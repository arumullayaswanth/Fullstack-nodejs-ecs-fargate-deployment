# 🧒 Project: Automatically Update ECS When New Image is Pushed to ECR

## 📌 Overview

This project uses AWS services to automatically update your ECS service when a new image is pushed to an ECR repository.

### 🔧 Tools Used

* **ECR (Elastic Container Registry)**
* **ECS (Elastic Container Service)**
* **Lambda**
* **EventBridge (CloudWatch Events)**
* **IAM Roles and Policies**

---

## 🏗️ Step-by-Step Implementation

### ✅ Step 1: Create an ECR Repository

1. Go to AWS Console → **ECR**
2. Click **Create repository**
3. Enter name: `flask-app-backend`
4. Leave everything else as default
5. Click **Create repository**

---

### ✅ Step 2: Build and Push Docker Image to ECR

```bash
# Replace with your values
AWS_ACCOUNT_ID=987654321000
AWS_REGION=us-east-1
REPO_NAME=flask-app-backend

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Build image
docker build -t $REPO_NAME .

# Tag image
docker tag $REPO_NAME:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPO_NAME:v1.0.3

# Push image to ECR
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPO_NAME:v1.0.3
```

---

### ✅ Step 3: Create an ECS Cluster

1. Go to **ECS** → Clusters → Create Cluster
2. Choose **Fargate**
3. Name: `production-backend-cluster`
4. Click **Create**

---

### ✅ Step 4: Create ECS Task Definition

1. Go to ECS → **Task Definitions** → Create new
2. Launch type: **Fargate**
3. Add container:

   * Name: `backend-container`
   * Image: `987654321000.dkr.ecr.us-east-1.amazonaws.com/flask-app-backend:v1.0.3`
   * Port: 5000
4. Click **Create**

---

### ✅ Step 5: Create ECS Service

1. Go to **Clusters → production-backend-cluster** → Create Service
2. Launch type: **Fargate**
3. Task definition: use the one you created
4. Number of tasks: 1
5. Click **Create Service**

---

### ✅ Step 6: Create Lambda Function

1. Go to AWS → **Lambda** → Create Function
2. Name: `AutoUpdateBackendOnPush`
3. Runtime: Python 3.12
4. Click **Create Function**

---

### ✅ Step 7: Add Lambda Code

Paste the Lambda code (see code section above).

```python
import boto3
import os
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ecs_client = boto3.client('ecs')

def lambda_handler(event, context):
    try:
        cluster_name = os.environ['ECS_CLUSTER']
        service_name = os.environ['ECS_SERVICE']
        container_name = os.environ['CONTAINER_NAME']

        # Get image details from ECR push event
        repository_name = event.get('detail', {}).get('repository-name')
        image_tag = event.get('detail', {}).get('image-tag')
        if not repository_name or not image_tag:
            raise ValueError("Missing 'repository-name' or 'image-tag' in event['detail']")

        # Construct full image URI
        account_id = os.environ['AWS_ACCOUNT_ID']
        region = os.environ['AWS_REGION']
        image_uri = f"{account_id}.dkr.ecr.{region}.amazonaws.com/{repository_name}:{image_tag}"
        logger.info(f"New image URI: {image_uri}")

        # Get current task definition
        service_desc = ecs_client.describe_services(cluster=cluster_name, services=[service_name])
        task_def_arn = service_desc['services'][0]['taskDefinition']
        task_def_desc = ecs_client.describe_task_definition(taskDefinition=task_def_arn)
        container_defs = task_def_desc['taskDefinition']['containerDefinitions']

        # Update image in container definition
        updated = False
        for container in container_defs:
            if container['name'] == container_name:
                container['image'] = image_uri
                updated = True

        if not updated:
            raise ValueError(f"Container name '{container_name}' not found in task definition.")

        # Register new task definition
        new_task = ecs_client.register_task_definition(
            family=task_def_desc['taskDefinition']['family'],
            executionRoleArn=task_def_desc['taskDefinition']['executionRoleArn'],
            networkMode=task_def_desc['taskDefinition']['networkMode'],
            containerDefinitions=container_defs,
            requiresCompatibilities=task_def_desc['taskDefinition']['requiresCompatibilities'],
            cpu=task_def_desc['taskDefinition']['cpu'],
            memory=task_def_desc['taskDefinition']['memory']
        )

        # Update service with new task definition
        ecs_client.update_service(
            cluster=cluster_name,
            service=service_name,
            taskDefinition=new_task['taskDefinition']['taskDefinitionArn']
        )

        logger.info("ECS service updated successfully.")
        return {"message": "ECS service updated with new image"}

    except Exception as e:
        logger.error(f"Error updating ECS service: {str(e)}")
        return {"error": str(e)}

```

---

### ✅ Step 8: Set Environment Variables

Under **Configuration → Environment variables**:

* `ECS_CLUSTER` = `production-backend-cluster`
* `ECS_SERVICE` = `flask-backend-service`
* `CONTAINER_NAME` = `backend-container`
* `AWS_ACCOUNT_ID` = `987654321000`
* `AWS_REGION` = `us-east-1`

---

### ✅ Step 9: Add IAM Permissions to Lambda

Attach this policy to Lambda's execution role:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:DescribeServices",
        "ecs:DescribeTaskDefinition",
        "ecs:RegisterTaskDefinition",
        "ecs:UpdateService"
      ],
      "Resource": "*"
    }
  ]
}
```

---

### ✅ Step 10: Create EventBridge Rule

1. Go to **EventBridge** → Rules → Create Rule
2. Name: `BackendAutoUpdateTrigger`
3. Event source: **AWS Services → ECR → Image Action**
4. Pattern:

```json
{
  "source": ["aws.ecr"],
  "detail-type": ["ECR Image Action"],
  "detail": {
    "action-type": ["PUSH"],
    "result": ["SUCCESS"]
  }
}
```

5. Set Target → **Lambda** → `AutoUpdateBackendOnPush`
6. Click **Create**

---

## ✅ Final Result

Every time you push a new image to ECR:

* EventBridge triggers the Lambda
* Lambda updates ECS Task Definition
* ECS runs the updated container

---

## 📈 Architecture Diagram

```
+------------+      Push        +-----------+       Triggers      +------------------------+
| Developer  |  ------------->  |   ECR     |  -----------------> |  Lambda (AutoUpdater)  |
+------------+                 +-----------+                     +------------------------+
                                                                      |
                                                                      | Calls
                                                                      v
                                                             +---------------------+
                                                             |   ECS Service       |
                                                             | (flask-backend-svc) |
                                                             +---------------------+
```

---

## 🏑 That's It!

You have successfully created a **fully automated pipeline** to update your ECS container on every ECR push using EventBridge and Lambda.


Done! ✅

- I've added random but realistic example values for:

1. ECR repo name: flask-app-backend
2. Image tag: v1.0.3
3. Account ID: 987654321000
4. ECS cluster: production-backend-cluster
5. Service name: flask-backend-service
6. Container name: backend-container
