# LocalStack版 Lambda CI/CD Sample

このディレクトリには、LocalStackを使用したローカル開発環境が含まれています。AWSサービス（DynamoDB、S3、SNS）をローカルでエミュレートし、Lambda関数をコンテナで実行します。

## 特徴

- 🐳 **完全にコンテナ化** - Dockerのみで動作
- 🏠 **ローカル完結** - AWS アカウント不要
- 🔄 **統合テスト** - 複数のLambda関数とAWSサービスの統合テスト
- 🚀 **高速フィードバック** - ローカルで即座にテスト

## 前提条件

- Docker & Docker Compose
- jq (テストスクリプト用)
- awscli-local (`pip install awscli-local`)

## クイックスタート

```bash
# LocalStack環境を起動
./scripts/start.sh

# テストを実行
./scripts/test.sh

# 環境を停止
./scripts/stop.sh
```

## アーキテクチャ

```
┌─────────────────┐    ┌─────────────────┐
│   LocalStack    │    │ Lambda Function │
│                 │    │   Containers    │
│ ┌─────────────┐ │    │                 │
│ │ DynamoDB    │ │◄───┤ user-management │
│ └─────────────┘ │    │ data-processor  │
│ ┌─────────────┐ │    │ notification    │
│ │ S3          │ │◄───┤ health-check    │
│ └─────────────┘ │    │                 │
│ ┌─────────────┐ │    │                 │
│ │ SNS         │ │◄───┤                 │
│ └─────────────┘ │    │                 │
└─────────────────┘    └─────────────────┘
```

## エンドポイント

### Lambda関数

各Lambda関数は個別のポートで公開されます：

- **User Management**: http://localhost:9001/2015-03-31/functions/function/invocations
- **Data Processor**: http://localhost:9002/2015-03-31/functions/function/invocations  
- **Notification**: http://localhost:9003/2015-03-31/functions/function/invocations
- **Health Check**: http://localhost:9004/2015-03-31/functions/function/invocations

### LocalStack

- **LocalStack Dashboard**: http://localhost:4566
- **AWS CLI エンドポイント**: http://localhost:4566

## 使用方法

### 環境の起動

```bash
cd localstack-version
./scripts/start.sh
```

起動後、以下のリソースが自動作成されます：
- DynamoDBテーブル: `local-users`, `local-processed-data`, `local-notifications`
- S3バケット: `lambda-cicd-local-data`
- SNSトピック: `lambda-cicd-local-notifications`

### Lambda関数の呼び出し

```bash
# ヘルスチェック
curl -X POST http://localhost:9004/2015-03-31/functions/function/invocations \
  -H "Content-Type: application/json" \
  -d '{
    "httpMethod": "GET",
    "resource": "/health"
  }'

# ユーザー作成
curl -X POST http://localhost:9001/2015-03-31/functions/function/invocations \
  -H "Content-Type: application/json" \
  -d '{
    "httpMethod": "POST",
    "resource": "/users",
    "body": "{\"name\": \"Test User\", \"email\": \"test@example.com\"}"
  }'
```

### LocalStackリソースの確認

```bash
# DynamoDBテーブル一覧
awslocal dynamodb list-tables --endpoint-url http://localhost:4566

# S3バケット一覧
awslocal s3 ls --endpoint-url http://localhost:4566

# SNSトピック一覧
awslocal sns list-topics --endpoint-url http://localhost:4566
```

## ログの確認

```bash
# 全サービスのログ
docker-compose logs -f

# 特定のサービスのログ
docker-compose logs -f user-management
docker-compose logs -f localstack
```

## トラブルシューティング

### LocalStackが起動しない

```bash
# コンテナの状態を確認
docker-compose ps

# LocalStackのログを確認
docker-compose logs localstack
```

### Lambda関数が応答しない

```bash
# 関数のログを確認
docker-compose logs user-management

# コンテナの状態を確認
docker ps
```

### 完全リセット

```bash
./scripts/stop.sh
docker system prune -f
./scripts/start.sh
```

## メインプロジェクトとの違い

| 項目 | メインプロジェクト | LocalStack版 |
|------|-------------------|--------------|
| 実行環境 | SAM Local | Docker Container |
| AWSサービス | モック (moto) | LocalStack |
| 統合テスト | ❌ | ✅ |
| 起動時間 | 高速 | 中程度 |
| リソース使用量 | 軽量 | 重い |
| デバッグ | 容易 | 中程度 |

## 開発ワークフロー

1. `./scripts/start.sh` でローカル環境起動
2. コードを編集（ホットリロード対応）
3. `./scripts/test.sh` でテスト実行
4. 統合テストでE2Eの動作確認
5. `./scripts/stop.sh` で環境停止