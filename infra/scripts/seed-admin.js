const { execSync } = require('child_process');
const { 
  CognitoIdentityProviderClient, 
  AdminCreateUserCommand, 
  AdminSetUserPasswordCommand, 
  AdminAddUserToGroupCommand 
} = require('@aws-sdk/client-cognito-identity-provider');

async function seedAdmin() {
  console.log("Starting Admin seeding...");
  
  let userPoolId;
  try {
    userPoolId = execSync('terraform output -raw user_pool_id').toString().trim();
    if (!userPoolId || userPoolId.startsWith("Warning")) {
      throw new Error("Invalid output from terraform output user_pool_id");
    }
    console.log(`Discovered Cognito User Pool ID: ${userPoolId}`);
  } catch (error) {
    console.error("Failed to retrieve user_pool_id from Terraform output:", error.message);
    process.exit(1);
  }

  const client = new CognitoIdentityProviderClient({ region: 'eu-south-1' });

  // 1. Create the user profile
  try {
    await client.send(new AdminCreateUserCommand({
      UserPoolId: userPoolId,
      Username: 'admin',
      UserAttributes: [
        { Name: 'email', Value: 'admin@taalim.ma' },
        { Name: 'email_verified', Value: 'true' }
      ],
      MessageAction: 'SUPPRESS'
    }));
    console.log("Admin user profile successfully created.");
  } catch (error) {
    if (error.name === 'UsernameExistsException') {
      console.log("Admin user already exists in Cognito. Proceeding to reset/confirm password.");
    } else {
      console.error("Error creating Admin user:", error.name, error.message);
      process.exit(1);
    }
  }

  // 2. Set a permanent password 
  // Note: the password must not be hardcoded in production. Consider using github secrets.
  try {
    await client.send(new AdminSetUserPasswordCommand({
      UserPoolId: userPoolId,
      Username: 'AymenAdmin',
      Password: 'Massar2024!',
      Permanent: true
    }));
    console.log("Admin user permanent password set successfully.");
  } catch (error) {
    console.error("Error setting password for Admin user:", error.message);
    process.exit(1);
  }

  // 3. Add admin to the admins group
  try {
    await client.send(new AdminAddUserToGroupCommand({
      UserPoolId: userPoolId,
      Username: 'admin',
      GroupName: 'admins'
    }));
    console.log("Admin user successfully added to the 'admins' group.");
  } catch (error) {
    console.error("Error adding Admin user to group:", error.message);
    process.exit(1);
  }

  console.log("Admin seeding completed successfully!");
}

seedAdmin();
