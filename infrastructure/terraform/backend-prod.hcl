bucket         = "ecommerce-terraform-state-prod"
key            = "prod/terraform.tfstate"
region         = "us-west-2"
encrypt        = true
dynamodb_table = "terraform-state-lock-prod"