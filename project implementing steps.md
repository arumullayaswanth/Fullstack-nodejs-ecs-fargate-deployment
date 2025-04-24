
# 🚀 Fullstack Node.js ECS Fargate Deployment Guide

## Step 1: Grant Permissions to Terraform

1. Navigate to **IAM (Identity and Access Management)** in your AWS Console.
2. Go to **Users** → Click **Create User**.
3. Set **User Name** as `ecs-docker`.
4. Click **Next** → Select **Set Permissions** → **Permission Options**.
5. Choose **Attach Policies Directly** → Search and select `AmazonEC2ContainerRegistryFullAccess`.
6. Click **Next** → Click **Create User**.
7. Open the `ecs-docker` user profile.
8. Go to **Security Credentials** → **Access Key** → **Create Access Key**.
9. Choose **Use Case** → Select **CLI**.
10. Confirm: _"I understand the recommendation and want to proceed"_.
11. Click **Next** → **Create Access Key**.
12. Download the `.csv` file containing access credentials.

---

## Step 2: Push Code to GitHub using VS Code

1. 🖥️ Open **VS Code Terminal**:
   ```bash
   aws configure
   ```

2. Enter your credentials:
   ```
   aws_access_key_id     = YOUR_ACCESS_KEY
   aws_secret_access_key = YOUR_SECRET_KEY
   region                = us-east-1
   output                = table
   ```

3. Verify the configuration:
   ```bash
   aws configure list
   aws sts get-caller-identity
   ```

4. Clone the project repository:
   ```bash
   cd ~/Downloads
   mkdir Fullstack-nodejs-ecs-fargate-deployment
   cd Fullstack-nodejs-ecs-fargate-deployment
   git clone https://github.com/arumullayaswanth/Fullstack-nodejs-ecs-fargate-deployment.git
   cd Fullstack-nodejs-ecs-fargate-deployment
   ls
   ```

---

## Step 3: Build Docker Images

### 🛠️ Backend Image

1. Navigate to the backend directory:
   ```bash
   cd backend/
   ```

2. Authenticate Docker with ECR:
   ```bash
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 421954350274.dkr.ecr.us-east-1.amazonaws.com
   ```

3. Build the Docker image:
   ```bash
   docker build -t backend .
   ```

4. Tag the image:
   ```bash
   docker tag backend:latest 421954350274.dkr.ecr.us-east-1.amazonaws.com/backend:latest
   ```

5. Push the image:
   ```bash
   docker push 421954350274.dkr.ecr.us-east-1.amazonaws.com/backend:latest
   ```

---

### 🖼️ Frontend Image

1. Navigate to the frontend directory:
   ```bash
   cd ../frontend/
   ```

2. Authenticate Docker with ECR:
   ```bash
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 421954350274.dkr.ecr.us-east-1.amazonaws.com
   ```

3. Build the Docker image:
   ```bash
   docker build -t frontend .
   ```

4. Tag the image:
   ```bash
   docker tag frontend:latest 421954350274.dkr.ecr.us-east-1.amazonaws.com/frontend:latest
   ```

5. Push the image:
   ```bash
   docker push 421954350274.dkr.ecr.us-east-1.amazonaws.com/frontend:latest
   ```

---

## Step 4: Verify Image URLs

1. Go to AWS Console → **Amazon Elastic Container Registry**.
2. Select **backend** repository → Copy the image URI.
3. Select **frontend** repository → Copy the image URI.

---

## Step 5: Update Terraform Task Definitions

### Backend Task Definition

1. Go to **VS Code** → Open `terraform-ecs-fargate-fullstack-app` → Open `backend-task-server.tf`
2. Update your image in the `container_definitions` block:

   ```hcl
   container_definitions = jsonencode([
     {
       name      = "backend"
       image     = "421954350274.dkr.ecr.us-east-1.amazonaws.com/backend:latest"  # Replace with your backend image
       cpu       = 256
       memory    = 512
       essential = true
     }
   ])
   ```

### Frontend Task Definition

1. Go to **VS Code** → Open `terraform-ecs-fargate-fullstack-app` → Open `frontend-task-server.tf`
2. Update your image in the `container_definitions` block:

   ```hcl
   container_definitions = jsonencode([
     {
       name      = "frontend"
       image     = "421954350274.dkr.ecr.us-east-1.amazonaws.com/frontend:latest"  # Replace with your frontend image
       cpu       = 256
       memory    = 512
       essential = true
     }
   ])
   ```

---

> ✅ Now your ECS Task Definitions are configured to use the latest images from Amazon ECR!



# Fullstack Node.js ECS Fargate Deployment – Step-by-Step Guide

## 🏗️ VPC in Terraform

1. **Open VS Code Terminal** and run:
```bash
ll
cd terraform-ecs-fargate-fullstack-app/
ls
cd vpa-network
terraform init
terraform validate
terraform plan
terraform apply --auto-approve
terraform show
terraform state list
terraform destroy -auto-approve
```

---

## 🛢️ RDS in Terraform

1. **Navigate to RDS Directory**:
```bash
cd ..
ls
cd rds
terraform init
terraform validate
terraform plan
terraform apply --auto-approve
terraform show
terraform state list
```

---

## 🖥️ Create EC2 to Connect Private RDS

1. **Launch EC2 Instance**:
   - Go to EC2 → Launch Instance
   - Name: `bastion`
   - AMI: Amazon Linux
   - Keypair: Your selected key
   - VPC: `ecs-vpc`
   - Subnet: `ecs-public1`
   - Security Group: `terraform-98765432`
   - Launch

2. **Connect and Configure EC2**:
```bash
sudo -i
sudo yum install git -y
sudo yum install docker -y
sudo usermod -aG docker ec2-user
newgrp docker
sudo service docker start
sudo chmod 777 /var/run/docker.sock
yum install mariadb105-server -y

git clone https://github.com/arumullayaswanth/Fullstack-nodejs-ecs-fargate-deployment.git
cd backend/
mysql -h <your-rds-endpoint> -u admin -p < test.sql

(eg: mysql -h book-rds.c0n8k0a0swtz.us-east-1.rds.amazonaws.com -u admin -Yaswanth123reddy < test.sql)
```

---

## 🔄 Update ECS Task Definition with RDS Endpoint

1. **Backend Task Update** (`backend-task-server.tf`):

---
**Come back to VS code then change the ecs-task directory. And add rds endpoint near the db**

```hcl
environment = [
        { name = "DB_HOST", value = "book-rds.c0n8k0a0swtz.us-east-1.rds.amazonaws.com" },   // replace your databasw end point
        { name = "PORT", value = "3306" },
        { name = "DB_USERNAME", value = "admin" },
        { name = "DB_PASSWORD", value = "Yaswanth123reddy" }
      ]


```

---

## 🧱 ECS Task Terraform Deployment

```bash
cd ..
ls
cd ecs-task
terraform init
terraform validate
terraform plan
terraform apply --auto-approve
terraform show
terraform state list
```

---

## 🌐 Configure Route 53 Hosted Zone

1. **Create Hosted Zone**:
   - Domain: `aluru.site`
   - Type: Public Hosted Zone

2. **Update Hostinger Nameservers**:
   - Paste the 4 NS records from Route 53:
     - ns-865.awsdns-84.net
     - ns-1995.awsdns-97.co.uk
     - ns-1418.awsdns-59.org
     - ns-265.awsdns-73.com

3. **Create A Record in Route 53**:
   - Type: A - IPv4 address
   - Alias: Yes
   - Alias target: Your backend ALB

---

## 🔐 Request HTTPS Certificate with ACM

1. **Request Public Certificate** for `aluru.site`.
2. **Validate via Route 53**.
3. **Wait for Certificate Approval**.

---

## ➕ Add HTTPS Listener to Load Balancer

1. **Go to EC2 → Load Balancers → frontend-alb → Listeners**.
2. Add:
   - Protocol: HTTPS
   - Port: 443
   - Action: Forward to web target group
   - Security policy: ELBSecurityPolicy-2021-06
   - Select ACM Certificate

---

## 🌍 Access Your Application

Visit: [http://aluru.site](http://aluru.site)

---

## 💣 Destroy All Terraform Resources

```bash
terraform destroy -auto-approve
```

