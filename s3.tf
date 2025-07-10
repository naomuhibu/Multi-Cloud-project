# =============================================================================
# S3 BUCKET
# =============================================================================

resource "aws_s3_bucket" "logs_backup" {
  bucket = "yoobee-wordpress-logs-backup-${random_string.bucket_suffix.result}"

  tags = {
    Name        = "yoobee-wordpress-logs-backup"
    Purpose     = "LogsBackup"
    Environment = var.environment
  }
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_versioning" "logs_backup" {
  bucket = aws_s3_bucket.logs_backup.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs_backup" {
  bucket = aws_s3_bucket.logs_backup.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Policy
resource "aws_s3_bucket_policy" "logs_backup" {
  bucket = aws_s3_bucket.logs_backup.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid     = "AllowCloudWatchLogs"
        Effect  = "Allow"
        Principal = {
          Service = "logs.amazonaws.com"
        }
        Action = [
          "s3:PutObject",
          "s3:GetBucketAcl"
        ]
        Resource = [
          aws_s3_bucket.logs_backup.arn,
          "${aws_s3_bucket.logs_backup.arn}/*"
        ]
      },
      {
        Sid     = "AllowLambdaAccess"
        Effect  = "Allow"
        Principal = {
          AWS = aws_iam_role.lambda_backup.arn
        }
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.logs_backup.arn}/*"
      }
    ]
  })
}

# S3 Lifecycle Configuration
resource "aws_s3_bucket_lifecycle_configuration" "logs_backup" {
  bucket = aws_s3_bucket.logs_backup.id

  rule {
    id     = "lifecycle_rule"
    status = "Enabled"

    transition {
      days          = 20
      storage_class = "STANDARD_IA"
    }

    expiration {
      days = 90
    }
  }
}