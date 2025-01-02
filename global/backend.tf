terraform {
 backend "s3" {
   bucket = "terraform-state-tnghks"
   key = "workspace-example/terraform.tfstate"
   region = "ap-northeast-3"
   dynamodb_table = "terraform-locks"
   encrypt = true
 }
}
