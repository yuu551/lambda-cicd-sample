#!/bin/bash

echo "🧪 Testing LocalStack Lambda functions..."

# 環境変数を設定
export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

# ヘルスチェック関数のテスト
echo "Testing Health Check function..."
curl -X POST http://localhost:9004/2015-03-31/functions/function/invocations \
  -H "Content-Type: application/json" \
  -d '{
    "httpMethod": "GET",
    "resource": "/health",
    "path": "/health"
  }' | jq .

echo ""

# ユーザー作成のテスト
echo "Testing User Management - Create User..."
USER_RESPONSE=$(curl -s -X POST http://localhost:9001/2015-03-31/functions/function/invocations \
  -H "Content-Type: application/json" \
  -d '{
    "httpMethod": "POST",
    "resource": "/users",
    "body": "{\"name\": \"Test User\", \"email\": \"test@example.com\"}"
  }')

echo $USER_RESPONSE | jq .

# ユーザーIDを抽出
USER_ID=$(echo $USER_RESPONSE | jq -r '.body' | jq -r '.user.id' 2>/dev/null)

if [ "$USER_ID" != "null" ] && [ -n "$USER_ID" ]; then
    echo ""
    echo "Testing User Management - Get User by ID: $USER_ID"
    curl -X POST http://localhost:9001/2015-03-31/functions/function/invocations \
      -H "Content-Type: application/json" \
      -d "{
        \"httpMethod\": \"GET\",
        \"resource\": \"/users/{id}\",
        \"pathParameters\": {\"id\": \"$USER_ID\"}
      }" | jq .
fi

echo ""
echo "Testing User Management - List Users..."
curl -X POST http://localhost:9001/2015-03-31/functions/function/invocations \
  -H "Content-Type: application/json" \
  -d '{
    "httpMethod": "GET",
    "resource": "/users"
  }' | jq .

echo ""
echo "Testing complete! Check the responses above for any errors."

# LocalStackの状態確認
echo ""
echo "LocalStack DynamoDB Tables:"
awslocal dynamodb list-tables --endpoint-url http://localhost:4566

echo ""
echo "LocalStack S3 Buckets:"
awslocal s3 ls --endpoint-url http://localhost:4566