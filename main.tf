resource "aws_instance" "example" {
  ami           = "ami-0206f4f885421736f" 
  instance_type = "t3.micro"

  tags = {
    Name = "terraform-example"
  }
}