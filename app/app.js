/**
 * Massar Mock Portal Application
 * Simulates the Moroccan Ministry of Education student portal running on AWS ECS Fargate.
 * 
 * Integration:
 * - AWS Secrets Manager (fetches database credentials at startup)
 * - Amazon Cognito (user authentication and JWT verification)
 * - AWS SQS (sends student results notifications)
 * - Aurora Serverless v2 MySQL via RDS Proxy (relational storage)
 * - ElastiCache Redis (caching student results)
 */

const express = require("express");
const mysql = require("mysql2/promise");
const Redis = require("ioredis");
const { CognitoJwtVerifier } = require("aws-jwt-verify");
const { SecretsManagerClient, GetSecretValueCommand } = require("@aws-sdk/client-secrets-manager");
const { CognitoIdentityProviderClient, InitiateAuthCommand } = require("@aws-sdk/client-cognito-identity-provider");
const { SQSClient, SendMessageCommand } = require("@aws-sdk/client-sqs");

const app = express();
app.use(express.json());

// Load and validate crucial environment variables
const REGION = process.env.AWS_REGION || "eu-south-1";
const PORT = process.env.PORT || 3000;

// AWS Clients Instantiations (Credential loading is managed by ECS Task Role)
const secretsClient = new SecretsManagerClient({ region: REGION });
const sqsClient = new SQSClient({ region: REGION });
const cognitoClient = new CognitoIdentityProviderClient({ region: REGION });

// Global holders for Database Credentials and Pool
let dbCredentials = null;
let dbPool = null;

// Initialize JWT Verifier dynamically if environment variables are present
let jwtVerifier = null;
if (process.env.COGNITO_USER_POOL_ID && process.env.USER_POOL_CLIENT_ID) {
  jwtVerifier = CognitoJwtVerifier.create({
    userPoolId: process.env.COGNITO_USER_POOL_ID,
    tokenUse: "access",
    clientId: process.env.USER_POOL_CLIENT_ID,
  });
  console.log("Cognito JWT Verifier successfully configured.");
} else {
  console.warn("Warning: COGNITO_USER_POOL_ID or USER_POOL_CLIENT_ID not defined. JWT verification will fail routes.");
}

// Initialize ElastiCache Redis Client
let redis = null;
if (process.env.ELASTICACHE_ENDPOINT) {
  let redisHost = process.env.ELASTICACHE_ENDPOINT;
  let redisPort = 6379;

  // Split endpoint if it contains host:port format
  if (redisHost.includes(":")) {
    const parts = redisHost.split(":");
    redisHost = parts[0];
    redisPort = parseInt(parts[1], 10);
  }

  console.log(`Configuring Redis connection to ${redisHost}:${redisPort}`);
  redis = new Redis({
    host: redisHost,
    port: redisPort,
    lazyConnect: true,          // Prevents startup crashes if Redis is temporarily unreachable
    maxRetriesPerRequest: 1,    // Fails commands fast so we can fall back to database immediately
    retryStrategy(times) {
      console.log(`Redis reconnect attempt #${times}...`);
      return Math.min(times * 1000, 5000); // Retry backoff up to 5s
    }
  });

  redis.on("error", (err) => {
    console.error("Redis Client Error:", err.message);
  });

  redis.on("connect", () => {
    console.log("Redis Client connected.");
  });
} else {
  console.warn("Warning: ELASTICACHE_ENDPOINT environment variable not configured. Redis caching is disabled.");
}

/**
 * Fetches database credentials from Secrets Manager.
 * Reuses cached credentials if already retrieved.
 */
async function getDbCredentials() {
  if (dbCredentials) return dbCredentials;

  const secretArn = process.env.DB_SECRET_ARN;
  if (!secretArn) {
    throw new Error("DB_SECRET_ARN environment variable is not defined");
  }

  console.log(`Fetching database credentials from Secrets Manager: ${secretArn}`);
  try {
    const command = new GetSecretValueCommand({ SecretId: secretArn });
    const data = await secretsClient.send(command);
    if (!data.SecretString) {
      throw new Error("Secrets Manager returned empty SecretString");
    }
    dbCredentials = JSON.parse(data.SecretString);
    return dbCredentials;
  } catch (error) {
    console.error("Error retrieving DB credentials from Secrets Manager:", error.message);
    throw error;
  }
}

/**
 * Returns a configured MySQL Connection Pool.
 * If the pool has not been initialized yet, it tries to fetch credentials and create it.
 */
async function getDbPool() {
  if (dbPool) return dbPool;

  try {
    const credentials = await getDbCredentials();
    const dbName = process.env.DB_NAME || "massardb";
    const dbHost = process.env.RDS_PROXY_ENDPOINT;

    if (!dbHost) {
      throw new Error("RDS_PROXY_ENDPOINT environment variable is not defined");
    }

    console.log(`Creating MySQL Connection Pool targeting RDS Proxy: ${dbHost}`);
    dbPool = mysql.createPool({
      host: dbHost,
      user: credentials.username,
      password: credentials.password,
      database: dbName,
      connectionLimit: 10, // Maximum pool size (limit 10)
      waitForConnections: true,
      queueLimit: 0
    });
    return dbPool;
  } catch (error) {
    console.error("MySQL Connection Pool initialization failed:", error.message);
    throw error;
  }
}

/**
 * Authentication Middleware for checking and verifying Cognito access tokens.
 */
const authMiddleware = async (req, res, next) => {
  if (!jwtVerifier) {
    return res.status(500).json({ error: "Authentication system is not configured on the server" });
  }

  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({ error: "Unauthorized: Missing or invalid Authorization header" });
  }

  const token = authHeader.split(" ")[1];
  try {
    const payload = await jwtVerifier.verify(token);
    req.user = payload; // Attach decoded JWT payload to the request
    next();
  } catch (error) {
    console.error("JWT Verification failed:", error.message);
    return res.status(401).json({ error: "Unauthorized: Invalid or expired token" });
  }
};

/**
 * ROUTE 1: GET /health
 * Public health check endpoint utilized by Application Load Balancers.
 * Does not block startup or crash even if DB/Redis is down.
 */
app.get("/health", (req, res) => {
  res.status(200).json({ status: "healthy" });
});

/**
 * ROUTE 2: POST /login
 * Public login endpoint to authenticate a student via Cognito.
 * Body: { username, password }
 */
app.post("/login", async (req, res) => {
  const { username, password } = req.body;

  if (!username || !password) {
    return res.status(400).json({ error: "Username and password are required" });
  }

  const clientId = process.env.USER_POOL_CLIENT_ID;
  if (!clientId) {
    return res.status(500).json({ error: "Cognito User Pool Client ID is not configured on the server" });
  }

  try {
    const command = new InitiateAuthCommand({
      AuthFlow: "USER_PASSWORD_AUTH",
      ClientId: clientId,
      AuthParameters: {
        USERNAME: username,
        PASSWORD: password
      }
    });

    const response = await cognitoClient.send(command);
    
    // Return authentication tokens to the client
    return res.status(200).json({
      access_token: response.AuthenticationResult.AccessToken,
      id_token: response.AuthenticationResult.IdToken,
      refresh_token: response.AuthenticationResult.RefreshToken,
      expires_in: response.AuthenticationResult.ExpiresIn,
      token_type: response.AuthenticationResult.TokenType
    });
  } catch (error) {
    console.error(`Login attempt failed for ${username}:`, error.message);
    return res.status(401).json({ 
      error: "Authentication failed", 
      message: error.message 
    });
  }
});

/**
 * ROUTE 3: GET /results
 * Protected route to get the authenticated student's results.
 * Pulls code_massar from JWT claims, checks Redis first, then falls back to Aurora MySQL.
 */
app.get("/results", authMiddleware, async (req, res) => {
  // Extract user identifier from claims (expects email or username: e.g. K130029841@taalim.ma or K130029841)
  const cognitoUser = req.user.username || req.user["cognito:username"] || req.user.email || "";
  const code_massar = cognitoUser.split("@")[0].toUpperCase();

  if (!code_massar) {
    return res.status(400).json({ error: "Invalid user claim format. Cannot parse code_massar." });
  }

  const cacheKey = `results:${code_massar}`;
  let cachedResults = null;

  // 1. Try fetching from Redis Cache (Failure-safe)
  if (redis && redis.status === "ready") {
    try {
      const data = await redis.get(cacheKey);
      if (data) {
        cachedResults = JSON.parse(data);
        console.log(`Cache HIT for student: ${code_massar}`);
      }
    } catch (err) {
      console.warn(`Redis GET failed for ${cacheKey}, falling back to DB:`, err.message);
    }
  }

  if (cachedResults) {
    return res.status(200).json(cachedResults);
  }

  // 2. Cache Miss: Query Aurora MySQL via RDS Proxy
  try {
    const db = await getDbPool();
    
    // Fetch Student data
    const [students] = await db.query(
      "SELECT id, code_massar, full_name, email, phone, result FROM students WHERE code_massar = ?",
      [code_massar]
    );

    if (students.length === 0) {
      return res.status(404).json({ error: `Results for student with code ${code_massar} not found` });
    }

    const student = students[0];

    // Fetch Subject Grades
    const [subjectGrades] = await db.query(
      "SELECT subject_name, grade FROM subject_results WHERE student_id = ?",
      [student.id]
    );

    // Format the response payload
    const payload = {
      full_name: student.full_name,
      code_massar: student.code_massar,
      result: student.result,
      subject_results: subjectGrades.map(row => ({
        subject_name: row.subject_name,
        grade: parseFloat(row.grade)
      }))
    };

    // 3. Write back to Redis Cache (Failure-safe, TTL: 300 seconds)
    if (redis && redis.status === "ready") {
      try {
        await redis.set(cacheKey, JSON.stringify(payload), "EX", 300);
        console.log(`Cached results for student ${code_massar} for 300 seconds.`);
      } catch (err) {
        console.warn(`Redis SET failed for ${cacheKey}:`, err.message);
      }
    }

    return res.status(200).json(payload);
  } catch (error) {
    console.error(`Error retrieving results for student ${code_massar}:`, error.message);
    return res.status(500).json({ error: "Failed to fetch student results from database" });
  }
});

/**
 * ROUTE 4: POST /admin/release-results
 * Protected route for administrator to trigger SQS notification releases.
 * Queries all students from DB, and sends messages to SQS queue.
 */
app.post("/admin/release-results", authMiddleware, async (req, res) => {
  const queueUrl = process.env.SQS_QUEUE_URL;
  if (!queueUrl) {
    return res.status(500).json({ error: "SQS Queue URL environment variable not configured" });
  }

  try {
    const db = await getDbPool();

    // Query all students
    const [students] = await db.query(
      "SELECT full_name, email, phone, result FROM students"
    );

    if (students.length === 0) {
      return res.status(200).json({ message: "No student records found to release", count: 0 });
    }

    console.log(`Found ${students.length} students. Sending notification payloads to SQS...`);

    // Prepare SQS SendMessage Promises to process in parallel
    const sendPromises = students.map(student => {
      const messageBody = JSON.stringify({
        email: student.email,
        phone: student.phone,
        result: student.result,
        full_name: student.full_name
      });

      const command = new SendMessageCommand({
        QueueUrl: queueUrl,
        MessageBody: messageBody
      });

      return sqsClient.send(command);
    });

    // Wait for all messages to be queued
    await Promise.all(sendPromises);
    console.log(`Successfully queued ${students.length} notification messages in SQS.`);

    return res.status(200).json({ 
      message: "Results released", 
      count: students.length 
    });
  } catch (error) {
    console.error("Failed to release results:", error.message);
    return res.status(500).json({ error: "Failed to process results release" });
  }
});

// Asynchronous startup initialization function
async function startupInitialization() {
  console.log("App booting. Initiating background AWS service connections...");
  
  // Attempt DB initialization asynchronously
  try {
    await getDbPool();
    console.log("Initial database connection check: SUCCESS.");
  } catch (error) {
    console.warn("Initial database connection check: FAILED. Application will proceed to start, and retry connection on-demand.", error.message);
  }

  // Attempt Redis connection check
  if (redis) {
    redis.connect().catch((err) => {
      console.warn("Initial Redis connection check: FAILED. App will proceed and run with caching disabled.", err.message);
    });
  }
}

// Start Server listening on port 3000 (required by AWS target group)
app.listen(PORT, () => {
  console.log(`Moroccan Ministry of Education (Massar Mock Portal) running on port ${PORT}`);
  startupInitialization();
});
