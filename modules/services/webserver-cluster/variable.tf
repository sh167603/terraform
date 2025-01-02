variable "server_port" {
  description = "The port. the server will use for HTTP requests"
  type        = number
}

variable "cluster_name" {
 description = "The name to use for all the cluster resources"
 type = string
}
variable "db_remote_state_bucket" {
 description = "The name of the S3 bucket for the database's remote state"
 type = string
}
variable "db_remote_state_key" {
 description = "The path for the database's remote state in S3"
 type = string
}

output "alb_dns_name" {
 value = aws_lb.example.dns_name
 description = "The domain name of the load balancer"
}
