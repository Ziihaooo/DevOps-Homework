# Code to Cloud - DevOps Deployment Project**Edit a file, create a new file, and clone from Bitbucket in under 2 minutes**



A containerized Node.js application with Nginx reverse proxy, deployed to AWS EC2 using Docker, Bitbucket Pipelines, and AWS SSM.When you're done, you can delete the content in this README and update the file with details for others getting started with your repository.



## 🏗️ Architecture*We recommend that you open this README in another tab as you perform the tasks below. You can [watch our video](https://youtu.be/0ocf7u76WSo) for a full demo of all the steps in this tutorial. Open the video in a new tab to avoid leaving Bitbucket.*



- **App Service**: Node.js HTTP server running on port 3000---

- **Nginx**: Reverse proxy with health check endpoint

- **Docker Compose**: Orchestrates both services## Edit a file

- **AWS EC2**: Target deployment environment

- **Bitbucket Pipelines**: CI/CD automationYou’ll start by editing this README file to learn how to edit a file in Bitbucket.

- **AWS S3**: Artifact storage

- **AWS SSM**: Remote command execution1. Click **Source** on the left side.

2. Click the README.md link from the list of files.

## 📋 Prerequisites3. Click the **Edit** button.

4. Delete the following text: *Delete this line to make a change to the README from Bitbucket.*

- Docker & Docker Compose5. After making your change, click **Commit** and then **Commit** again in the dialog. The commit page will open and you’ll see the change you just made.

- AWS CLI configured6. Go back to the **Source** page.

- Make

- Bitbucket repository with OIDC configured---

- AWS EC2 instance with appropriate IAM role

- AWS S3 bucket for artifacts## Create a file



## 🚀 DeploymentNext, you’ll add a new file to this repository.



### Automated Deployment (CI/CD)1. Click the **New file** button at the top of the **Source** page.

2. Give the file a filename of **contributors.txt**.

Push to the `DEVOPSOCT-48` branch to trigger:3. Enter your name in the empty file space.

1. **Lint** - Validates Dockerfile syntax4. Click **Commit** and then **Commit** again in the dialog.

2. **Build** - Creates Docker images5. Go back to the **Source** page.

3. **Push** - Publishes to Docker Hub

4. **Deploy** - Deploys to EC2 via AWS SSMBefore you move on, go ahead and explore the repository. You've already seen the **Source** page, but check out the **Commits**, **Branches**, and **Settings** pages.

5. **Verify** - Health check validation

---

### Manual Deployment

## Clone a repository

```bash

# Build and push imagesUse these steps to clone from SourceTree, our client for using the repository command-line free. Cloning allows you to work on your files locally. If you don't yet have SourceTree, [download and install first](https://www.sourcetreeapp.com/). If you prefer to clone from the command line, see [Clone a repository](https://confluence.atlassian.com/x/4whODQ).

make build

make push1. You’ll see the clone button under the **Source** heading. Click that button.

2. Now click **Check out in SourceTree**. You may need to create a SourceTree account or log in.

# Upload deployment files to S33. When you see the **Clone New** dialog in SourceTree, update the destination path and name if you’d like to and then click **Clone**.

make upload-s34. Open the directory you just created to see your repository’s files.



# Deploy to EC2Now that you're more familiar with your Bitbucket repository, go ahead and add a new file locally. You can [push your change back to Bitbucket with SourceTree](https://confluence.atlassian.com/x/iqyBMg), or you can [add, commit,](https://confluence.atlassian.com/x/8QhODQ) and [push from the command line](https://confluence.atlassian.com/x/NQ0zDQ).
make deploy

# Verify deployment health
make verify
```

## 🔧 Available Commands

### Build & Test
```bash
make lint          # Lint Dockerfiles
make build         # Build app and nginx images
make test-nginx    # Test nginx configuration
```

### Deploy & Manage
```bash
make deploy        # Deploy to EC2 via AWS SSM
make verify        # Check deployment health (30 retries)
make up            # Start containers locally
make down          # Stop containers
```

## 🏥 Health Checks

The application includes two health endpoints:

**App Health Endpoint** (internal):
```bash
curl http://localhost:3000/api/health
# Returns: {"status":"ok"}
```

**Nginx Health Endpoint** (public):
```bash
curl http://<EC2_PUBLIC_IP>/health
# Returns: Service is healthy
```

**Automated Health Verification**:
```bash
make verify
# Polls http://<EC2_IP>/api/health for 90 seconds
# ✅ Success: "Deployment healthy!"
# ❌ Failure: "Deployment did NOT become healthy in time"
```

## 📋 Logs

### View Logs on EC2 (via SSH)
```bash
ssh ec2-user@<EC2_IP>
cd /opt/codetocloud
sudo docker-compose logs -f              # All services
sudo docker-compose logs -f app          # App only
sudo docker-compose logs -f nginx        # Nginx only
sudo docker-compose logs --tail=100 app  # Last 100 lines
```

### Local Logs
```bash
docker-compose logs -f
docker-compose logs -f app
docker-compose logs -f nginx
```

## 🔄 Reload/Restart

### Restart Specific Service
```bash
docker-compose restart app
docker-compose restart nginx
```

### Reload Entire Stack
```bash
make down
make up
```

### Zero-Downtime Reload on EC2 (via SSM)
```bash
aws ssm send-command \
  --instance-ids i-0e9efb73e3f4a89a6 \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["cd /opt/codetocloud","sudo docker-compose pull","sudo docker-compose up -d --force-recreate"]' \
  --region ap-southeast-2
```

## ⏮️ Rollback

### Rollback to Previous Version

1. **Identify previous tag**:
```bash
# Check your Docker Hub or git history
git log --oneline -5
```

2. **Redeploy with specific tag**:
```bash
# Set VERSION to previous commit hash
make deploy APP_TAG=<previous-commit-hash>
make verify
```

3. **Quick rollback via SSM**:
```bash
aws ssm send-command \
  --instance-ids i-0e9efb73e3f4a89a6 \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["cd /opt/codetocloud","export APP_TAG=<previous-tag>","sudo -E docker-compose pull","sudo -E docker-compose up -d --force-recreate"]' \
  --region ap-southeast-2
```

## 🔐 Environment Variables

Set these in Bitbucket Pipeline variables:

- `DOCKER_USERZ` - Docker Hub username
- `DOCKER_PASSZ` - Docker Hub password
- `AWS_ROLE_ARN` - AWS IAM role for OIDC
- `EC2_INSTANCE_ID` - Target EC2 instance
- `S3_BUCKET` - S3 bucket for artifacts

## 📦 Docker Images

Images are tagged with git commit hash:
```
<DOCKER_USERZ>/codetocloud-app:<commit-hash>
<DOCKER_USERZ>/codetocloud-nginx:<commit-hash>
```

## 🏥 Health Check Configuration

**App Container**:
- Endpoint: `http://localhost:3000/api/health`
- Interval: 30s
- Timeout: 10s
- Retries: 3

**Nginx Container**:
- Endpoint: `http://localhost/health`
- Interval: 30s
- Timeout: 10s
- Retries: 3
- Depends on: App health check passing

## 🛠️ Troubleshooting

### Check Container Status
```bash
docker-compose ps
docker-compose logs
```

### Access EC2 and Debug
```bash
ssh ec2-user@<EC2_IP>
cd /opt/codetocloud
sudo docker-compose ps
sudo docker-compose logs --tail=50
```

### Verify Environment Variables
```bash
cat /opt/codetocloud/.env
```

### Test AWS Connectivity
```bash
make OICDcheck  # Verify OIDC and S3 access
```

## 📁 Project Structure

```
.
├── app/
│   ├── Dockerfile          # Node.js app container
│   ├── server.js           # Simple HTTP server with /api/health
│   └── package.json
├── deploy/
│   └── nginx/
│       ├── Dockerfile.nginx
│       └── default.conf    # Nginx reverse proxy config
├── docker-compose.yml      # Multi-container orchestration
├── Makefile               # Automation commands
└── bitbucket-pipelines.yml # CI/CD pipeline
```

## 🎯 Deployment Flow

1. Developer commits to `DEVOPSOCT-48` branch
2. Bitbucket Pipeline triggers
3. Images are linted, built, and pushed to Docker Hub
4. Deployment files uploaded to S3
5. AWS SSM executes deployment on EC2:
   - Installs Docker and dependencies
   - Downloads docker-compose from S3
   - Pulls latest images from Docker Hub
   - Starts containers with docker-compose
6. Health verification ensures services are running
7. ✅ Deployment complete!

## 📊 How EC2 Runs the Images

### Deployment Process on EC2

When `make deploy` runs, it uses **AWS Systems Manager (SSM)** to execute commands on your EC2 instance:

1. **Preparation**:
   - Updates system packages (`yum update`)
   - Installs Docker and Make
   - Enables and starts Docker service

2. **Download Dependencies**:
   - Downloads `docker-compose` binary from S3 to `/usr/local/bin/`
   - Downloads `docker-compose.yml` from S3 to `/opt/codetocloud/`
   - Downloads `Makefile` from S3 to `/opt/codetocloud/`

3. **Environment Configuration**:
   - Creates `.env` file with:
     - `PROJECT_NAME=codetocloud`
     - `DOCKER_USERZ=<your-docker-username>`
     - `DOCKER_REPO=codetocloud`
     - `APP_TAG=<git-commit-hash>`

4. **Container Deployment**:
   - Runs `make up` which:
     - Stops old containers (`docker-compose down`)
     - Pulls latest images from Docker Hub
     - Starts containers in detached mode (`docker-compose up -d`)
     - Waits for services to become healthy

5. **Container Runtime**:
   - Docker daemon manages container lifecycle
   - Containers restart automatically on failure (`restart: always`)
   - Health checks run every 30 seconds
   - Nginx proxies traffic to the Node.js app

### How to Verify EC2 is Running Images

```bash
# SSH into EC2
ssh ec2-user@<EC2_PUBLIC_IP>

# Check running containers
sudo docker ps

# View container details
sudo docker inspect codetocloud-app
sudo docker inspect codetocloud-nginx

# Check which images are running
sudo docker images | grep codetocloud

# View resource usage
sudo docker stats
```
