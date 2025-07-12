#!/bin/bash

# Set AWS configuration for LocalStack
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

echo "Creating DynamoDB tables..."

# ユーザーテーブル
aws dynamodb create-table \
  --endpoint-url http://localhost:4566 \
  --table-name local-users \
  --attribute-definitions AttributeName=id,AttributeType=S \
  --key-schema AttributeName=id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1

# 処理済みデータテーブル
aws dynamodb create-table \
  --endpoint-url http://localhost:4566 \
  --table-name local-processed-data \
  --attribute-definitions AttributeName=id,AttributeType=S \
  --key-schema AttributeName=id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1

# 通知テーブル
aws dynamodb create-table \
  --endpoint-url http://localhost:4566 \
  --table-name local-notifications \
  --attribute-definitions AttributeName=id,AttributeType=S \
  --key-schema AttributeName=id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1

echo "Creating S3 bucket..."
aws s3 mb s3://lambda-cicd-local-data --endpoint-url http://localhost:4566

echo "Creating SNS topic..."
aws sns create-topic --name lambda-cicd-local-notifications --endpoint-url http://localhost:4566

echo "LocalStack initialization completed!"

# テーブルの確認
echo "Created DynamoDB tables:"
aws dynamodb list-tables --endpoint-url http://localhost:4566

echo "Created S3 buckets:"
aws s3 ls --endpoint-url http://localhost:4566

echo "Created SNS topics:"
aws sns list-topics --endpoint-url http://localhost:4566