# Optional remote backend for the bootstrap stack after its first local apply.
bucket         = "example-platform-tfstate-111122223333-eu-west-2"
key            = "bootstrap/example/terraform.tfstate"
region         = "eu-west-2"
dynamodb_table = "example-platform-tfstate-lock-example"
encrypt        = true
kms_key_id     = "arn:aws:kms:eu-west-2:111122223333:key/00000000-0000-4000-8000-000000000000"
