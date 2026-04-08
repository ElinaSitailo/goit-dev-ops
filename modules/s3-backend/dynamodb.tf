resource "aws_dynamodb_table" "terraform_locks" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"  # Pay only for what you use
  hash_key     = var.table_hash_key # Required key for Terraform

  # Define the primary key for the DynamoDB table
  attribute {
    name = var.table_hash_key
    type = "S" # String type
  }

  # Point-in-time recovery for table restoration
  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name        = var.table_name
    Description = "Terraform state locking table"
  }
}
