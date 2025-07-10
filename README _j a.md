# Yoobee College Multi-Cloud Infrastructure Migration Project (AWS + Azure Hybrid Cloud)

## 概要

このプロジェクトは、Yoobee College のインフラストラクチャを AWS と Azure を組み合わせたハイブリッドクラウド環境へ移行するための Terraform 設定です。AWS 上に WordPress アプリケーションと関連するデータベース (RDS)、ロードバランサー、S3 バケット、Lambda 関数、CloudWatch アラームなどをデプロイし、Azure 上に DNS ゾーンと AWS のロードバランサーを指す CNAME レコードを設定します。

主な目的は、スケーラブルで可用性の高い WordPress 環境を構築し、ログ管理、データベースバックアップ、セキュリティ監視などの運用要件を満たすことです。

## アーキテクチャ概要

このプロジェクトによってデプロイされる主要なコンポーネントは以下の通りです。

### AWS (Amazon Web Services)

* **VPC (Virtual Private Cloud)**: WordPress アプリケーション用の隔離されたネットワーク環境。
* **EC2 (Elastic Compute Cloud)**: WordPress アプリケーションを実行するウェブサーバー。Auto Scaling Group によってスケーラビリティと可用性が確保されます。
* **RDS (Relational Database Service)**: WordPress のデータを格納する MySQL データベース。マルチ AZ 配置により高可用性を実現します。
* **ALB (Application Load Balancer)**: EC2 インスタンスへのトラフィックを分散し、HTTPS を終端します。
* **S3 (Simple Storage Service)**: ロードバランサーのアクセスログ、CloudWatch のログエクスポート、RDS のバックアップなどを保存します。
* **Lambda (Serverless Compute)**:
    * RDS のスナップショットバックアップを自動化する関数。
    * CloudWatch Logs を S3 にエクスポートする関数。
* **IAM (Identity and Access Management)**: 各サービスが連携するために必要なロールとポリシー。
* **CloudWatch (Monitoring and Observability)**:
    * EC2、RDS、Auto Scaling Group のメトリクス監視とアラーム設定。
    * EC2 インスタンスの状態変化通知。
* **EventBridge (Serverless Event Bus)**: 定期的なバックアップやログエクスポートをトリガーするルール。
* **SNS (Simple Notification Service)**: アラーム通知の配信。

### Azure (Microsoft Azure)

* **Resource Group**: Azure リソースを論理的にグループ化します。
* **DNS Zone**: カスタムドメイン (`loadbalancers-yoobeecolleges.xyz`) の DNS レコードを管理します。
* **CNAME Record**: `www.loadbalancers-yoobeecolleges.xyz` から AWS の ALB へトラフィックをリダイレクトします。

## 前提条件

このプロジェクトをデプロイするには、以下のものが必要です。

* **Terraform CLI**: バージョン 1.0 以上。
* **AWS CLI**: AWS リソースをプロビジョニングするための認証情報が設定されていること。
    * `~/.aws/credentials` に適切な認証情報が設定されているか、環境変数が設定されている必要があります。
* **Azure CLI**: Azure リソースをプロビジョニングするための認証情報が設定されていること。
    * `az login` でログイン済みであること。
* **SSH キーペア**: AWS EC2 インスタンスに接続するための SSH キーペアが `~/.ssh/id_rsa.pub` に存在すること。
    * もし異なるパスを使用する場合は、`asg.tf` の `aws_key_pair.wordpress` リソースの `public_key` パスを更新してください。
* **ドメイン名**: `loadbalancers-yoobeecolleges.xyz` (または `variables.tf` で設定したカスタムドメイン) の所有権があり、Azure DNS で管理できること。
