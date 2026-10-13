resource "aws_apigatewayv2_api" "documents_api" {
  name          = "documents_api"
  protocol_type = "HTTP"
}