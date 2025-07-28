# 本番環境エラー修正まとめ

## 🐛 発生した問題

**エラー内容**: `AxiosError: Network Error` および `ERR_NAME_NOT_RESOLVED`
- フロントエンド（https://jimotoko.com）からAPIサーバー（https://api.jimotoko.com）への接続が失敗
- 原因：`api.jimotoko.com` のDNS設定が存在しない

## 🔍 根本原因

1. **ALB（Application Load Balancer）が未設定**
   - ECSサービスはデプロイされているが、外部からアクセスするためのロードバランサーが無い
   - ECSタスクは一時的なパブリックIPを持つが、安定したエンドポイントが無い

2. **DNS設定が不完全**
   - `api.jimotoko.com` のRoute 53設定が存在しない
   - フロントエンドが存在しないドメインに接続しようとしている

## 🚨 緊急対応（実施済み）

### 1. ECSタスクの直接IP接続
- 現在のECSタスクのパブリックIPを特定: `43.207.110.17`
- `ALLOWED_HOSTS` にIPアドレスを追加
- フロントエンドの `NEXT_PUBLIC_API_URL` を直接IPに変更

### 2. GitHub Actions自動デプロイ設定
- バックエンド・フロントエンド両方のワークフローを修正
- `git push` で自動デプロイが実行される

### 3. Application Load Balancer作成（部分的）
- ALBは作成済み: `jimotoko-backend-alb-712943240.ap-northeast-1.elb.amazonaws.com`
- Target Group作成済み: `jimotoko-backend-tg-new`
- Listener設定済み（HTTP:80）

## 📋 現在の状況

### ✅ 完了したタスク
- [x] ECSタスクのパブリックIP特定
- [x] ALB作成
- [x] Target Group作成
- [x] Listener設定
- [x] Django ALLOWED_HOSTS設定更新
- [x] フロントエンド環境変数更新
- [x] GitHub Actions自動デプロイ設定

### ⏳ デプロイ中
- [ ] バックエンドの新しいタスク定義デプロイ
- [ ] フロントエンドの新しいビルドデプロイ

### 🔄 残りのタスク
- [ ] ECSサービスをTarget Groupに登録
- [ ] Route 53でapi.jimotoko.comのDNS設定
- [ ] SSL証明書設定（ACM）
- [ ] HTTPSリダイレクト設定

## 🛠️ 本格修正の手順

### 1. ECSサービスとALBの統合
```bash
# ECSサービスをTarget Groupに登録
aws ecs update-service \
  --cluster jimotoko-cluster \
  --service jimotoko-backend-service \
  --load-balancers targetGroupArn=arn:aws:elasticloadbalancing:ap-northeast-1:162174360270:targetgroup/jimotoko-backend-tg-new/10d998d83306e7b9,containerName=jimotoko-backend,containerPort=8000
```

### 2. Route 53 DNS設定
```bash
# api.jimotoko.com のAレコード作成
aws route53 change-resource-record-sets \
  --hosted-zone-id Z123456789 \
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "api.jimotoko.com",
        "Type": "A",
        "AliasTarget": {
          "DNSName": "jimotoko-backend-alb-712943240.ap-northeast-1.elb.amazonaws.com",
          "EvaluateTargetHealth": false,
          "HostedZoneId": "Z2YN17T5R711GT"
        }
      }
    }]
  }'
```

### 3. SSL証明書とHTTPS設定
```bash
# ACMでSSL証明書取得
aws acm request-certificate \
  --domain-name api.jimotoko.com \
  --validation-method DNS

# HTTPS Listener追加
aws elbv2 create-listener \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTPS \
  --port 443 \
  --ssl-policy ELBSecurityPolicy-TLS-1-2-2017-01 \
  --certificates CertificateArn=$CERT_ARN \
  --default-actions Type=forward,TargetGroupArn=$TG_ARN
```

### 4. セキュリティ設定最終化
- ALBセキュリティグループでHTTPS(443)を許可
- ECSタスクセキュリティグループをALBからのトラフィックのみに制限
- パブリックIPアクセスを無効化

## 🔄 デプロイ確認手順

### 現在（緊急対応）
1. ブラウザで https://jimotoko.com にアクセス
2. サインアップを試行
3. ネットワークタブでAPI接続確認

### 修正後（本格対応）
1. `nslookup api.jimotoko.com` でDNS解決確認
2. `curl https://api.jimotoko.com/api/health/` でAPI動作確認
3. フロントエンドでサインアップ・ログイン動作確認

## 📞 連絡事項

緊急対応により一時的に動作するはずですが、以下の制限があります：
- ECSタスクが再起動すると新しいIPアドレスが割り当てられる
- HTTPSではなくHTTPでの通信となる
- パブリックIPへの直接アクセスのため、セキュリティ上推奨されない

本格修正（ALB + DNS）の完了が推奨されます。