Certainly\! Here is the `README.md` file for your Terraform project.

-----

# Yoobee College Multi-Cloud Infrastructure Migration Project (AWS + Azure Hybrid Cloud)

## Overview

This project provides the **Terraform configuration** for migrating Yoobee College's infrastructure to a **hybrid cloud environment**, leveraging both **AWS and Azure**. It deploys a **WordPress application** with its associated database (RDS), load balancer, S3 buckets, Lambda functions, and CloudWatch alarms on AWS. On the Azure side, it sets up a DNS Zone and a CNAME record pointing to the AWS Load Balancer.

The primary goal is to establish a **scalable and highly available WordPress environment** that meets operational requirements for logging, database backups, security monitoring, and more.

-----

## Architecture Summary

The main components deployed by this project are as follows:

### AWS (Amazon Web Services)

  * **VPC (Virtual Private Cloud)**: An isolated network environment for the WordPress application.
  * **EC2 (Elastic Compute Cloud)**: Web servers running the WordPress application. **Scalability and high availability** are ensured by an **Auto Scaling Group**.
  * **RDS (Relational Database Service)**: A MySQL database storing WordPress data. **High availability** is achieved through **Multi-AZ deployment**.
  * **ALB (Application Load Balancer)**: Distributes traffic to EC2 instances and terminates HTTPS connections.
  * **S3 (Simple Storage Service)**: Stores load balancer access logs, CloudWatch log exports, and RDS backups.
  * **Lambda (Serverless Compute)**:
      * A function to automate RDS snapshot backups.
      * A function to export CloudWatch Logs to S3.
  * **IAM (Identity and Access Management)**: Roles and policies required for seamless service integration.
  * **CloudWatch (Monitoring and Observability)**:
      * Monitors metrics and sets alarms for EC2, RDS, and Auto Scaling Group.
      * Notifies on EC2 instance state changes.
  * **EventBridge (Serverless Event Bus)**: Rules to trigger periodic backups and log exports.
  * **SNS (Simple Notification Service)**: Delivers alarm notifications.

### Azure (Microsoft Azure)

  * **Resource Group**: Logically groups Azure resources.
  * **DNS Zone**: Manages DNS records for the custom domain (`loadbalancers-yoobeecolleges.xyz`).
  * **CNAME Record**: Redirects traffic from `www.loadbalancers-yoobeecolleges.xyz` to the AWS ALB.

-----

## Prerequisites

To deploy this project, you'll need the following:

  * **Terraform CLI**: Version 1.0 or newer.
  * **AWS CLI**: Configured with credentials to provision AWS resources.
      * Ensure appropriate credentials are set up in `~/.aws/credentials` or via environment variables.
  * **Azure CLI**: Authenticated to provision Azure resources.
      * You should be logged in using `az login`.
  * **SSH Key Pair**: An SSH key pair for connecting to AWS EC2 instances must exist at `~/.ssh/id_rsa.pub`.
      * If you're using a different path, please update the `public_key` path in the `aws_key_pair.wordpress` resource within `asg.tf`.
  * **Domain Name**: Ownership of `loadbalancers-yoobeecolleges.xyz` (or your custom domain set in `variables.tf`) and the ability to manage its DNS with Azure DNS.

-----

## Setup and Deployment

### 1\. Clone the Repository

```bash
git clone <URL of this repository>
cd <repository-name>
```

### 2\. Prepare Variable File (Optional)

While `variables.tf` has default values, you can create a `terraform.tfvars` file to override them if needed. It's **highly recommended** to set sensitive variables like `db_password` in this file.

Example: `terraform.tfvars`

```terraform
aws_region  = "ap-southeast-2"
environment = "development"
domain_name = "your-custom-domain.com"
admin_ip    = "YOUR_PUBLIC_IP/32" # Replace with your current public IP address
db_password = "YourStrongDBPassword"
```

**Note**: If you include sensitive information in `terraform.tfvars`, ensure this file is added to `.gitignore` and is **not** committed to your Git repository.

### 3\. Initialize Terraform

Download the necessary provider plugins and initialize the backend. It's **strongly recommended** to create a `backend.tf` file and configure a remote backend (e.g., AWS S3 or Azure Storage Account).

Example: `backend.tf` (for AWS S3)

```terraform
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket" # Replace with your S3 bucket name
    key            = "yoobee-migration/terraform.tfstate"
    region         = "ap-southeast-2"
    encrypt        = true
    dynamodb_table = "your-terraform-state-lock-table" # Optional: for state locking
  }
}
```

```bash
terraform init
```

### 4\. Review the Plan

Check the changes Terraform will make before applying them.

```bash
terraform plan
```

### 5\. Deploy the Infrastructure

If the plan looks good, proceed to deploy the infrastructure.

```bash
terraform apply
```

Type `yes` when prompted to confirm.

### 6\. Post-Deployment Verification

Once the deployment is complete, you can retrieve output information using:

```bash
terraform output
```

Specifically, check the `wordpress_public_url` and verify that you can access the WordPress setup page in your browser.

-----

## Cleanup

To destroy all deployed resources, run:

```bash
terraform destroy
```

Type `yes` when prompted to confirm.

**Caution**: `terraform destroy` will remove all resources. Exercise extreme care when running this in a production environment.

-----

## File Structure

The project files are logically separated by purpose as follows:

```
.
├── main.tf                 # Main Terraform configuration and provider definitions
├── variables.tf            # All variable definitions
├── data.tf                 # Data source definitions
├── azure.tf                # Azure-related resources (Resource Group, DNS Zone, CNAME)
├── network.tf              # AWS networking resources (VPC, Subnets, Route Tables)
├── security_groups.tf      # All security group definitions
├── s3.tf                   # S3 bucket and related configurations
├── rds.tf                  # RDS database and subnet group
├── alb.tf                  # AWS Application Load Balancer and related resources (Target Group, ACM, Listeners)
├── iam.tf                  # IAM roles and policies
├── lambda.tf               # Lambda functions and their inline code
├── eventbridge.tf          # EventBridge rules and targets
├── sns.tf                  # SNS topic and subscriptions
├── alarms.tf               # CloudWatch alarms
├── asg.tf                  # EC2 Launch Template, Key Pair, Auto Scaling Group, Scaling Policies
├── outputs.tf              # Output information after deployment
└── .gitignore              # Files to exclude from Git version control
```

-----

## Important Notes

  * **Sensitive Information**: While sensitive variables like `db_password` are marked with `sensitive = true` in `variables.tf`, if you include them directly in a `terraform.tfvars` file, ensure that file is properly excluded from Git via `.gitignore`. For enhanced security, consider using secret management services like AWS Secrets Manager or Azure Key Vault.
  * **Terraform State**: For team collaboration and production deployments, managing your Terraform state file (`.tfstate`) in a **remote backend** (e.g., AWS S3 with DynamoDB for locking) is crucial. This prevents state corruption and conflicts.
  * **Domain Validation**: The ACM certificate used for the ALB's HTTPS listener requires DNS validation. Although Terraform automatically creates the necessary CNAME record in the Azure DNS Zone after requesting the certificate, it may take some time for the certificate to be issued.
  * **CloudWatch Logs**: The CloudWatch agent on your EC2 instances is configured to collect logs, and a Lambda function is set up to export these logs to S3. The log group names (e.g., `/ec2/wordpress/messages`) are defined in the `user_data` script within `asg.tf`.