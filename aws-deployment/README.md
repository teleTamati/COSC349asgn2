# Task Tracker - Cloud Deployment

A distributed task management application deployed on AWS using Infrastructure as Code (Terraform).

[![AWS](https://img.shields.io/badge/AWS-Cloud-orange)](https://aws.amazon.com/)
[![Terraform](https://img.shields.io/badge/Terraform-IaC-blue)](https://terraform.io/)
[![CloudWatch](https://img.shields.io/badge/CloudWatch-Monitoring-green)](https://aws.amazon.com/cloudwatch/)

## Architecture
- **Frontend Server**: Web interface for task management
- **API Server**: RESTful API handling business logic
- **Database Server**: MySQL database for persistent storage
- **CloudWatch**: Monitoring and alerting system

##  Quick Start

### Prerequisites
- AWS CLI configured with valid credentials
- Terraform installed
- SSH key pair created in AWS

## Option 1: Using Pre-configured Vagrant VM
If you don't have Terraform installed locally, use the included Vagrant VM:

```bash
# Clone repository
git clone https://github.com/teleTamati/COSC349asgn2.git
cd COSC349asgn2

# Start the VM with Terraform pre-installed
vagrant up
vagrant ssh

# Navigate to deployment directory
cd /vagrant/aws-deployment

# Deploy infrastructure
terraform init
terraform apply

# Get your application URLs
terraform output

```

### Option 2: Deploying Directly from Your Local Machine

```bash
# Clone repository
git clone https://github.com/teleTamati/COSC349asgn2.git
cd COSC349asgn2/aws-deployment

# Ensure AWS CLI and Terraform are installed locally
# Configure AWS credentials
aws configure

# Deploy infrastructure
terraform init
terraform apply

# Access your application
terraform output
```