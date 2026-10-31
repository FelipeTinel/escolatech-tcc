#!/bin/bash
# Executado no boot de cada instância criada pelo ASG.
# Sem "set -x": evita vazar a senha do banco no log.
set -euo pipefail
exec > >(tee /var/log/user-data.log) 2>&1

dnf install -y docker jq
systemctl enable --now docker

# Baixa a imagem do ECR
aws ecr get-login-password --region ${region} \
  | docker login --username AWS --password-stdin ${ecr_registry}
docker pull ${ecr_repo_url}:${image_tag}

# Lê a senha do banco no Secrets Manager (via IAM Role da instância)
SECRET_JSON=$(aws secretsmanager get-secret-value \
  --region ${region} \
  --secret-id ${db_secret_arn} \
  --query SecretString --output text)
DB_PASSWORD=$(echo "$SECRET_JSON" | jq -r .password)

docker rm -f app 2>/dev/null || true
docker run -d --name app --restart unless-stopped \
  -p ${app_port}:${app_port} \
  -e PORT=${app_port} \
  -e DB_HOST=${db_host} \
  -e DB_PORT=${db_port} \
  -e DB_NAME=${db_name} \
  -e DB_USER=${db_username} \
  -e DB_PASSWORD="$DB_PASSWORD" \
  ${ecr_repo_url}:${image_tag}
