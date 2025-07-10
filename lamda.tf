# =============================================================================
# LAMBDA FUNCTIONS
# =============================================================================

# Lambda function for RDS backup
resource "aws_lambda_function" "backup" {
  filename         = "lambda_backup.zip"
  function_name    = "LamdaFunctionBackup"
  role             = aws_iam_role.lambda_backup.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.lambda_backup.output_base64sha256
  runtime          = "nodejs20.x"
  timeout          = 300

  environment {
    variables = {
      S3_BUCKET     = aws_s3_bucket.logs_backup.bucket
      DB_IDENTIFIER = aws_db_instance.mysql.identifier
    }
  }

  tags = {
    Name = "LamdaFunctionBackup"
  }
}

data "archive_file" "lambda_backup" {
  type        = "zip"
  output_path = "lambda_backup.zip"
  source {
    content = <<-EOT
const AWS = require('aws-sdk');
const rds = new AWS.RDS();
const s3 = new AWS.S3();

exports.handler = async (event) => {
    const dbIdentifier = process.env.DB_IDENTIFIER;
    const s3Bucket = process.env.S3_BUCKET;
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const snapshotId = `${dbIdentifier}-snapshot-${timestamp}`;

    try {
        // Create RDS snapshot
        const snapshotResult = await rds.createDBSnapshot({
            DBSnapshotIdentifier: snapshotId,
            DBInstanceIdentifier: dbIdentifier
        }).promise();

        console.log('Snapshot created:', snapshotResult.DBSnapshot.DBSnapshotIdentifier);

        return {
            statusCode: 200,
            body: JSON.stringify({
                message: 'Backup completed successfully',
                snapshotId: snapshotId
            })
        };
    } catch (error) {
        console.error('Error creating backup:', error);
        throw error;
    }
};
EOT
    filename = "index.js"
  }
}

# Lambda function for CloudWatch logs export
resource "aws_lambda_function" "cwlogs" {
  filename         = "lambda_cwlogs.zip"
  function_name    = "LamdaFunctionCWlogs"
  role             = aws_iam_role.lambda_cwlogs.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda_cwlogs.output_base64sha256
  runtime          = "python3.12"
  timeout          = 300

  environment {
    variables = {
      S3_BUCKET = aws_s3_bucket.logs_backup.bucket
    }
  }

  tags = {
    Name = "LamdaFunctionCWlogs"
  }
}

data "archive_file" "lambda_cwlogs" {
  type        = "zip"
  output_path = "lambda_cwlogs.zip"
  source {
    content = <<-EOT
import boto3
import json
import os
from datetime import datetime, timedelta

def lambda_handler(event, context):
    logs_client = boto3.client('logs')
    s3_bucket = os.environ['S3_BUCKET']

    try:
        # Get log groups
        log_groups = logs_client.describe_log_groups()

        for log_group in log_groups['logGroups']:
            log_group_name = log_group['logGroupName']

            # Skip AWS service logs unless explicitly included
            if not log_group_name.startswith('/ec2/wordpress/'):
                continue

            # Create export task
            start_time = int((datetime.now() - timedelta(days=1)).timestamp() * 1000)
            end_time = int(datetime.now().timestamp() * 1000)

            export_task = logs_client.create_export_task(
                logGroupName=log_group_name,
                fromTime=start_time,
                to=end_time,
                destination=s3_bucket,
                destinationPrefix='daily-logs-from-CW/'
            )

            print(f"Export task created for {log_group_name}: {export_task['taskId']}")

        return {
            'statusCode': 200,
            'body': json.dumps('CloudWatch logs export completed successfully')
        }
    except Exception as e:
        print(f"Error: {str(e)}")
        raise e
EOT
    filename = "lambda_function.py"
  }
}