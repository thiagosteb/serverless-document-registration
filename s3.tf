resource "aws_s3_bucket" "documents" {
  bucket = "document-registration-and-upload-fpt"

  tags = {
    Name        = "Document registration-upload bucket"
    Environment = "dev"
  }
}