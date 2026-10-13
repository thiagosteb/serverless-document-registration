resource "aws_dynamodb_table" "basic_dynamodb_table" {
  name         = "DocRegistration"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "document_id"

  attribute {
    name = "document_id"
    type = "S"
  }
}



