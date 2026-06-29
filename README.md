# Massar AWS Infrastructure Redesign

This repository contains the production-grade AWS infrastructure code for the Massar platform redesign, built entirely using Terraform and automated via GitHub Actions CI/CD pipelines.

**Companion repository:** [aymenelk01/massar-app](https://github.com/aymenelk01/massar-app) — the application code for test the infrastructure and deployment pipelines that run on top of this infrastructure.

> **Deploying this project?** See the **[Deployment Guide](DEPLOYMENT.md)** for prerequisites, step-by-step bootstrap instructions, variable reference, and teardown procedures.

---

## Table of Contents

- [Repository Structure](#repository-structure)
- [Part 1: Project Overview & Executive Summary](#part-1-project-overview--executive-summary)
  - [Project Overview](#project-overview)
  - [Key Business & Technical Goals Achieved](#key-business--technical-goals-achieved)
- [Part 2: Technical Reference & Architecture Deep Dive](#part-2-technical-reference--architecture-deep-dive)
  - [System Architecture Diagram](#system-architecture-diagram)
  - [Technical Stack & Service Mapping](#technical-stack--service-mapping)
  - [Infrastructure Decisions](#infrastructure-decisions)
    - [ECS Fargate with Graviton ARM64 Compute](#ecs-fargate-with-graviton-arm64-compute)
    - [Amazon ECR Image Management](#amazon-elastic-container-registry-ecr-image-management)
    - [Why ECR over Docker Hub](#why-ecr-over-docker-hub)
    - [Aurora Serverless v2 MySQL with IAM Database Authentication](#aurora-serverless-v2-mysql-with-iam-database-authentication)
    - [RDS Proxy with IAM Database Authentication](#rds-proxy-with-iam-database-authentication)
    - [ElastiCache Redis 7 Look-Aside Caching](#elasticache-redis-7-look-aside-caching)
    - [Flyway Connecting Directly to Aurora Bypassing the RDS Proxy](#flyway-connecting-directly-to-aurora-bypassing-the-rds-proxy)
    - [Amazon CloudFront Content Delivery Network](#amazon-cloudfront-content-delivery-network)
    - [AWS WAFv2 Web Application Firewall](#aws-wafv2-web-application-firewall)
    - [Application Load Balancer (ALB) Routing](#application-load-balancer-alb-routing)
    - [Private Subnet Isolation with VPC Interface Endpoints (No NAT Gateway)](#private-subnet-isolation-with-vpc-interface-endpoints-no-nat-gateway)
    - [Three-Availability-Zone Architecture and High Availability](#three-availability-zone-architecture-and-high-availability)
    - [Amazon Bedrock Nova Pro Academic Guidance](#amazon-bedrock-nova-pro-academic-guidance)
    - [Amazon Cognito](#amazon-cognito)
    - [Asynchronous PDF Diploma Generation via SQS and Lambda](#asynchronous-pdf-diploma-generation-via-sqs-and-lambda)
    - [Decoupled Notifications via SQS, Lambda, and SES/SNS](#decoupled-notifications-via-sqs-lambda-and-sessns)
    - [Secure Amazon S3 Object Storage with Lifecycle Management](#secure-amazon-s3-object-storage-with-lifecycle-management)
    - [Remote Terraform State Management with S3 and Native Locking](#remote-terraform-state-management-with-s3-and-native-locking)
    - [Amazon CloudWatch for Logging and Monitoring](#amazon-cloudwatch-for-logging-and-monitoring)
    - [Application Auto-Scaling Strategy For ECS](#application-auto-scaling-strategy-for-ecs)
  - [Security Posture](#security-posture)
  - [Problem Solving](#problem-solving)
  - [Cost Optimisation & Sustainability](#cost-optimisation--sustainability)
  - [CI/CD Pipeline Architecture](#cicd-pipeline-architecture)
    - [Post-Apply Bootstrap: setup-cognito-admin.sh](#post-apply-bootstrap-setup-cognito-adminsh)
    - [Keyless Access (CI/CD Authentication)](#keyless-access-cicd-authentication)
  - [Production Improvements](#production-improvements)

---

## Repository Structure

<details>
<summary><b>Repository Structure</b> (Click to expand)</summary>

```
massar-aws-infrastructure/
│
├── .github/
│   └── workflows/
│       ├── terraform.yml          # Infrastructure CI/CD — validate (PR) + apply (merge to main)
│       └── infracost.yml          # Cost-diff comment posted on every Terraform PR
│
├── bootstrap-statebucket/         # Run once: creates the S3 remote state bucket (local backend)
│   ├── s3state.tf
│   ├── variables.tf
│   └── providers.tf
│
├── bootstrap-oidc/                # Run once: provisions OIDC IdP + TerraformRole + DeployRole
│   ├── main.tf                    # GitHub OIDC Identity Provider
│   ├── terraformIAM.tf            # TerraformRole (PowerUserAccess + scoped IAM inline policy)
│   ├── deployIAM.tf               # DeployRole (fully custom least-privilege policy)
│   ├── data.tf
│   ├── output.tf
│   ├── backend.tf
│   ├── variables.tf
│   └── providers.tf
│
├── budget/                        # Standalone module: AWS Budget ($50/month cap + 80% alerts)
│   ├── main.tf
│   ├── variables.tf
│   ├── terraform.tfvars
│   ├── backend.tf
│   └── providers.tf
│
└── infra/                         # Main Terraform root module (all application infrastructure)
    ├── main.tf                    # Module composition — wires all modules together
    ├── variables.tf
    ├── output.tf
    ├── providers.tf
    ├── backend.tf                 # S3 remote backend + native state locking
    ├── terraform.tfvars
    ├── terraform.tfvars.example.md
    ├── .tflint.hcl                # TFLint ruleset (pinned, used by terraform-validate job)
    ├── infracost.tfvars           # Infracost variable overrides
    │
    ├── scripts/
    │   └── setup-cognito-admin.sh # Post-apply: idempotent admin user provisioning in Cognito
    │
    └── modules/
        ├── vpc/                   # VPC, subnets (3 AZ × 3 tiers), route tables, Flow Logs
        │   ├── main.tf
        │   ├── subnets.tf
        │   ├── routetables.tf
        │   ├── gatewayendpoints.tf  # Free S3 + DynamoDB gateway endpoints
        │   ├── vpcflowlogs.tf
        │   ├── cloudwatch.tf
        │   ├── iam.tf
        │   ├── data.tf
        │   ├── output.tf
        │   └── variables.tf
        │
        ├── security/              # Security groups + all inbound/outbound rules
        │   ├── security_group.tf
        │   ├── rules.tf
        │   ├── data.tf
        │   ├── output.tf
        │   └── variables.tf
        │
        ├── endpoints/             # VPC Interface Endpoints (ECR, SQS, Cognito, SM, CW, Bedrock)
        │   ├── main.tf
        │   ├── data.tf
        │   ├── output.tf
        │   └── variables.tf
        │
        ├── storage/               # S3 buckets: static assets, diplomas, access logs
        │   ├── s3static.tf
        │   ├── s3documents.tf
        │   ├── s3logs.tf
        │   ├── s3policies.tf      # OAC bucket policy (CloudFront-only access for static bucket)
        │   ├── outputs.tf
        │   └── variables.tf
        │
        ├── ecr/                   # Two ECR repos (app + flyway) with lifecycle & scan-on-push
        │   ├── main.tf
        │   ├── output.tf
        │   └── variables.tf
        │
        ├── cognito/               # Cognito User Pool, app client, user groups, SSM parameter write
        │   ├── main.tf
        │   ├── ssm.tf
        │   ├── output.tf
        │   └── variables.tf
        │
        ├── database/              # Aurora Serverless v2 (writer + reader), RDS Proxy, autoscaling
        │   ├── aurora.tf          # Cluster, instances, Secrets Manager master password
        │   ├── rdsproxy.tf        # RDS Proxy with IAM auth (read/write + read-only endpoints)
        │   ├── autoscaling.tf     # Reader auto-scaling + scheduled pre-warm actions
        │   ├── cloudwatch.tf
        │   ├── data.tf
        │   ├── output.tf
        │   └── variables.tf
        │
        ├── cache/                 # ElastiCache Redis 7 replication group
        │   ├── main.tf
        │   ├── output.tf
        │   └── variables.tf
        │
        ├── loadbalancer/          # Application Load Balancer + target group + health check
        │   ├── alb.tf
        │   ├── output.tf
        │   └── variables.tf
        │
        ├── cloudfront/            # CloudFront distribution, OAC, WAFv2 web ACL
        │   ├── main.tf
        │   ├── waf.tf             # WAFv2: rate limits, SQLi/XSS/Log4j managed rule groups
        │   ├── oac.tf
        │   ├── s3policy.tf
        │   ├── data.tf
        │   ├── provider.tf
        │   ├── output.tf
        │   └── variables.tf
        │
        ├── compute/               # ECS cluster, Fargate app service, Flyway task, autoscaling, IAM
        │   ├── ecs.tf             # App task definition + ECS service (ARM64 Fargate)
        │   ├── flywayecs.tf       # One-off Flyway migration task definition
        │   ├── autoscaling.tf     # ECS target tracking + scheduled scale actions
        │   ├── iam.tf             # Task execution role + task role (Bedrock, SSM, ECR, SQS…)
        │   ├── cloudwatch.tf
        │   ├── data.tf
        │   ├── output.tf
        │   └── variables.tf
        │
        ├── notifications/         # SQS queue + Lambda (ARM64 Python) → SES email + SNS SMS
        │   ├── sqs.tf
        │   ├── lambda.tf
        │   ├── lambda_function.py
        │   ├── iam.tf
        │   ├── sns.tf
        │   ├── cloudwatch.tf
        │   ├── locals.tf
        │   ├── outputs.tf
        │   ├── data.tf
        │   └── variables.tf
        │
        └── documents/             # SQS queue + Lambda (ARM64 Python) → PDF diploma → S3
            ├── sqs.tf
            ├── lambda.tf
            ├── iam.tf
            ├── locals.tf
            ├── outputs.tf
            ├── data.tf
            ├── variables.tf
            └── src/
                ├── lambda_function.py  # PDF generation logic (FPDF)
                └── requirements.txt
```
</details>

---

## Part 1: Project Overview & Executive Summary

_(Written for HR Professionals, Hiring Managers, and Non-Technical Stakeholders)_

### Project Overview

The official Moroccan student portal (Massar) serves as the digital backbone for educational management in Morocco. Every year, when Baccalaureate exam results are released, millions of students and parents attempt to access the platform simultaneously, causing severe system crashes, slow response times, and downtime. Additionally, security threats and vulnerability reports in 2025 highlighted the urgent need for a more secure and resilient infrastructure.

This project completely redesigns Massar's infrastructure on AWS to demonstrate how a modern, cloud-native architecture can solve these real-world scaling and security challenges. By moving away from rigid physical servers and implementing auto-scaling cloud services, this redesign ensures the platform remains available during high-stress exam release days while keeping operational costs near zero during quiet periods.


### Key Business & Technical Goals Achieved

- **High Availability:** Replaced single-point-of-failure servers with an automated system that scales up instantly across three Availability Zones to handle millions of simultaneous users.
- **Hardened Data Security:** Protected the sensitive educational records and personal data of minor students using enterprise-grade encryption and access controls.
- **Exceptional Cost Efficiency:** Utilized serverless technologies that only charge for active usage, shrinking the platform's running costs when exams are not active.
- **Continuous Integration & Rapid Delivery:** To eliminate human error and accelerate release velocity, i built an automated GitHub Actions deployment framework. By completely bypassing manual AWS configurations, code and infrastructure alterations transit securely through automated testing, compliance gates, and financial guardrails.
---

## Part 2: Technical Reference & Architecture Deep Dive

_(Written for Senior Cloud, DevOps, and Platform Engineers)_

### System Architecture Diagram

![System Architecture](massar-architecture.drawio.svg)


### Technical Stack & Service Mapping

<details>
<summary><b>Technical Stack and Service Mapping</b> (Click to expand)</summary>

| AWS Service                      | Category              | Specific Role in Architecture                                                                                                               | Reference                                                                                                             |
| :------------------------------- | :-------------------- | :------------------------------------------------------------------------------------------------------------------------------------------ | :-------------------------------------------------------------------------------------------------------------------- |
| **Amazon CloudFront**            | Content Delivery      | Caching and serving static frontend assets from the nearest edge location, terminating SSL, and routing /api/\* requests to the ALB origin. | [main.tf](infra/modules/cloudfront/main.tf)                                                                           |
| **AWS WAFv2**                    | Edge Security         | Blocking web exploits (SQLi, XSS), enforcing login rate limits, and checking IP reputation.                                                 | [waf.tf](infra/modules/cloudfront/waf.tf)                                                                             |
| **Application Load Balancer**    | Traffic Routing       | Distributing incoming API traffic to Fargate tasks and executing health checks on `/health`.                                                | [alb.tf](infra/modules/loadbalancer/alb.tf)                                                                           |
| **AWS ECS on Fargate**           | Container Compute     | Running the app backend code and Flyway migration runner on AWS Graviton (ARM64).                                                           | [ecs.tf](infra/modules/compute/ecs.tf)                                                                                |
| **AWS Application Auto-Scaling** | Scaling Compute       | Scaling the ECS service desired task count dynamically based on CPU utilization and shcedule actions.                                 | [autoscaling.tf](infra/modules/compute/autoscaling.tf)                                                              |
| **Amazon ECR**                   | Container Registry    | Storing application and migration Docker images, running vulnerability scans, and cleaning up old builds.                                   | [main.tf](infra/modules/ecr/main.tf)                                                                                  |
| **Amazon Aurora Serverless v2**  | Relational Database   | Storing student and teachers data and subject grades using MySQL 8.0 with Serverless V2 scaling.                                            | [aurora.tf](infra/modules/database/aurora.tf)                                                                         |
| **Amazon RDS Proxy**             | Database Proxying     | Pooling database connections for scale, managing failovers, and enforcing strict IAM database authentication.                               | [rdsproxy.tf](infra/modules/database/rdsproxy.tf)                                                                     |
| **Amazon ElastiCache (Redis)**   | In-Memory Caching     | Operating a highly available Redis 7 cluster to cache student exam results, absorbing read traffic spikes.                                  | [main.tf](infra/modules/cache/main.tf)                                                                                |
| **AWS Cognito**                  | Identity & Access     | Managing secure student and teacher user authentication, issuing JWTs, and organizing group roles.                                          | [main.tf](infra/modules/cognito/main.tf)                                                                              |
| **Amazon SQS**                   | Message Queueing      | Decoupling the notification engine and diploma generator tasks from the main backend server.                                                | [sqs.tf(for notifications)](infra/modules/notifications/sqs.tf) [sqs.tf(for diplomas)](/infra/modules/documents/sqs.tf) |
| **AWS Lambda**                   | Serverless Compute    | Processing SQS messages asynchronously to generate PDF diplomas and dispatch emails/SMS alerts.                                             | [lambda.tf(for notifications)](infra/modules/notifications/lambda.tf)   [lambda.tf(for diplomas)](/infra/modules/documents/src/lambda.tf)                                                                 |
| **Amazon Bedrock**               | Generative AI         | Interacting with the `amazon.nova-pro-v1:0` model via Converse API for student academic advising.                                           | [IAM.tf](/infra/modules/compute/iam.tf#L199)                                   |
| **Amazon S3**                    | Object Storage        | Storing static frontend builds, generated PDF diplomas, audit logs, and Terraform backend state.                                            | [Storage](/infra/modules/storage)                                                                                          |
| **Amazon CloudWatch**            | Monitoring & Logs     | Centralizing container logs, database queries, lambda output, and tracking system metrics.                                                  |                                                                   |
| **AWS Secrets Manager**          | Secrets Storage       | Securing the Aurora database master credentials, which are read only by the Flyway task execution role.                                     | [aurora.tf](infra/modules/database/aurora.tf#L39)                                                                     |
| **AWS Systems Manager**          | SSM & Parameter Store | Providing secure parameter configuration storage and facilitating secure session shells via ECS Exec.                                       | [ecs.tf](infra/modules/compute/iam.tf#L154)                                                                            |

</details>

---

### Infrastructure Decisions

<details>
<summary><b>ECS Fargate with Graviton ARM64 Compute</b> (Click to expand)</summary>

AWS Elastic Container Service (ECS) running on AWS Fargate was selected over standard EC2 Auto Scaling groups to eliminate the operational complexity of patching, scaling, and managing host operating systems, allowing the engineering team to focus entirely on the application container. Fargate was chosen over AWS Lambda for hosting the core application because the API backend maintains persistent TCP connections to ElastiCache and the RDS Proxy, which avoids the severe cold-start latencies and the 15-minute execution timeouts inherent to Lambda. The containers are compiled for the AWS Graviton (ARM64) architecture, which delivers approximately 20% better price-performance compared to traditional x86 instances. This choice ensures the backend handles continuous, high-throughput HTTP connections smoothly while lowering the overall environmental footprint through reduced energy usage.

</details>

<details>
<summary><b>Amazon Elastic Container Registry (ECR) Image Management</b> (Click to expand)</summary>

To support our containerized application model, i provisioned two distinct Amazon Elastic Container Registry (ECR) repositories: one for the primary backend application and another for the Flyway migration tool. i configured the repositories with tag mutability (`image_tag_mutability = "MUTABLE"`) to allow our GitHub Actions CI/CD workflows to push both a specific git commit hash (`sha-*`) and update the `latest` tag on every build. To prevent storage costs from accumulating over time, a lifecycle policy is applied to both repositories, which retains only the last 5 tagged images for rollback safety and immediately deletes untagged images older than 1 day. Security is integrated at the registry level by enabling automatic image scanning on push to detect vulnerabilities before container images are deployed to ECS Fargate.

</details>

<details>
<summary><b>Why ECR over Docker Hub</b> (Click to expand)</summary>

Amazon ECR was selected over Docker Hub as the container registry for both the application and Flyway migration images. The primary architectural driver is the no-NAT-Gateway design — pulling images from Docker Hub would require either a NAT Gateway(which will add more costs) or a public subnet(which is a security risk), directly contradicting the private subnet isolation security requirement. With ECR, image pulls are routed exclusively through the ECR VPC Interface Endpoints (ecr.api and ecr.dkr), keeping all registry traffic within the AWS private network at zero data transfer cost. Authentication is handled natively via the ECS Task Role IAM permissions — no registry credentials to store, rotate, or expose. Additionally, ECR provides integrated vulnerability scanning on every image push and lifecycle policies to automate old image cleanup, both of which are already implemented in this architecture.

</details>

<details>
<summary><b>Aurora Serverless v2 MySQL with IAM Database Authentication</b> (Click to expand)</summary>

- **Why Aurora Over Rds and DynamoDb:** The relational storage engine is built on Amazon Aurora Serverless v2 MySQL. The first decision was to use Aurora over standard RDS MySQL. With standard RDS, you must select and provision a fixed instance type — idling 23 hours a day wastes money, while under-provisioning during the exam release spike causes the exact crash the real Massar system is known for. Aurora Serverless v2 solves this by scaling up within seconds in response to real load rather than requiring a manual instance resize or a scheduled scaling window. The second decision was to use Aurora MySQL over DynamoDB: the deeply relational nature of grade calculations, national coefficients, and branch-subject mappings makes a relational database the only appropriate choice, as DynamoDB's key-value model would require shifting complex JOIN logic into the application layer entirely.
- **Aurora Serverless v2 Capacity Configuration (ACU):** The cluster is configured with a minimum of 0.5 ACU and a maximum of 64 ACU. The minimum is set to 0.5 rather than 0 to eliminate Aurora cold start latency — a serverless cluster at 0 ACU requires several seconds to resume from pause, which is unacceptable on a platform where a student's first request after a long idle period must return immediately. The maximum caps runaway scaling during unexpected traffic and controls worst-case cost. During the Baccalaureate results window the cluster scales freely within this range in response to real connection load from the RDS Proxy connection pool.
- **Writer/Reader Instance Separation:** The cluster runs two instance types: a single writer instance that handles all write operations (grade submissions, Flyway DDL migrations) and a dedicated static reader instance that serves all read queries through the RDS Proxy read-only endpoint. Aurora Auto Scaling adds up to 5 reader instances during the Baccalaureate spike. This separation protects the writer from being saturated by read traffic — the dominant load pattern during results publication is pure reads from hundreds of thousands of students checking results simultaneously. By absorbing that load on reader instances, the writer remains available and stable for any concurrent write operations. Aurora replicates from writer to readers with sub-10ms lag, which is acceptable for result lookups that are written hours before publication.
- **Aurora Reader Auto Scaling Strategy:** Reader instances follow the same two-layer scaling approach as the ECS application layer. A target tracking policy scales reader instances horizontally when average CPU across all readers exceeds 70%, with a 60-second scale-out cooldown and a 300-second scale-in cooldown. However, reactive scaling alone is insufficient for Aurora — provisioning a new reader instance takes 3–5 minutes, meaning a CPU-triggered scale-out during the Bac results spike would arrive too late. To solve this, a scheduled action pre-warms the reader floor to 3 instances at 23:00 UTC on July 14 (midnight Morocco time), two hours before results go live, with a ceiling of 5. A second scheduled action returns the floor to 1 reader and ceiling to 3 on July 16 23:00 UTC. During normal operation the single static reader handles non-cached read traffic from teachers and administrators. During the spike the pre-warmed readers serve as the fallback layer for any cache misses that reach Aurora, ensuring the writer remains uncontested regardless of ElastiCache behavior.([autoscaling.tf](/infra/modules/database/autoscaling.tf)).

</details>

<details>
<summary><b>RDS Proxy with IAM Database Authentication</b> (Click to expand)</summary>

The RDS Proxy is positioned in front of the Aurora cluster to manage connection pooling and multiplexing, preventing the horizontal scaling of Fargate containers from exhausting the database's hard connection limit. To eliminate database credentials from the application configuration entirely, i enforce IAM Database Authentication (`IAM_AUTH`) on the RDS Proxy, requiring the app backend code to authenticate using short-lived IAM tokens generated dynamically by the backend — no password is ever stored or rotated manually. The proxy exposes two endpoints: a default endpoint that routes to the Aurora writer for all write operations, and a dedicated read-only endpoint that load-balances across all available reader instances. The application connects exclusively through these two proxy endpoints, meaning connection pooling, TLS enforcement, and IAM authentication apply equally to both read and write traffic.

</details>

<details>
<summary><b>ElastiCache Redis 7 Look-Aside Caching</b> (Click to expand)</summary>

Exam results are completely immutable once they are officially published, making caching the primary defense mechanism against the database exhaustion. To handle the peak traffic of hundreds of thousands of concurrent queries without crashing, i implemented an Amazon ElastiCache Redis 7 replication group operating in a look-aside caching pattern. When a student requests their grades, the backend queries Redis first; if cached, the result is returned in microseconds, bypassing database queries entirely. In the event of a cache miss, the backend fetches the data from the database, formats the payload, and writes it back to Redis. The look-aside pattern is designed to absorb the majority of read traffic during cache-warm conditions, isolating the database cluster from CPU exhaustion. To eliminate cache misses entirely during the spike, the application exposes a pre-warm endpoint that is triggered before results go live — it queries all results from Aurora in bulk and loads them into Redis with a 48-hour TTL. When the Baccalaureate results are published at midnight, every student query is guaranteed to be a cache hit from the first request.

</details>

<details>
<summary><b>Flyway Connecting Directly to Aurora Bypassing the RDS Proxy</b> (Click to expand)</summary>

Database migrations are managed using Flyway, which runs as an one-off ECS Fargate task during the deployment lifecycle rather than a long-running service. The migration task is configured to bypass the RDS Proxy entirely, connecting directly to the Aurora cluster endpoint via JDBC. This architectural decision was made because the RDS Proxy is configured to require AWS IAM Database Authentication, which Flyway does not natively support in its JDBC connection out of the box in this setup. Connecting Flyway directly using the master database credentials(the password created and rotated by AWS setting manage_master_user_password to true) retrieved securely from AWS Secrets Manager ensures that DDL schema changes execute successfully without polluting or consuming the connection pools reserved for application traffic.

</details>

<details>
<summary><b>Amazon CloudFront Content Delivery Network</b> (Click to expand)</summary>

Amazon CloudFront serves as the global entry point for all incoming traffic, acting as a high-performance content delivery network. It hosts the static HTML/JS frontend assets directly from an S3 bucket cache at edge locations, completely offloading static asset delivery from the Fargate compute tier. Dynamic API requests matching `/api/*` are routed directly to the Application Load Balancer using CloudFront origin behaviors. This separation reduces latency for end-users, minimizes origin traffic, and lowers compute resource pressure on the backend services during traffic spikes.

</details>

<details>
<summary><b>AWS WAFv2 Web Application Firewall</b> (Click to expand)</summary>

To secure the application against the real-world security risks and extortion attempts seen in 2025, AWS WAFv2 is attached directly to the CloudFront distribution. The firewall implements a strict rate limit of 100 requests per 5 minutes per IP specifically on the `/login` path to prevent brute-force authentication attacks, alongside a broader blanket rate limit of 1500 requests per IP. Furthermore, it integrates AWS Managed Rule Groups, including the SQL Injection Rule Set, Common Rule Set, Known Bad Inputs, and IP Reputation Lists, blocking malicious actors before their requests ever reach the Application Load Balancer or S3 origins.

</details>

<details>
<summary><b>Application Load Balancer (ALB) Routing</b> (Click to expand)</summary>

The Application Load Balancer distributes dynamic traffic across the ECS Fargate tasks running in the private subnets. It performs HTTP health checks on the `/health` endpoint to ensure traffic is only routed to active, healthy containers. The ALB's security group is configured to reject all direct internet traffic, allowing inbound traffic exclusively from CloudFront edge locations by referencing the AWS-managed CloudFront prefix list. This prevents bypass attacks where an attacker attempts to scan or DDOS the ALB directly.

</details>

<details>
<summary><b>Private Subnet Isolation with VPC Interface Endpoints (No NAT Gateway)</b> (Click to expand)</summary>

To satisfy strict security guidelines, all backend computing resources, database clusters, and caching nodes are deployed inside private subnets with no public IP addresses. By not deploying an AWS NAT Gateway, the outbound internet path is eliminated entirely — preventing data exfiltration from compromised workloads and ensuring all traffic remains within the AWS private network. Instead, i configured VPC Interface Endpoints (PrivateLink) for services that live outside the VPC, such as ECR, SQS, Cognito, Secrets Manager, CloudWatch Logs, and Bedrock. While a NAT Gateway may cost less in certain low-traffic configurations compared to multiple interface endpoints, the endpoints were selected to maximize security by ensuring all traffic between private resources and AWS services stays within the AWS network, preventing any outbound path to the public internet.

</details>

<details>
<summary><b>Three-Availability-Zone Architecture and High Availability</b> (Click to expand)</summary>

The real Massar platform crashes on a predictable, annual schedule: a single datacenter absorbs the entire country's traffic at the moment results are published, with no failover path. This architecture eliminates that failure mode. The VPC spans all three Availability Zones with nine dedicated subnets — public (ALB), private-app (Fargate), and private-db (Aurora, RDS Proxy, ElastiCache) — one set per AZ. Every tier of the stack has a live presence in all three zones simultaneously, not as a standby.

</details>

<details>
<summary><b>Amazon Bedrock Nova Pro Academic Guidance</b> (Click to expand)</summary>

The platform integrates generative AI capabilities by accessing the `amazon.nova-pro-v1:0` model via Amazon Bedrock's serverless Converse API. The backend communicates with Bedrock to provide students with personalized academic guidance, analyzing their grade coefficients and suggesting target fields of study. By utilizing Bedrock's serverless runtime, i deliver advanced AI-powered chat advisory features without the cost or operational burden of scaling custom machine learning inference servers.

</details>

<details>
<summary><b>Amazon Cognito</b> (Click to expand)</summary>

Amazon Cognito manages all authentication for the platform. It issues short-lived JWT tokens that are validated on every request by the Express backend using aws-jwt-verify. User passwords are never stored in Aurora or handled by the application layer — Cognito owns the credential store entirely.

</details>

<details>
<summary><b>Asynchronous PDF Diploma Generation via SQS and Lambda</b> (Click to expand)</summary>

Generating secure PDF diplomas using libraries like FPDF is a CPU-heavy process that, if done synchronously in the main web server, would quickly drain system resources and crash container instances during results release events. To resolve this, the backend writes a message containing the student data(JSON format) to an Amazon SQS queue when a diploma is requested. A Python-based Lambda function (compiled for ARM64) is triggered by SQS to generate the PDF and write it directly to a private S3 bucket so the students can download their diplomas from a pre-signed url. This asynchronous decoupling protects the main server tier from CPU exhaustion, keeping the student portal responsive.

</details>

<details>
<summary><b>Decoupled Notifications via SQS, Lambda, and SES/SNS</b> (Click to expand)</summary>

When exam results are finalized, the administrator triggers a release event which must dispatch notifications to thousands of students via email and SMS. The backend writes the notification tasks to an Amazon SQS queue, allowing the admin API request to complete instantly. An ARM64 Python Lambda function processes these messages in batches, sending HTML-formatted emails via Amazon SES and transactional SMS messages via Amazon SNS. Decoupling the notification dispatch prevents API timeouts, protects downstream services from throttling, and ensures reliable delivery.

</details>

<details>
<summary><b>Secure Amazon S3 Object Storage with Lifecycle Management</b> (Click to expand)</summary>

Amazon S3 is configured as the storage layer for static frontend files, generated diplomas, infrastructure access logs, and Terraform backend state files. The static files bucket is configured with a bucket policy that grants read access exclusively to the CloudFront distribution via Origin Access Control (OAC), preventing direct S3 URL access entirely. The documents bucket containing student diplomas is entirely private, and the application accesses files by generating short-lived presigned URLs. Automated S3 Lifecycle Policies are applied to optimize storage costs: the documents bucket transitions PDF diplomas to `STANDARD_IA` after 90 days, archives them to `GLACIER` after 365 days, and deletes non-current versions after 30 days, while the logs bucket transitions access logs to `STANDARD_IA` after 30 days, to `GLACIER` after 90 days, and permanently deletes them after 365 days.

</details>

<details>
<summary><b>Remote Terraform State Management with S3 and Native Locking</b> (Click to expand)</summary>

To secure infrastructure state and enable safe team collaboration, the project uses an Amazon S3 remote backend with server-side encryption (`encrypt = true`) and native state locking (`use_lockfile = true`). Storing the state file centrally in S3 creates a single source of truth for the platform's actual resource status, preventing configuration drift when multiple engineers or CI/CD pipelines run Terraform commands. State encryption at rest ensures that sensitive metadata and database secrets generated during deployment are protected against unauthorized access. Furthermore, S3 native state locking prevents concurrent executions of Terraform, protecting the backend state from corruption and avoiding deployment race conditions.

</details>

<details>
<summary><b>Amazon CloudWatch for Logging and Monitoring</b> (Click to expand)</summary>

Six dedicated log groups are provisioned across four modules, each with an explicit 7-day retention policy:

| Log Group | Module | Content |
|---|---|---|
| `/ecs/massar-{env}` | compute | ECS app container stdout/stderr |
| `/ecs/exec/massar-{env}` | compute | ECS Exec interactive session audit trail |
| `/ecs/flyway/massar-{env}` | compute | Flyway migration task output |
| `/aurora/massar-error-{env}` | database | Aurora engine errors |
| `/aurora/massar-slowquery-{env}` | database | Aurora slow query log |
| `/aws/lambda/massar-notifications-{env}` | notifications | Lambda function execution output |
| VPC Flow Logs | vpc | All accepted/rejected network flows |

**Retention set to 7 days:** The default CloudWatch behaviour with no retention policy is to retain logs indefinitely, which accumulates storage costs silently. The 7-day window is a deliberate cost-containment decision for a portfolio project — it covers the window in which any deployment issue or traffic spike would be actively investigated. In a production environment, compliance requirements (e.g., audit logs, slow query logs) would extend this to 90 days or longer.

**ECS Exec audit log:** Every interactive shell session opened via `aws ecs execute-command` is written to the dedicated exec log group. This ensures that any debugging access to a running Fargate container during an incident is captured and traceable, rather than being an unlogged back-door into the production environment.

**Aurora slow query log:** Enabled on the cluster via `enabled_cloudwatch_logs_exports = ["error", "slowquery"]`. This surfaces any query taking longer than the `long_query_time` threshold directly in CloudWatch without requiring SSH access to a database host — a key operational advantage of managed Aurora over self-hosted MySQL.

**VPC Flow Logs:** All network traffic accepted and rejected within the VPC is captured via the vpc module and streamed to CloudWatch. During a security incident or unexpected traffic spike, flow logs provide the network-level audit trail needed to identify the source — including any unexpected outbound connections that would indicate a compromised container.([vpcflowlogs.tf](/infra/modules/vpc/vpcflowlogs.tf)).

</details>

<details>
<summary><b>Application Auto-Scaling Strategy For ECS</b>(Click to expand)</summary>
Massar's traffic is not random. It spikes on predictable, calendar-driven events — most critically the publication of Baccalaureate results every July. The original infrastructure reacted to these spikes after they started, by which point the service was already degraded and returning errors to users.
Reactive scaling alone does not solve this. A target tracking policy watching CPU starts from the current running task count. If only 1 task is running when 500,000 users simultaneously hit the site, the policy fires — but the 60–90 seconds required for Fargate task provisioning, image pull, and ALB registration means users are already experiencing failure before new capacity is available.
</details>

<details>
<summary>Click to see how this autoscaling strategy improves performance</summary>

##### Decision — Two-Layer Scaling
 
##### Layer 1: Scheduled Pre-warming (Proactive)
 
```
cron(0 23 14 7 ? *)  →  min=8, max=25  (July 15 00:00 Morocco time)
cron(0 23 16 7 ? *)  →  min=1, max=7   (July 17 00:00 Morocco time)
```
 
> All schedules are UTC. Morocco observes WEST (UTC+1) in July — midnight Morocco time is 23:00 UTC the previous day.
 
8 tasks are running and healthy **before the first user arrives**. There is no cold start under load. The service absorbs the initial traffic surge immediately.
 
##### Layer 2: Target Tracking Policy (Reactive, within bounds)
 
```
Metric:               ECSServiceAverageCPUUtilization
Target:               75%
Scale-out cooldown:   60s
Scale-in cooldown:    300s
```
 
Once pre-warmed, the policy handles everything beyond the floor. If the spike is larger than anticipated, tasks scale out toward max=25. If traffic subsides mid-event, tasks scale back toward min=8.
 
The asymmetric cooldown is intentional:
- **60s scale-out** — react fast, users are waiting
- **300s scale-in** — be conservative, a 30-second traffic lull during a spike does not mean the spike is over
##### How They Interact
 
```
Scheduled action  →  controls the boundaries (min / max)
Target tracking   →  controls the count within those boundaries
```
 
A single policy governs all phases without modification. During the spike window it operates within `8–25`. During normal periods within `1–7`.
 
##### Alternatives Considered
 
**Reactive scaling only (no pre-warming)**
Rejected. Fargate provisioning latency (60–90s) means the service degrades before new capacity is available. For a simultaneous national traffic spike this is not acceptable.
 
**Scale to zero at night**
Considered for cost optimization. Rejected because ECS target tracking cannot scale from zero — no running tasks means no CPU metrics emitted to CloudWatch, so the scale-out signal never fires. The minimum viable floor is 1 task.

</details>

---

### Security Posture

- **Granular Network Security:** All compute (ECS), database (Aurora), and cache (Redis) instances are isolated inside private subnets. 
- **VPC PrivateLink Integration:** The architecture completely lacks a NAT Gateway, ensuring that private resources have no path to the public internet. Communication with AWS APIs (ECR, SQS, Cognito, Bedrock, Secrets Manager, CloudWatch) is routed exclusively over private VPC Interface Endpoints ([main.tf](infra/modules/endpoints/main.tf)) ([security_group.tf](/infra/modules/security/security_group.tf)).
- **Security Groups And The Rules:** Security group egress rules contain no rules permitting internet-bound traffic. Even in the absence of a network route to the internet, all task-level egress is explicitly restricted to internal VPC CIDR ranges and VPC endpoint ENIs — ensuring defense-in-depth where both the routing layer and the host layer independently enforce the no-internet-egress policy. ([rules.tf](infra/modules/security/rules.tf)) 
- **S3 Gateway Endpoint:** All S3 traffic from private subnets is routed through a VPC Gateway Endpoint, ensuring that object storage access never traverses the public internet. Combined with the no-NAT-Gateway design, this guarantees that private resources have no outbound path outside the AWS network for both API and object storage traffic.([gatewayendpoints.tf](infra/modules/vpc/gatewayendpoints.tf)).
- **End-to-End IAM Authentication:** The infrastructure eliminates static database credentials across the entire connection path. The Express backend running on ECS Fargate generates a short-lived AWS IAM authentication token (valid for 15 minutes) using its IAM Task Role to authenticate with the RDS Proxy. Concurrently, the RDS Proxy leverages native end-to-end IAM database authentication to connect directly to the Amazon Aurora cluster, completely bypassing traditional database passwords and eliminating the requirement for credential storage or rotation in AWS Secrets Manager.[aurora.tf](infra/modules/database/aurora.tf#L47) [aurora.tf](/infra/modules/database/rdsproxy.tf#L54)
- **Flyway Migration Credentials:** The Flyway migration task authenticates to Aurora using the master password managed and automatically rotated by AWS Secrets Manager via manage_master_user_password = true on the aws_rds_cluster resource. No static credentials are stored in the task definition or application configuration — the Flyway task execution role is granted read access to the generated secret ARN exclusively, ensuring the master password is never exposed outside of Secrets Manager. [aurora.tf](infra/modules/database/aurora.tf#L39)
- **Database Access — Least Privilege IAM User:** The application never connects to Aurora using the master credentials. Flyway creates a dedicated `db_iam_user` during the initial migration, it connects to Aurora through RDS Proxy using this user, authenticated via IAM — no static password, SSL enforced, and permissions scoped to only the operations the application requires.
- **Why Flyway Uses the Master Username Instead?:** Flyway cannot use `db_iam_user` for two reasons:
- No password: `db_iam_user` authenticates exclusively via `AWSAuthenticationPlugin`. Flyway connects directly to Aurora (bypassing RDS Proxy) and Aurora requires a password at the connection level. There is no IAM token exchange in a direct Aurora connection.
- Insufficient permissions: `db_iam_user` is granted only DML permissions. Flyway needs `CREATE` to build and manage the schema, which is intentionally withheld from the application user, The master credentials are managed by AWS via `manage_master_user_password`, rotated automatically in Secrets Manager, and used exclusively by Flyway at migration time.
- **Cognito security:** Cognito issues short-lived JWT tokens that are validated on every request by the Express backend using aws-jwt-verify — no session state is stored server-side, eliminating an entire class of session hijacking vulnerabilities. User passwords are never stored in Aurora or handled by the application layer — Cognito owns the credential store entirely. ([main.tf](infra/modules/cognito/main.tf)).
- **Container Root Hardening:** Both tasks flyway and app are configured with a read-only root filesystem (`readonlyRootFilesystem = true`) ([flywayecs.tf](infra/modules/compute/flywayecs.tf#L21))  ([ecs.tf](infra/modules/compute/ecs.tf#L60))
- **WAF Protection:** Attached to CloudFront to apply SQL injection, XSS, rate-limiting, and known bad inputs (Log4j) protection at the network edge ([waf.tf](infra/modules/cloudfront/waf.tf)).
- **Encrypted Remote State & Locking:** Storing the Terraform state file in a dedicated, private S3 bucket with server-side encryption (`encrypt = true`) ensures that sensitive generated parameters are protected at rest. Enabling S3 native state locking (`use_lockfile = true`) prevents concurrent execution conflicts, protecting the state from corruption during team deployments ([backend.tf](infra/backend.tf)).
- **Automated Security Scanning:** Checkov is embedded directly into the CI/CD pipeline, executing static analysis security checks on all Terraform files and failing the build if high-severity issues are detected ([terraform.yml](.github/workflows/terraform.yml#L79)).
- **ElastiCache Authentication (Known Gap):** Redis access is currently restricted by security group rules to ECS task IPs only. ElastiCache User Group Authentication (aws_elasticache_user_group) is not yet configured — this is a documented production gap.
- **Terraform Role Scoping:** The TerraformRole uses AWS-managed PowerUserAccess as a dev-phase baseline — a deliberate tradeoff to reduce pipeline configuration overhead during development. Since PowerUserAccess excludes IAM write permissions by design, I added a supplementary inline policy granting only the exact IAM actions required by Terraform, scoped exclusively to resource ARNs prefixed with massar-*, preventing the role from creating, modifying, or attaching policies to any resource outside the project boundary to minimize the security risk as much i can. Replacing PowerUserAccess with a fully custom IAM policy scoped exclusively to the services and actions this role requires is documented as a production improvement to achieve full least-privilege compliance ([terraformIAM.tf](/bootstrap/terraformIAM.tf)).
- **Deploy Role (Least-Privilege):** The DeployRole assumed by the application deployment pipeline follow the full least privilege using a fully custom IAM policy with no AWS managed policies attached. Every permission is scoped to the minimum required: S3 access is restricted to the static bucket ARN only; ECR push is restricted to the two Massar repository ARNs; ECS service management is scoped to the Massar service ARN; iam:PassRole is restricted to the three specific ECS task roles by ARN; SSM read access is restricted to the two Cognito parameter paths only; and ecs:RunTask includes an ArnEquals condition restricting execution to the Massar cluster only. The three statements using Resource = "*" — ecr:GetAuthorizationToken, ecs:RegisterTaskDefinition, and the network discovery actions — are AWS API-level constraints where resource-level scoping is not supported by IAM ([terraformIAM.tf](/bootstrap/deployIAM.tf)).

---

### Problem Solving

#### 1. Flyway Cannot Authenticate Through RDS Proxy
 
**Problem:** RDS Proxy was configured to require IAM authentication to eliminate static database credentials. Flyway does not support IAM auth, so it could not reach Aurora through the proxy.
 
**Solution:** Flyway connects directly to Aurora, bypassing the proxy, using `manage_master_user_password` — AWS manages and rotates the master password in Secrets Manager automatically. The proxy with IAM auth remains enforced for the application.
 
---
 
#### 2. ECR Bootstrap Deadlock
 
**Problem:** `terraform apply` failed because ECS Task Definitions referenced ECR images that did not exist yet — ECR was empty before the app pipeline ran.
 
**Solution:** Terraform registers a public placeholder image so the service reaches a stable state on first apply. `ignore_changes = [container_definitions]` prevents Terraform from ever overwriting the image field again. The `deploy-app` job then replaces the placeholder by registering a new task definition revision with the real SHA-tagged ECR image and updating the service to run it.
 
---
 
#### 3. S3 State Bucket Cannot Bootstrap Itself
 
**Problem:** Terraform cannot create the S3 bucket it uses as its own remote backend — the backend is read before any resources are processed.
 
**Solution:** A separate minimal Terraform module with a local backend is responsible solely for creating the S3 state bucket. This bootstrap module is run once before the main module. The main module then initializes normally against the S3 backend.
 
---
 
#### 4. Cognito IDs Hardcoded in the App Pipeline
 
**Problem:** The app pipeline needed Cognito User Pool and Client IDs. Hardcoding them would break every time Terraform recreated the Cognito resources.
 
**Solution:** Terraform writes the IDs to SSM Parameter Store after each apply. The app pipeline reads them dynamically at runtime — no hardcoded values, no manual updates.
 
---
 
#### 5. Static Files Out of Sync After Cognito Changes
 
**Problem:** The frontend static files embed Cognito IDs. When Terraform recreated Cognito, the static files in S3 still held the old IDs.
 
**Solution:** The Terraform pipeline sends a `repository_dispatch` event only when Cognito resources are modified or recreated. This triggers a dedicated workflow that reads the new IDs from SSM and re-uploads the static files to S3 automatically.
 
---
 
#### 6. App Job Blocked When Only Backend Files Changed
 
**Problem:** The app job depends on the Flyway migration job completing successfully. When only backend files changed and no migrations were modified, the migration job was skipped — which caused the app job to be blocked and never run.
 
**Solution:** The app job uses `needs` combined with an `if` condition. If only backend files changed, the app job runs directly without waiting for migration. If both changed, the migration job runs first and the app job waits for it to exit successfully before starting.

---

### Cost Optimisation & Sustainability

- **Fargate Graviton (ARM64) Compute:** ECS tasks run on AWS Graviton processors, delivering approximately 20% better price-performance than x86 instances. In alignment with AWS's sustainability goals, Graviton processors use less power per compute unit than equivalent x86 processors, reducing energy consumption and greenhouse gas emissions.([ecs.tf](/infra/modules/compute/ecs.tf#L36)).
- **Lambda ARM64 Optimization:** The SQS-triggered Lambda functions are configured to use the ARM64 architecture, providing a similar 20% price-performance improvement over x86, which lowers operational costs for asynchronous document and email processing.([lambda.tf](/infra/modules/notifications/lambda.tf)).
- **S3 gateway endpoint:** To bypass the high data processing fees and the 96$/monthly of standard NAT Gateways(3az), the architecture routes all object storage traffic through a VPC Gateway Endpoint for Amazon S3. Because Massar handles massive, high-throughput payloads—such as student digital transcripts, bulletins, and media assets—routing this traffic over standard network paths would incur uncapped variable data processing fees ($0.045/GB). Implementing the S3 Gateway Endpoint drops data transit fees for S3 to $0.00/GB with $0.00/hour infrastructure overhead, shifting terabytes of exam-period traffic entirely onto AWS private fiber for free ([gatewayendpoints.tf](infra/modules/vpc/gatewayendpoints.tf)).
- **CloudFront Edge Caching:** Caching static assets at CloudFront edge locations reduces origin requests to the ALB and ECS, directly lowering compute costs during peak results release periods.
- **In-Memory Database Caching:** Using ElastiCache Redis to cache student results prevents the Aurora database from needing to scale up to expensive, larger ACU capacities during results release day, saving database compute costs.
- **Transient Migration Tasks:** The Flyway container is executed as a short-lived ECS task that spins down immediately after completion, resulting in zero idle compute cost for database schema management ([deploy.yml](https://github.com/aymenelk01/massar-app/blob/main/.github/workflows/deploy.yml#L111)).
- **Infracost Pull Request Feedback:** Infracost is integrated into the CI/CD pipeline, checking every pull request and posting a cost impact diff comment before any infrastructure changes are applied, preventing surprise budget increases ([infracost.yml](.github/workflows/infracost.yml)).
- **ECR Storage Cost Control:** ECR repositories employ automated lifecycle policies that retain only the last 5 images tagged with `sha-*` for rollback security and immediately delete untagged or orphaned images older than 1 day, preventing storage volume accumulation and controlling registry storage costs.([main.tf](/infra/modules/ecr/main.tf)).
- **S3 Tiered Lifecycle Management:** Both the documents and logs S3 buckets use automated lifecycle configurations to minimize storage fees. The documents bucket transitions PDF diplomas to `STANDARD_IA` (Infrequent Access) after 90 days, archives them to `GLACIER` after 365 days, and deletes non-current versions after 30 days. The logs bucket transitions access logs to `STANDARD_IA` after 30 days, to `GLACIER` after 90 days, and permanently deletes them after 365 days, significantly reducing S3 storage costs.([s3logs.tf](/infra/modules/storage/s3logs.tf))([s3documents.tf](/infra/modules/storage/s3documents.tf)).
- **AWS Budgets Configuration:** An AWS Budget is configured to monitor costs monthly with a limit of $50/month(since this is a portfolio project), triggering email notifications if actual or forecasted costs exceed 80% of the threshold ([main.tf](budget/main.tf)).

- **Auto Scaling Strategy:** Massar's original infrastructure was statically provisioned for peak load year-round. This redesign eliminates that by matching capacity to actual demand at any given time, improving performance while saving money.([autoscaling.tf](/infra/modules/compute/autoscaling.tf)).

<details>
<summary>Click to see how this autoscaling strategy improves cost efficiency</summary>

##### Baseline — Normal Days
 
```
min_capacity = 1
max_capacity = 7
```
 
With Fargate, billing is per vCPU and memory second — you pay for every running task, whether it is serving requests or sitting idle. Holding `min_capacity = 1` instead of a static 8 means that on a normal day with low traffic, you are paying for 1 task instead of 8. That is a 87.5% reduction in baseline compute cost for approximately 360 days of the year. Additional tasks are launched only when CPU crosses 75%, billed only for the duration they run, and terminated once load drops.
 
##### Spike Window — Baccalaureate Results (48 hours)
 
```
min_capacity = 8
max_capacity = 25
```
 
The floor is raised to 8 tasks for exactly 48 hours around the results publication date, then automatically returns to `min=1, max=7` via a second scheduled action — no manual intervention required. The cost of those 8 tasks is incurred for 2 days out of 365. Scoping the elevated capacity to the actual event window rather than holding it year-round means the spike cost is contained and proportional to the demand that justifies it. Any tasks beyond the 8-task floor that target tracking launches during the spike are also automatically terminated once load subsides, so you never pay for peak capacity a minute longer than necessary.
 
##### Cost Impact
 
| Period | Min Tasks Running | Over-provisioned? |
|---|---|---|
| Normal days (~360 days/year) | 1 | No — scales on demand |
| Bac results window (~2 days/year) | 8 | No — required for the load |
 
This eliminates the only two costly mistakes: paying for 8+ tasks year-round, or crashing under load and scaling reactively after degradation has already started.

</details>

---

### CI/CD Pipeline Architecture

The system utilizes a three-pipeline architecture to manage infrastructure validation, application code deployments, and cost tracking.

```
massar-aws-infrastructure/          massar-app/
        │                                  │
  terraform.yml                      deploy.yml
  infracost.yml                            │
        │                                  │
  TerraformRole                      DeployRole
  (PowerUserAccess
   + customize IAM access)        (customize policy)
```

1.  **Terraform CI/CD (`terraform.yml`):** Triggered on any change to the `infra/**` path. The workflow is split into two mutually exclusive jobs controlled by the `github.event_name` conditional, so the CI job and the CD job never run simultaneously, also to avoid re-running validation steps that already passed on the pull request gate. On merge to main, the terraform-deploy job skips directly to plan and apply, since fmt, tflint, checkov, and validate were already enforced before the PR was approved. ([terraform.yml](.github/workflows/terraform.yml)):
    - **Job 1 — `terraform-validate` (Pull Request gate):** Runs exclusively on `pull_request` events. It assumes the `TerraformRole` via OIDC, then executes `terraform fmt -check` to enforce canonical formatting, initializes the backend, runs **TFLint** (with a pinned config at `infra/.tflint.hcl` and result caching) to enforce Terraform best practices, runs **Checkov** with `soft_fail: false` so any failing security check breaks the PR and cannot be bypassed, runs `terraform validate` to catch syntax and type errors, and finally runs `terraform plan` to produce a dry-run of the proposed changes. No infrastructure is created or modified at this stage — the job is a pure validation gate that must pass before any merge is allowed.

    - **Job 2 — `terraform-deploy` (Merge to main):** Runs exclusively on `push` events to `main`. It re-authenticates via OIDC, re-initializes the backend, generates a plan artifact (`-out=tfplan`), and applies it piping the JSON output through `jq` in real time so apply progress is readable in the GitHub Actions log rather than as a wall of raw JSON. After apply, it runs `terraform output` to surface the live resource identifiers. The job then inspects the apply output to detect whether any `aws_cognito` resource was created or updated, and if so runs a post-apply bootstrap script (`setup-cognito-admin.sh`) to provision the initial admin account in the new User Pool. Finally, if Cognito was touched, it dispatches a `repository_dispatch` event to the `massar-app` repository, triggering a frontend rebuild so the frontend config is immediately updated with the new Cognito Pool ID and Client ID. A final `Enforce Pipeline Status` step forces a non-zero exit if `terraform apply` failed, overriding any `if: always()` steps that would otherwise mask the failure.

#### Post-Apply Bootstrap: `setup-cognito-admin.sh`

Rather than requiring manual AWS Console intervention after a fresh deployment, the deployment pipeline automatically executes the `setup-cognito-admin.sh` script to create the initial admin account using the AWS CLI, ensuring the script dynamically targets the specific pool instance just created or updated, the `terraform-deploy` job calls [`setup-cognito-admin.sh`](infra/scripts/setup-cognito-admin.sh) automatically. The Pool ID is never hardcoded in the script; instead, the workflow extracts it at runtime with `terraform output -raw user_pool_id` and injects it as the `COGNITO_USER_POOL_ID` environment variable, so the script always targets the pool that was just created or updated.

The script is designed to be fully idempotent — running it multiple times against the same pool produces the same result without errors. The first thing it does is call `aws cognito-idp admin-get-user` and capture both the output and the exit code. If the exit code is zero the user already exists and the script exits immediately with no changes made. If the exit code is 254 and the output contains `UserNotFoundException` — the specific AWS CLI signal for a missing user — it proceeds through three sequential provisioning steps: `admin-create-user` with `--message-action SUPPRESS` to skip Cognito's default welcome email, `admin-set-user-password` with `--permanent` to bypass the forced-change-on-login flow that would otherwise block programmatic access, and `admin-add-user-to-group` to assign the account to the `admins` group, which maps to the role-based access control rules enforced by the Cognito authorizer on protected routes. Any other non-zero exit code — a network failure, an IAM permission error, or an unexpected AWS service error — falls into the `else` branch, which prints the raw error output and exits with code 1, killing the pipeline rather than silently swallowing the failure.

2.  **Application Deployment (`deploy.yml`):** Implements a three-job architecture to deploy code changes ([deploy.yml](https://github.com/aymenelk01/massar-app/blob/main/.github/workflows/deploy.yml)):
    - `how the deploy-migrations and deploy-app jobs work together`:deploy-migrations triggers only when changes are detected in the Flyway migration files path, and deploy-app triggers only when changes are detected in the application source path — allowing independent deployments when only one layer changes. When both paths are modified in the same push, deploy-migrations executes first and deploy-app is blocked from starting until migrations complete successfully. If deploy-migrations fails, deploy-app does not run — preventing the application from deploying against a schema it was not designed for.
    - `deploy-migrations`: Builds the Flyway migration Docker image for ARM64, pushes it to ECR, dynamically discovers the VPC subnets and security groups ids by AWS CLI, runs the migration task in ECS Fargate, and blocks until completion.
    - `deploy-app`: Triggered after migrations succeed. It builds the app container, pushes it to ECR, downloads the active ECS task definition, renders the new task definition with the updated image tag, updates the Fargate service, and waits for stability.
    - `deploy-static`: Reads the active Cognito User Pool ID and Client ID parameters from the SSM Parameter Store, builds the Vite static frontend, and synchronizes files to S3 with optimized cache-control headers.

3.  **Infracost (`infracost.yml`):** Automatically computes cost differences on Terraform pull requests. It runs a cost breakdown on the target branch, compares it to the proposed PR branch, and posts the difference directly to the GitHub PR comments ([infracost.yml](.github/workflows/infracost.yml)).

#### Keyless Access (CI/CD Authentication)

There are **zero long-lived AWS credentials** stored in GitHub Secrets—no `AWS_ACCESS_KEY_ID` or `AWS_SECRET_ACCESS_KEY` are used. Instead, authentication utilizes **OpenID Connect (OIDC)** federation. GitHub Actions establishes a trust relationship with AWS IAM using an Identity Provider (IdP) mapping. When a workflow executes, it requests a short-lived JSON Web Token from GitHub's OIDC provider, which AWS verifies and exchanges for temporary IAM session credentials via AWS STS.

- **Terraform Role:** assumed by the infrastructure pipeline ([terraformIAM.tf](bootstrap/terraformIAM.tf#L3)).
- **Deploy Role:** assumed by the application deployment pipeline ([deployIAM.tf](bootstrap/deployIAM.tf#L4)).

---

### Production Improvements

Below is an honest assessment of changes required to transition this portfolio project into a live production deployment:

- **SES Production Mode:** Request AWS to move the SES account out of the Sandbox environment to allow sending results emails to unverified student email addresses.
- **Route 53 & Custom Domain Name:** Create a Route 53 public hosted zone and associate it with a registered domain name (e.g., `massar.men.gov.ma`), replacing the default CloudFront URL.
- **HTTPS on Application Load Balancer:** Generate an ACM SSL/TLS certificate and configure HTTPS listeners on the ALB, ensuring encrypted transit between CloudFront and the ALB.
- **ElastiCache Redis User Group Authentication:** Replace the current unauthenticated ElastiCache access with fine-grained ElastiCache User Group Authentication (`aws_elasticache_user_group`) to restrict access.
- **Customer Managed Keys (CMK):** Replace default AWS-managed encryption keys with Customer Managed Keys in KMS for encrypting RDS, S3, ElastiCache, and CloudWatch logs.
- **Multi-Environment Pipeline:** Extend the pipelines to support distinct `dev`, `staging`, and `production` environments with manual approval gates between stages.
- **AWS Backup for Aurora:** Configure an AWS Backup plan to schedule daily backups and manage the lifecycle of Aurora DB snapshots.
- **Active Directory/Enterprise IdP Integration:** Configure Cognito federated identity providers to link with the Ministry of Education's existing Active Directory (ADFS) or SAML 2.0 Identity Provider.
- **Least-Privilege Terraform Role Scoping:** The current pipeline role utilizes the AWS-managed `PowerUserAccess` policy for simplicity during development. In a live production environment, this must be replaced with a custom, strictly scoped least-privilege IAM policy limited to the exact resource ARNs and API calls managed by Terraform.


