resource "aws_iam_role" "default" {
  name        = "lambda_${var.function_name}"
  description = "IAM role for the ${var.function_name} function"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": "AllowLambdaToAssumeThisRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "default" {
  name        = "lambda_${var.function_name}"
  path        = "/"
  description = "IAM policy for the ${var.function_name} function"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowLogCreation",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:${local.account_id}:*/aws/lambda/*"
    },
    {
        "Sid": "AllowShutdown",
        "Effect": "Allow",
        "Action": [
            "autoscaling:SetDesiredCapacity",
            "autoscaling:UpdateAutoScalingGroup",
            "autoscaling:*Update*",
            "ec2:DescribeInstances",
            "ec2:DescribeRegions",
            "ec2:CancelSpotFleetRequests",
            "ec2:DescribeSpotInstanceRequests",
            "ec2:StopInstances",
            "ec2:Stop*",
            "ec2:DescribeSpotFleetRequests",
            "ec2:CancelSpotInstanceRequests",
            "ecs:DescribeServices",
            "ecs:ListClusters",
            "ecs:ListServices",
            "ecs:UpdateService",
            "autoscaling:DescribeAutoScalingGroups",
            "sagemaker:ListNotebookInstances",
            "sagemaker:ListTags",
            "sagemaker:StopNotebookInstance",
            "rds:DescribeDBInstances",
            "rds:DescribeDBClusters",
            "rds:ListTagsForResource",
            "rds:Stop*",
            "redshift:DescribeClusters",
            "redshift:PauseCluster"
        ],
        "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "default" {
  role       = aws_iam_role.default.name
  policy_arn = aws_iam_policy.default.arn
}

resource "aws_iam_role_policy_attachment" "xray" {
  role       = aws_iam_role.default.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
}

data "archive_file" "default" {
  type        = "zip"
  source_dir  = var.function_dir
  output_path = "${path.module}/.terraform/lambda_${var.function_name}.zip"
}

resource "aws_cloudwatch_log_group" "default" {
  name              = "/aws/lambda/${aws_lambda_function.default.function_name}"
  retention_in_days = 400
}

resource "aws_lambda_function" "default" {
  #checkov:skip=CKV_AWS_115:Using the default shared concurrency limit instead of reserving concurrency per function
  #checkov:skip=CKV_AWS_116:DLQ not part of the design here
  #checkov:skip=CKV_AWS_117:No VPC needed
  filename      = data.archive_file.default.output_path
  function_name = var.function_name
  description   = var.function_description
  role          = aws_iam_role.default.arn
  handler       = var.handler
  timeout       = var.timeout
  runtime       = var.runtime

  source_code_hash = data.archive_file.default.output_base64sha256

  dynamic "environment" {
    for_each = var.environment_variables != null ? [true] : []
    content {
      variables = var.environment_variables
    }
  }

  tracing_config {
    mode = "PassThrough"
  }

  tags = var.tags
}

resource "aws_cloudwatch_event_rule" "amer" {
  name        = "baseline_amer_shutdown_schedule"
  description = "Trigger the baseline_stop_instances Lambda function at the AMER shutdown time"

  # Run 2 minutes after the target hour
  schedule_expression = "cron(2 ${var.environment_variables["AMER_SHUTDOWN_HOUR"]} * * ? *)"
  is_enabled          = true

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "amer" {
  arn  = aws_lambda_function.default.arn
  rule = aws_cloudwatch_event_rule.amer.id
}

resource "aws_lambda_permission" "invoke_amer" {
  statement_id  = "AMERSchedule"
  action        = "lambda:InvokeFunction"
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.amer.arn
  function_name = aws_lambda_function.default.function_name
}

resource "aws_cloudwatch_event_rule" "emea" {
  name        = "baseline_emea_shutdown_schedule"
  description = "Trigger the baseline_stop_instances Lambda function at the EMEA shutdown time"

  schedule_expression = "cron(2 ${var.environment_variables["EMEA_SHUTDOWN_HOUR"]} * * ? *)"
  is_enabled          = true

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "emea" {
  arn  = aws_lambda_function.default.arn
  rule = aws_cloudwatch_event_rule.emea.id
}

resource "aws_lambda_permission" "invoke_emea" {
  statement_id  = "EMEASchedule"
  action        = "lambda:InvokeFunction"
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.emea.arn
  function_name = aws_lambda_function.default.function_name
}

resource "aws_cloudwatch_event_rule" "apac" {
  name        = "baseline_apac_shutdown_schedule"
  description = "Trigger the baseline_stop_instances Lambda function at the APAC shutdown time"

  schedule_expression = "cron(2 ${var.environment_variables["APAC_SHUTDOWN_HOUR"]} * * ? *)"
  is_enabled          = true

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "apac" {
  arn  = aws_lambda_function.default.arn
  rule = aws_cloudwatch_event_rule.apac.id
}

resource "aws_lambda_permission" "invoke_apac" {
  statement_id  = "APACSchedule"
  action        = "lambda:InvokeFunction"
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.apac.arn
  function_name = aws_lambda_function.default.function_name
}