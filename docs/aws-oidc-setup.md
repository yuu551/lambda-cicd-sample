# AWS OIDC認証設定手順

GitHub ActionsからAWSリソースにアクセスするための、OIDC（OpenID Connect）認証の設定手順です。

## 1. GitHub OIDC Providerの作成

### AWS CLIでの作成
```bash
aws iam create-open-id-connect-provider \
    --url https://token.actions.githubusercontent.com \
    --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
    --client-id-list sts.amazonaws.com
```

### AWS コンソールでの作成
1. IAM > Identity providers > Add provider
2. Provider type: OpenID Connect
3. Provider URL: `https://token.actions.githubusercontent.com`
4. Audience: `sts.amazonaws.com`

## 2. IAMロールの作成

### 信頼関係ポリシー
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
                    "token.actions.githubusercontent.com:sub": "repo:yuu551/lambda-cicd-sample:ref:refs/heads/main"
                },
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": "repo:yuu551/lambda-cicd-sample:*"
                }
            }
        }
    ]
}
```

### 必要な権限ポリシー
以下のポリシーをロールにアタッチしてください：

1. **CloudFormation操作権限**
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudformation:CreateStack",
                "cloudformation:UpdateStack",
                "cloudformation:DeleteStack",
                "cloudformation:DescribeStacks",
                "cloudformation:DescribeStackResources",
                "cloudformation:DescribeStackEvents",
                "cloudformation:GetTemplate",
                "cloudformation:GetTemplateSummary",
                "cloudformation:ListStacks"
            ],
            "Resource": "*"
        }
    ]
}
```

2. **Lambda操作権限**
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "lambda:CreateFunction",
                "lambda:UpdateFunctionCode",
                "lambda:UpdateFunctionConfiguration",
                "lambda:DeleteFunction",
                "lambda:GetFunction",
                "lambda:ListFunctions",
                "lambda:PublishVersion",
                "lambda:CreateAlias",
                "lambda:UpdateAlias",
                "lambda:DeleteAlias",
                "lambda:AddPermission",
                "lambda:RemovePermission",
                "lambda:PutFunctionEventInvokeConfig",
                "lambda:DeleteFunctionEventInvokeConfig"
            ],
            "Resource": "*"
        }
    ]
}
```

3. **その他必要な権限**
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:CreateBucket",
                "s3:DeleteBucket",
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:ListBucket",
                "s3:GetBucketLocation",
                "s3:GetBucketPolicy",
                "s3:PutBucketPolicy",
                "dynamodb:CreateTable",
                "dynamodb:DeleteTable",
                "dynamodb:DescribeTable",
                "dynamodb:UpdateTable",
                "apigateway:*",
                "iam:CreateRole",
                "iam:DeleteRole",
                "iam:GetRole",
                "iam:PassRole",
                "iam:AttachRolePolicy",
                "iam:DetachRolePolicy",
                "iam:PutRolePolicy",
                "iam:DeleteRolePolicy",
                "logs:CreateLogGroup",
                "logs:DeleteLogGroup",
                "logs:DescribeLogGroups",
                "logs:PutRetentionPolicy"
            ],
            "Resource": "*"
        }
    ]
}
```

## 3. GitHub Repository設定

### Secretsの設定
1. GitHub Repository > Settings > Secrets and variables > Actions
2. 以下のSecretを追加：
   - `AWS_ROLE_ARN`: 作成したIAMロールのARN
     - 例: `arn:aws:iam::123456789012:role/GitHubActionsRole`

### Environmentsの設定
1. GitHub Repository > Settings > Environments
2. 以下の環境を作成：
   - `test`: テスト用環境
   - `development`: 開発用環境
   - `production`: 本番用環境

## 4. 設定確認

以下のコマンドでロールが正しく作成されているか確認できます：

```bash
# OIDC Providerの確認
aws iam list-open-id-connect-providers

# IAMロールの確認
aws iam get-role --role-name GitHubActionsRole

# ロールのポリシー確認
aws iam list-attached-role-policies --role-name GitHubActionsRole
```

## トラブルシューティング

### よくあるエラー
1. **"No OpenIDConnect provider found"**: OIDC Providerが作成されていません
2. **"Not authorized to perform sts:AssumeRoleWithWebIdentity"**: 信頼関係ポリシーが正しくありません
3. **"Access denied"**: IAMロールに必要な権限がありません

### 確認事項
- GitHubリポジトリ名が信頼関係ポリシーと一致しているか
- ブランチ名の条件が正しく設定されているか
- AWS_ROLE_ARNがGitHub Secretsに正しく設定されているか