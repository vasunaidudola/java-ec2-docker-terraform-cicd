#!/bin/bash
yum update -y
amazon-linux-extras install docker -y || yum install docker -y
systemctl enable docker
systemctl start docker

docker pull ${dockerhub_username}/${image_name}:${image_tag}

docker run -d --name java-app -p 80:8080 --restart always ${dockerhub_username}/${image_name}:${image_tag}
