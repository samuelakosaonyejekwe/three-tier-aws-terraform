# Three-Tier AWS Terraform (eu-west-2) ...

## Architecture
- VPC across 2 AZs: eu-west-2a, eu-west-2b
- Public subnets (2): Public ALB + NAT gateways
- Private web subnets (2): Web ASG desired=2 (Nginx + Git)
- Private app subnets (2): Internal ALB + App ASG desired=2 (Apache + PHP + MySQL client + Git)
- Private db subnets (2): Aurora MySQL (cluster + writer + reader)
- Route53: app.samproject.com -> Public ALB
- ACM: certificate for app.samproject.com with DNS validation
- HTTPS 443 on public ALB + HTTP->HTTPS redirect
- SSM enabled for instances (Session Manager)

## Folder layout
- infra/: Terraform code
- user-data/: boot scripts

## Deploy
1) Configure AWS credentials:
   aws configure
   Region: eu-west-2

2) Set variables (DO NOT COMMIT terraform.tfvars):
   cp infra/terraform.tfvars.example infra/terraform.tfvars
   nano infra/terraform.tfvars

3) Run:
   cd infra
   terraform init
   terraform fmt -recursive
   terraform validate
   terraform plan
   terraform apply

## Test
- https://app.samproject.com  (should load web tier)
- https://app.samproject.com/api/  (should proxy to app tier)
- http://app.samproject.com  (should redirect to https)

## SSM Access
AWS Console -> Systems Manager -> Session Manager -> Start session
