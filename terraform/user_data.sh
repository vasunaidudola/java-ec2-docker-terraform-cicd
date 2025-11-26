#!/bin/bash
# Deploy version: ${deploy_version}

yum update -y
amazon-linux-extras install docker -y || yum install docker -y
systemctl enable docker
systemctl start docker

# Pull latest image
docker pull ${dockerhub_username}/${image_name}:${image_tag}

# Stop and remove old container if it exists
docker rm -f java-app || true

# Run container
docker run -d --name java-app -p 80:8080 --restart always ${dockerhub_username}/${image_name}:${image_tag}
