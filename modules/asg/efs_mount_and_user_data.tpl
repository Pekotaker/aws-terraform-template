cat << EOF > ./user_data.sh 
#!/bin/bash -x
sudo apt update -y && sudo apt upgrade -y
sudo apt install docker.io -y
sudo systemctl start docker
sudo systemctl enable docker
sudo mkdir -p /etc/ecs
sudo touch /etc/ecs/ecs.config
echo "ECS_CLUSTER=${ecs_cluster_name}" | sudo tee -a /etc/ecs/ecs.config
sudo curl -O https://s3.us-west-2.amazonaws.com/amazon-ecs-agent-us-west-2/amazon-ecs-init-latest.amd64.deb
sudo dpkg -i amazon-ecs-init-latest.amd64.deb
sudo systemctl start ecs
sudo systemctl enable ecs
apt install awscli -y
apt install make -y
apt install docker-compose-v2 -y
echo 'success' > ~/user.log

EOF