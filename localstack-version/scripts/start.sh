#!/bin/bash

echo "🚀 Starting LocalStack version of Lambda CI/CD Sample..."

# 前回のコンテナを停止・削除
docker-compose down --remove-orphans

# LocalStackデータディレクトリを作成
mkdir -p localstack-data

# 環境変数を読み込み
if [ -f .env.local ]; then
    export $(cat .env.local | grep -v '^#' | xargs)
fi

# DockerComposeでサービスを起動
echo "Starting LocalStack..."
docker-compose up -d localstack

echo "Waiting for LocalStack to be ready..."
max_attempts=30
attempt=0
until curl -s http://localhost:4566/health > /dev/null 2>&1; do
    attempt=$((attempt + 1))
    if [ $attempt -ge $max_attempts ]; then
        echo "❌ LocalStack failed to start after $max_attempts attempts"
        docker-compose logs localstack
        exit 1
    fi
    echo "Waiting for LocalStack... (attempt $attempt/$max_attempts)"
    sleep 3
done

echo "LocalStack is ready! Initializing AWS resources..."
./scripts/init-aws.sh

echo "Building and starting Lambda functions..."
docker-compose up -d

echo "LocalStack Dashboard: http://localhost:4566"
echo ""
echo "Lambda Function Endpoints:"
echo "  User Management:  http://localhost:9001/2015-03-31/functions/function/invocations"
echo "  Data Processor:   http://localhost:9002/2015-03-31/functions/function/invocations" 
echo "  Notification:     http://localhost:9003/2015-03-31/functions/function/invocations"
echo "  Health Check:     http://localhost:9004/2015-03-31/functions/function/invocations"
echo ""
echo "Use 'docker-compose logs -f' to see logs"
echo "Use './scripts/test.sh' to run tests"
echo "Use './scripts/stop.sh' to stop all services"