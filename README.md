# Lambda CI/CD Sample

複数のLambda関数を含むCI/CD環境のサンプルプロジェクトです。

## 📁 プロジェクト構成

```
lambda-cicd-sample/
├── template.yaml              # SAMテンプレート
├── src/
│   ├── handlers/             # Lambda関数のハンドラー
│   │   ├── user_management.py
│   │   ├── data_processor.py
│   │   └── notification.py
│   ├── layers/               # 共通レイヤー
│   │   └── common/
│   │       ├── utils.py
│   │       ├── db.py
│   │       ├── validators.py
│   │       └── requirements.txt
│   └── tests/                # テストコード
│       └── test_user_management.py
├── events/                   # テスト用イベントファイル
│   ├── user-create.json
│   ├── user-get.json
│   ├── s3-event.json
│   └── notification-send.json
├── .github/workflows/        # GitHub Actions
│   └── cicd.yml
└── README.md
```

## 🚀 機能

### Lambda関数
1. **User Management** - ユーザー管理API
   - ユーザー作成 (POST /users)
   - ユーザー取得 (GET /users/{id})
   - ユーザー一覧 (GET /users)

2. **Data Processor** - データ処理
   - API経由でのデータ処理 (POST /process)
   - S3オブジェクト作成時の自動処理

3. **Notification** - 通知サービス
   - Email/SMS通知 (POST /notify)
   - SNSトピック経由の通知処理

### 共通レイヤー
- **utils.py** - 共通ユーティリティ関数
- **db.py** - DynamoDB操作クラス
- **validators.py** - バリデーション関数

## 🛠️ 前提条件

- [AWS CLI](https://aws.amazon.com/cli/) がインストールされ、設定されている
- [AWS SAM CLI](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html) がインストールされている
- [Docker](https://www.docker.com/) がインストールされている
- Python 3.9 以上

## 🔧 ローカル開発環境の設定

### 1. 仮想環境の作成と依存関係のインストール

#### macOS/Linux
```bash
# Python仮想環境を作成
python3 -m venv venv

# 仮想環境を有効化
source venv/bin/activate

# テストに必要なパッケージをインストール
pip install --upgrade pip
pip install pytest "moto[dynamodb]" boto3
pip install -r src/layers/common/requirements.txt
```

#### Windows (Command Prompt)
```cmd
# Python仮想環境を作成
python -m venv venv

# 仮想環境を有効化
venv\Scripts\activate

# テストに必要なパッケージをインストール
pip install --upgrade pip
pip install pytest "moto[dynamodb]" boto3
pip install -r src/layers/common/requirements.txt
```

#### Windows (PowerShell)
```powershell
# Python仮想環境を作成
python -m venv venv

# 仮想環境を有効化
venv\Scripts\Activate.ps1
# または実行ポリシーエラーの場合
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
venv\Scripts\Activate.ps1

# テストに必要なパッケージをインストール
pip install --upgrade pip
pip install pytest 'moto[dynamodb]' boto3
pip install -r src/layers/common/requirements.txt
```

### 2. SAM ビルド

```bash
sam build
```

### 3. ローカルテスト

#### 単体テスト実行

**macOS/Linux**
```bash
# 仮想環境が有効であることを確認
source venv/bin/activate

# テストを実行
cd src/tests
python -m pytest test_user_management.py -v

# または従来のunittest方式
python test_user_management.py
```

**Windows**
```cmd
# 仮想環境が有効であることを確認
venv\Scripts\activate

# テストを実行
cd src\tests
python -m pytest test_user_management.py -v

# または従来のunittest方式
python test_user_management.py
```

**注意**: テストではmoto 5.x以降を使用しているため、DynamoDBのモック機能が自動で有効になります。

#### SAM Local による関数テスト
```bash
# SAMビルドが必要（初回のみ）
sam build

# ユーザー作成のテスト
sam local invoke UserManagementFunction --event events/user-create.json

# データ処理のテスト
sam local invoke DataProcessorFunction --event events/s3-event.json

# 通知のテスト
sam local invoke NotificationFunction --event events/notification-send.json
```

**注意**: SAM Localの実行にはDockerが必要です。

#### ローカルAPI起動
```bash
# APIサーバーをローカルで起動
sam local start-api --port 3000

# 別のターミナルでテスト
curl -X POST http://localhost:3000/users \\
  -H "Content-Type: application/json" \\
  -d '{"name": "Test User", "email": "test@example.com"}'

curl http://localhost:3000/users
```

## 🐙 GitHubリポジトリ作成とCI/CD設定

### 1. Gitリポジトリの初期化

```bash
# プロジェクトルートで実行
git init
git add .
git commit -m "Initial commit: Lambda CI/CD sample"
```

### 2. GitHubリポジトリの作成

1. [GitHub](https://github.com)にログイン
2. 「New repository」をクリック
3. リポジトリ設定:
   - **Repository name**: `lambda-cicd-sample`
   - **Owner**: `yuu551`
   - **Visibility**: Public または Private
   - **Initialize**: チェックを入れない（既にコードがあるため）

### 3. リモートリポジトリとの連携

```bash
# GitHubで作成したリポジトリURLを設定
git remote add origin https://github.com/yuu551/lambda-cicd-sample.git
git branch -M main
git push -u origin main
```

### 4. GitHub Actions環境設定

CI/CDパイプラインを動作させるために以下を設定：

#### a) Repository Secrets
Settings → Secrets and variables → Actions で以下を追加：
- `AWS_ROLE_ARN`: デプロイ用のIAMロールARN

#### b) Environments
Settings → Environments で以下を作成：
- `test`: テスト環境用
- `development`: 開発環境用  
- `production`: 本番環境用

### 5. CI/CDワークフロー体験

```bash
# 開発ブランチでの作業
git checkout -b develop
git push -u origin develop
# → GitHub Actionsで開発環境への自動デプロイが実行

# Pull Request作成
# → 自動テストが実行される

# mainブランチへのマージ
# → 本番環境への自動デプロイが実行
```

## 🚀 デプロイ方法

### 手動デプロイ

#### 開発環境
```bash
sam deploy \\
  --stack-name lambda-cicd-dev \\
  --parameter-overrides Environment=dev LogLevel=DEBUG \\
  --capabilities CAPABILITY_IAM \\
  --region ap-northeast-1 \\
  --resolve-s3
```

#### 本番環境
```bash
sam deploy \\
  --stack-name lambda-cicd-prod \\
  --parameter-overrides Environment=prod LogLevel=INFO \\
  --capabilities CAPABILITY_IAM \\
  --region ap-northeast-1 \\
  --resolve-s3
```

### GitHub Actions による自動デプロイ

このプロジェクトは GitHub Actions による CI/CD パイプラインを含んでいます。

#### 必要な設定
1. GitHub リポジトリで以下のEnvironmentを作成:
   - `test`
   - `development`
   - `production`

2. 各環境に以下のSecretsを設定:
   - `AWS_ROLE_ARN`: デプロイ用のIAMロールARN

#### デプロイフロー
- `develop` ブランチ → 開発環境へ自動デプロイ
- `main` ブランチ → 本番環境へ自動デプロイ
- プルリクエスト → テスト実行 + SAM Local テスト

## 📊 モニタリング

デプロイ後は以下のAWSサービスでモニタリングできます:

- **CloudWatch Logs**: Lambda関数のログ
- **CloudWatch Metrics**: パフォーマンス指標
- **X-Ray**: 分散トレーシング（有効化済み）

## 🧪 テスト

### ユニットテスト

**macOS/Linux**
```bash
# 仮想環境を有効化
source venv/bin/activate

# テストを実行
cd src/tests
python -m pytest test_user_management.py -v

# カバレッジ付きテスト（オプション）
pip install pytest-cov
python -m pytest test_user_management.py --cov=../handlers --cov-report=html
```

**Windows**
```cmd
# 仮想環境を有効化
venv\Scripts\activate

# テストを実行
cd src\tests
python -m pytest test_user_management.py -v

# カバレッジ付きテスト（オプション）
pip install pytest-cov
python -m pytest test_user_management.py --cov=../handlers --cov-report=html
```

### 統合テスト
```bash
# デプロイ後のAPI URLを取得
API_URL=$(aws cloudformation describe-stacks \\
  --stack-name lambda-cicd-dev \\
  --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayUrl`].OutputValue' \\
  --output text)

# API テスト
curl -X POST $API_URL/users \\
  -H "Content-Type: application/json" \\
  -d '{"name": "Test User", "email": "test@example.com"}'
```

## 🔧 トラブルシューティング

### よくある問題

1. **Lambda Layer のビルドエラー**
   ```bash
   # レイヤーディレクトリの権限を確認
   ls -la src/layers/common/
   
   # requirements.txt が存在することを確認
   cat src/layers/common/requirements.txt
   ```

2. **DynamoDB テーブルが見つからない**
   - 環境変数 `ENVIRONMENT` が正しく設定されているか確認
   - テーブル名が `{ENVIRONMENT}-{table_name}` の形式になっているか確認

3. **API Gateway 403エラー**
   - IAMロールの権限を確認
   - CORSの設定を確認

### ログ確認
```bash
# 特定の関数のログを確認
aws logs tail /aws/lambda/lambda-cicd-dev-user-management --follow

# すべてのログを確認
sam logs --stack-name lambda-cicd-dev --tail
```

## 🛡️ セキュリティ

- Lambda関数は最小権限の原則に従ってIAMロールを設定
- 機密情報は環境変数として管理
- VPCの設定は必要に応じて実装
- WAFの設定は本番環境で推奨

## 📝 ライセンス

このプロジェクトはMIT License の下で公開されています。

## 🤝 貢献

1. このリポジトリをフォーク
2. 新しいブランチを作成 (`git checkout -b feature/new-feature`)
3. 変更をコミット (`git commit -am 'Add new feature'`)
4. ブランチにプッシュ (`git push origin feature/new-feature`)
5. プルリクエストを作成

## 📚 参考資料

- [AWS SAM デベロッパーガイド](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/)
- [GitHub Actions でのSAMデプロイ](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/deploying-using-github.html)
- [AWS Lambda 開発者ガイド](https://docs.aws.amazon.com/lambda/latest/dg/)