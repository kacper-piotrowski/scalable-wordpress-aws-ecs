# AWS WordPress Infrastructure (Terraform)
The goal of this project is to automate the deployment of a scalable, high-availability cloud infrastructure on AWS using Terraform. It provisions an isolated network environment, a relational database, shared storage, and an auto-scaling ECS cluster capable of hosting multiple independent WordPress services.

## Main Features:
- Multi-AZ network architecture: dedicated VPC (`10.1.0.0/16`) with 2 public and 2 private subnets across two Availability Zones, an Internet Gateway, and 2 independent NAT Gateways
- Container orchestration and scaling: ECS cluster running on EC2 instances managed by an Auto Scaling Group, Capacity Providers, and Target Tracking scaling policies (triggered at 80% CPU usage)
- Multi-tenant WordPress deployment: dynamic generation of ECS Task Definitions (`wordpress:latest`), Target Groups, and Application Load Balancer listeners from a single service map (`local.wp_services`) with dynamic host port mapping
- Persistent shared storage: Amazon EFS mounted across private subnets with dedicated EFS Access Points (`/service1`, `/service2`, POSIX `UID/GID = 33`) isolating files for each WordPress instance
- Automated database provisioning: RDS MySQL 8.0 instance in private subnets initialized automatically on startup via a Bastion Host executing a template script (`create_db.sh.tpl`)
- Environment sizing: dynamic adjustment of EC2 instance types, scaling limits, and RDS Multi-AZ redundancy based on the selected environment type (`TEST`, `DEVELOPER`, `PRODUCTION`)

## Technologies and Services Used:
- Infrastructure as Code: `Terraform (HCL)`, `Bash` (`cloud-init` template scripts)
- AWS Compute & Containers: `Amazon ECS`, `Amazon EC2`, `Auto Scaling Groups`, `Application Load Balancer (ALB)`
- AWS Storage & Database: `Amazon RDS (MySQL 8.0)`, `Amazon EFS`
- AWS Networking & Security: `VPC`, `NAT Gateway`, `Internet Gateway`, `Security Groups`

## Project Structure:
- `vpc.tf` - definition of the VPC, public and private subnets, Internet Gateway, NAT Gateways, and routing tables
- `sgs.tf` - Security Groups restricting traffic between the Load Balancer, ECS cluster (ephemeral ports `32768-65535`), Bastion Host, and RDS/EFS
- `data.tf` - configuration of the RDS MySQL instance, EFS file system, mount targets, and per-service EFS Access Points
- `cluster.tf` - ECS cluster definition, EC2 Launch Template, Auto Scaling Group, and Capacity Provider configuration
- `apps.tf` - Application Load Balancer, Target Groups, ECS Task Definitions, Services, and CPU auto-scaling policies
- `bastion.tf` & `create_db.sh.tpl` - Bastion Host instance in the public subnet and the bash template script that creates separate MySQL databases for each WordPress service
- `vars.tf` - input variables for environment type, AWS region, SSH keys, database credentials, and IAM Instance Profile name

## How to Run:
1. Edit the `vars.tf` with your chosen variable values

2. Initialize Terraform and check the execution plan:
```bash
terraform init
terraform plan
```
3. Deploy the infrastructure to AWS:
```bash
terraform apply
```

## Configuration Parameters (`vars.tf`):
- `chosentype` - sets the environment profile (`TEST`, `DEVELOPER`, `PRODUCTION`), adjusting EC2 instance sizes (`t3.micro` to `t3.medium`) and toggling RDS `multi_az`
- `chosenregion` - target AWS region with automatic Availability Zone discovery
- `db_password` - sensitive variable storing the master password for the RDS MySQL instance
- `ssh_name` - name of the EC2 Key Pair used for SSH access to the Bastion Host (defaults to `vockey` for AWS Academy)
- `iam_instance_profile_name` - IAM Instance Profile name for EC2 ECS instances (defaults to `LabInstanceProfile` for AWS Academy)
