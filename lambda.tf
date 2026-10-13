# IAM role for lambda execution

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "example" {
  name               = "lambda_execution_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# Package the lambda function code
data "archive_file" "example" {
  type        = "zip"
  source_file = "${path.module}/lambda/lambda_function.py"
  output_path = "${path.module}/lambda/function.zip"
}

# Lambda function

resource "aws_lambda_function" "example" {
  filename      = data.archive_file.example.output_path
  function_name = "document-upload"
  role          = aws_iam_role.example.arn
  handler       = "lambda_function.lambda_handler"
  code_sha256   = data.archive_file.example.output_base64sha256

  runtime = "python3.13"

  environment {
    variables = {
      environment = "dev"
      LOG_LEVEL   = "info"
    }
  }

  tags = {
    environment = "dev"
    Application = "example"
  }

}

data "aws_iam_policy_document" "lambda_permissions" {

  statement {
    effect = "Allow"

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "arn:aws:s3:::document-registration-and-upload-fpt/*"
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "dynamodb:PutItem"
    ]

    resources = [
      aws_dynamodb_table.basic_dynamodb_table.arn
    ]
  }
}

resource "aws_iam_policy" "lambda_permissions" {
  name   = "document-upload-lambda-permissions"
  policy = data.aws_iam_policy_document.lambda_permissions.json
}
resource "aws_iam_role_policy_attachment" "lambda_permissions" {
  role       = aws_iam_role.example.name
  policy_arn = aws_iam_policy.lambda_permissions.arn
}
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.example.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id = aws_apigatewayv2_api.documents_api.id

  integration_type = "AWS_PROXY"
  integration_uri = aws_lambda_function.example.invoke_arn

  payload_format_version = "2.0"
}
resource "aws_apigatewayv2_route" "document_post" {
  api_id = aws_apigatewayv2_api.documents_api.id
  route_key = "POST /documents"

  target = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id = "AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.example.function_name
  principal = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.documents_api.execution_arn}/*/*"
  
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.documents_api.id
  name        = "$default"
  auto_deploy = true
}