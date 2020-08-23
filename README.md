# Aws_Terraform_Task_1
Build an Infrastructure as a Code(Iaas) on AWS using Terraform

# Objective: 
Launch/Create Application on AWS using Terraform

# AWS Services used:
- EC2
- EBS
- S3
- CloudFront

# STEPS
1. Create the key and security group which allow the port 80.
2. Launch EC2 instance.
3. In this Ec2 instance use the key and security group which we have created in step 1.
4. Launch one Volume (EBS) and mount that volume into /var/www/html
5. Developer have uploded the code into github repo also the repo has some images.
6. Copy the github repo code into /var/www/html
7. Create S3 bucket, and copy/deploy the images from github repo into the s3 bucket and change the permission to public readable.
8. Create a Cloudfront using s3 bucket(which contains images) and use the Cloudfront URL to  update in code in /var/www/html
9. Launch the website automatically

# Aws_Terraform_Task_2
Objective is Same as Task 1 but with few changes: Mount Amazon EFS (Elastic File System) instead of EBS in EC2 instance.

# AWS Services used:
- EC2
- EFS
- S3
- CloudFront

# STEPS
1. Create the key and security group which allow the port 80 (http), 22 (ssh) , 2049 (nfs).
2. Launch EC2 instance.
3. In this Ec2 instance use the key and security group which we have created in step 1.
4. Create one EFS file system, create a EFS mount target for EFS file system, install "amazon-efs-utils" package into EC2 instance and mount that File Storage (EFS) to /var/www/html
5. Developer have uploded the code into github repo also the repo has some images.
6. Copy the github repo code into /var/www/html
7. Create S3 bucket, and copy/deploy the images from github repo into the s3 bucket and change the permission to public readable.
8. Create a Cloudfront using s3 bucket(which contains images) and use the Cloudfront URL to  update in code in /var/www/html
9. Launch the website automatically


# Aws_Terraform_Task_3
Article: https://medium.com/@vikasgargvi/iaac-infrastructure-as-a-code-using-terraform-for-deploying-secure-wordpress-application-and-f8241c3faa25

# Aws_Terraform_Task_4
Medium Article: https://medium.com/@vikasgargvi/infrastructure-as-a-code-using-terraform-deploy-wordpress-on-public-subnet-and-mysql-on-private-ae996dae8aca

# Aws_Terraform_Task_6
Medium Article: https://medium.com/@vikasgargvi/connect-wordpress-with-aws-rds-relational-database-service-dc26bb390e64
