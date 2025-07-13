# AWS SAM 総合ガイド

このドキュメントでは、AWS SAM（Serverless Application Model）について包括的に解説します。

## 目次

1. [SAM概要](#sam概要)
2. [プロジェクト構成解説](#プロジェクト構成解説)
3. [開発ワークフロー](#開発ワークフロー)
4. [SAMコマンド集](#samコマンド集)
5. [SAM Local開発](#sam-local開発)
6. [デプロイメント](#デプロイメント)
7. [トラブルシューティング](#トラブルシューティング)
8. [ベストプラクティス](#ベストプラクティス)

## SAM概要

### SAMとは

AWS SAM（Serverless Application Model）は、サーバーレスアプリケーションを構築・デプロイするためのオープンソースのフレームワークです。

### SAMの利点

- **簡潔な構文**: CloudFormationよりもシンプルな記述
- **ローカル開発**: SAM Localによる本格的なローカルテスト環境
- **自動リソース作成**: Lambda、API Gateway、DynamoDBなどのリソースを自動生成
- **CI/CD統合**: GitHub ActionsやCodePipelineとの連携が容易

### SAMで管理できるAWSサービス

SAMでは以下のAWSサービスを統合的に管理できます：

- **Lambda関数**: サーバーレス関数
- **API Gateway**: RESTful APIエンドポイント
- **DynamoDB**: NoSQLデータベース
- **S3**: オブジェクトストレージ
- **SNS**: メッセージング・通知サービス
- **SQS**: メッセージキューサービス
- **EventBridge**: イベントルーティング
- **Step Functions**: ワークフローオーケストレーション
- **Lambda Layer**: 共通ライブラリ・依存関係

## SAMテンプレート解説

### template.yaml の基本構造

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Transform: AWS::Serverless-2016-10-31
Description: Sample SAM Application
```

**必須要素**:
- `AWSTemplateFormatVersion`: CloudFormationテンプレートのバージョン
- `Transform`: SAM変換を有効化する宣言
- `Description`: アプリケーションの説明（オプション）

#### グローバル設定

```yaml
Globals:
  Function:
    Timeout: 30
    MemorySize: 512
    Runtime: python3.9
    Environment:
      Variables:
        ENVIRONMENT: !Ref Environment
        LOG_LEVEL: !Ref LogLevel
```

すべてのLambda関数に共通する設定を定義します。

#### パラメータ

```yaml
Parameters:
  Environment:
    Type: String
    Default: dev
    AllowedValues: [dev, staging, prod]
  LogLevel:
    Type: String  
    Default: INFO
    AllowedValues: [DEBUG, INFO, WARNING, ERROR]
```

環境別の設定を可能にする動的パラメータです。

#### Lambda Layer（共通レイヤー）

```yaml
CommonLayer:
  Type: AWS::Lambda::LayerVersion
  Properties:
    LayerName: !Sub ${AWS::StackName}-common-layer
    Content: ./src/layers/common/
    CompatibleRuntimes:
      - python3.9
```

**Lambda Layerの特徴**:
- **共有コード**: 複数のLambda関数で共通して使用するコードやライブラリ
- **パッケージサイズ削減**: 関数本体から依存関係を分離
- **バージョン管理**: レイヤーのバージョン管理が可能
- **自動パス追加**: AWS Lambdaが自動的に`/opt/python`にパスを追加（Python用）

#### Lambda関数の定義例

```yaml
MyFunction:
  Type: AWS::Serverless::Function
  Properties:
    FunctionName: !Sub ${AWS::StackName}-my-function
    CodeUri: ./src/my_function/
    Handler: app.lambda_handler
    Runtime: python3.9
    Layers:
      - !Ref CommonLayer
    Policies:
      - DynamoDBCrudPolicy:
          TableName: !Ref MyTable
    Events:
      ApiEvent:
        Type: Api
        Properties:
          Path: /api/resource
          Method: post
```

#### DynamoDBテーブル

```yaml
MyTable:
  Type: AWS::DynamoDB::Table
  Properties:
    TableName: !Sub ${Environment}-my-table
    BillingMode: PAY_PER_REQUEST
    AttributeDefinitions:
      - AttributeName: id
        AttributeType: S
    KeySchema:
      - AttributeName: id
        KeyType: HASH
```

**DynamoDBの設定項目**:
- `BillingMode`: 課金モード（PAY_PER_REQUEST または PROVISIONED）
- `AttributeDefinitions`: 属性定義
- `KeySchema`: プライマリキーの定義
- `GlobalSecondaryIndexes`: グローバルセカンダリインデックス（オプション）

## 開発ワークフロー

### 1. 開発環境セットアップ

```bash
# Python仮想環境を作成（推奨）
python3 -m venv venv
source venv/bin/activate  # macOS/Linux
# venv\Scripts\activate   # Windows

# 基本的な依存関係をインストール
pip install --upgrade pip
pip install boto3 pytest

# プロジェクト固有の依存関係（requirements.txtがある場合）
pip install -r requirements.txt
```

### 2. コード開発

典型的なSAMプロジェクトの構造：

```
my-sam-app/
├── template.yaml          # SAMテンプレート
├── src/
│   ├── function1/         # Lambda関数1
│   │   └── app.py
│   ├── function2/         # Lambda関数2
│   │   └── app.py
│   └── layers/            # 共通レイヤー
│       └── common/
│           └── python/
└── tests/                 # テストコード
    └── unit/
```

### 3. ローカルテスト

```bash
# SAMビルド
sam build

# 単体テスト
python -m pytest tests/ -v

# Lambda関数の個別テスト
sam local invoke MyFunction --event events/test-event.json
```

### 4. 統合テスト

```bash
# ローカルAPIサーバー起動
sam local start-api --port 3000

# API動作確認
curl -X POST http://localhost:3000/api/resource \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

### 5. デプロイ

```bash
# 初回デプロイ（ガイド付き）
sam deploy --guided

# 設定済み環境へのデプロイ
sam deploy

# パラメータ指定デプロイ
sam deploy --parameter-overrides Environment=dev \
  --capabilities CAPABILITY_IAM \
  --region us-east-1
```

## SAMコマンド集

### 基本コマンド

```bash
# プロジェクト初期化（新規プロジェクト用）
sam init

# アプリケーションをビルド
sam build

# テンプレートの構文チェック
sam validate

# より厳密な検証
sam validate --lint
```

### ローカル開発コマンド

```bash
# Lambda関数を個別実行
sam local invoke <FunctionName> --event <event-file>

# APIサーバーを起動
sam local start-api [--port 3000]

# Lambda関数をAPIとして起動
sam local start-lambda

# DynamoDB Localを起動（別途インストール必要）
sam local start-dynamodb
```

### デプロイコマンド

```bash
# ガイド付きデプロイ（初回推奨）
sam deploy --guided

# 設定済み環境へのデプロイ
sam deploy

# パラメータ指定デプロイ
sam deploy --parameter-overrides Environment=prod LogLevel=INFO

# 特定のリージョンへのデプロイ
sam deploy --region ap-northeast-1

# S3バケットを自動作成
sam deploy --resolve-s3
```

### デバッグ・監視コマンド

```bash
# ログの表示
sam logs -n <FunctionName> --stack-name <stack-name>

# リアルタイムログ監視
sam logs -n <FunctionName> --stack-name <stack-name> --tail

# CloudWatchログをフィルタ
sam logs -n <FunctionName> --filter "ERROR"

# 同期デプロイ（ホットリロード）
sam sync --stack-name <stack-name> --watch
```

## SAM Local開発

### Docker要件

SAM Localを使用するには、Dockerが必要です：

```bash
# Docker動作確認
docker --version
docker info
```

### Lambda関数のテスト

#### イベントファイルの作成

```json
// events/test-event.json
{
  "httpMethod": "POST",
  "resource": "/api/resource",
  "body": "{\"key\": \"value\", \"data\": \"test\"}"
}
```

#### 関数の実行

```bash
# 基本的な関数テスト
sam local invoke MyFunction --event events/test-event.json

# S3イベントのテスト
sam local invoke S3ProcessorFunction --event events/s3-event.json

# SQSイベントのテスト  
sam local invoke SQSProcessorFunction --event events/sqs-event.json
```

### API Gatewayのテスト

```bash
# APIサーバー起動
sam local start-api --port 3000

# エンドポイントテスト例
curl -X GET http://localhost:3000/health
curl -X POST http://localhost:3000/api/resource \
  -H "Content-Type: application/json" \
  -d '{"data": "test"}'
curl -X GET http://localhost:3000/api/resources
```

### 環境変数の設定

```bash
# 環境変数ファイルを作成
echo 'MyFunction:
  ENVIRONMENT: "local"
  LOG_LEVEL: "DEBUG"
  DB_TABLE_NAME: "test-table"' > env.json

# 環境変数を使用してテスト
sam local invoke MyFunction \
  --event events/test-event.json \
  --env-vars env.json
```

## デプロイメント

### 手動デプロイ

#### 開発環境

```bash
sam deploy \
  --stack-name my-app-dev \
  --parameter-overrides Environment=dev \
  --capabilities CAPABILITY_IAM \
  --region us-east-1 \
  --resolve-s3
```

#### 本番環境

```bash
sam deploy \
  --stack-name my-app-prod \
  --parameter-overrides Environment=prod \
  --capabilities CAPABILITY_IAM \
  --region us-east-1 \
  --resolve-s3
```

### CI/CDによる自動デプロイ

GitHub Actionsの例：

```yaml
# .github/workflows/deploy.yml（例）
name: Deploy SAM Application
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: aws-actions/setup-sam@v2
      - name: SAM Build
        run: sam build
      - name: SAM Deploy
        run: |
          sam deploy \
            --stack-name my-app-prod \
            --capabilities CAPABILITY_IAM \
            --region us-east-1 \
            --resolve-s3 \
            --no-confirm-changeset
```

### デプロイ戦略

1. **ブランチベースデプロイ**
   - `develop` → 開発環境
   - `main` → 本番環境

2. **環境別設定**
   - パラメータによる環境の切り替え
   - リソース名の環境別プレフィックス

3. **Blue/Greenデプロイ**
   - AWS CodeDeployとの統合
   - トラフィックの段階的切り替え

4. **ロールバック**
   ```bash
   # CloudFormationスタックのロールバック
   aws cloudformation cancel-update-stack --stack-name my-app-prod
   
   # 前のバージョンへの復元
   aws cloudformation update-stack --stack-name my-app-prod \
     --use-previous-template
   ```

## トラブルシューティング

### よくあるエラーと解決方法

#### 1. Docker関連のエラー

**エラー**: `Error: Running AWS SAM projects locally requires Docker.`

**解決方法**:
```bash
# Docker Desktopの起動確認
docker ps

# Dockerサービスの再起動
# macOS: Docker Desktop → Restart
# Linux: sudo systemctl restart docker
```

#### 2. レイヤーのインポートエラー

**エラー**: `ModuleNotFoundError: No module named 'my_module'`

**解決方法**:
- Lambda Layerの構造を確認
- Pythonの場合: `src/layers/my_layer/python/`
- Node.jsの場合: `src/layers/my_layer/nodejs/node_modules/`
- SAMは自動的に適切なパスに追加（手動のパス操作は不要）

#### 3. ビルドエラー

**エラー**: `Error: PythonPipBuilder:ResolveDependencies`

**解決方法**:
```bash
# requirements.txtの確認
cat requirements.txt

# 依存関係の手動インストールで確認
pip install -r requirements.txt

# Dockerコンテナでのビルド
sam build --use-container
```

#### 4. デプロイエラー

**エラー**: `S3 bucket does not exist`

**解決方法**:
```bash
# S3バケットの自動作成
sam deploy --resolve-s3

# または手動でバケット作成
aws s3 mb s3://your-deployment-bucket
sam deploy --s3-bucket your-deployment-bucket
```

#### 5. 権限エラー

**エラー**: `User is not authorized to perform: cloudformation:CreateStack`

**解決方法**:
```bash
# 必要な権限の確認
aws iam get-user
aws sts get-caller-identity

# --capabilities の指定
sam deploy --capabilities CAPABILITY_IAM
```

### ログの確認方法

```bash
# CloudWatchログの表示
sam logs -n MyFunction --stack-name my-app-dev

# リアルタイムログ監視
sam logs -n MyFunction --stack-name my-app-dev --tail

# エラーのみフィルタ
sam logs -n MyFunction --filter "ERROR"
```

## ベストプラクティス

### 1. プロジェクト構成

推奨されるディレクトリ構造：

```
my-sam-app/
├── template.yaml              # SAMテンプレート
├── src/                       # ソースコード
│   ├── function1/             # 機能別ディレクトリ
│   ├── function2/
│   ├── shared/                # 共有コード
│   └── layers/                # Lambda Layers
├── tests/                     # テストコード
├── events/                    # テスト用イベント
├── docs/                      # ドキュメント
└── scripts/                   # 運用スクリプト
```

### 2. 共通レイヤーの活用

- 複数のLambda関数で使用するコードはレイヤーに集約
- 言語別の適切なディレクトリ構造を使用
- バージョン管理でレイヤーの更新を追跡
- レイヤーサイズの制限（250MB解凍時）に注意

### 3. 環境管理

- パラメータを使用した環境の切り替え
- リソース名に環境プレフィックス: `{Environment}-resource-name`
- 環境別の設定値管理
- SSM Parameter StoreやSecrets Managerの活用

### 4. テスト戦略

```bash
# 3層のテスト戦略
1. 単体テスト: Jest/Pytest + モック
2. SAM Local: sam local invoke
3. 統合テスト: sam local start-api + エンドツーエンド
```

### 5. セキュリティ

- IAMポリシーは最小権限の原則
- 機密情報はParameter StoreやSecrets Manager
- API Gatewayでの認証・認可

### 6. 監視とロギング

- CloudWatchでのメトリクス監視
- 構造化ログの活用
- X-Rayでの分散トレーシング（必要に応じて）

### 7. CI/CD

- ブランチ戦略の確立
- 自動テストの実行
- 段階的デプロイ（dev → staging → prod）

## 参考リンク

- [AWS SAM公式ドキュメント](https://docs.aws.amazon.com/serverless-application-model/)
- [SAM CLI コマンドリファレンス](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-command-reference.html)
- [SAM テンプレート仕様](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/sam-specification.html)
- [AWS Lambda Layers](https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html)
- [SAM Policy Templates](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-policy-templates.html)