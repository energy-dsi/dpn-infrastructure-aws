# Replace after running the bootstrap stack. The KMS key ARN is available from
# the bootstrap outputs.
bucket         = "example-platform-tfstate-111122223333-eu-west-2"
key            = "example/terraform.tfstate"
region         = "eu-west-2"
dynamodb_table = "example-platform-tfstate-lock-example"
encrypt        = true
kms_key_id     = "arn:aws:kms:eu-west-2:111122223333:key/00000000-0000-4000-8000-000000000000"
