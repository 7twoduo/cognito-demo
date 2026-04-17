resource "aws_iam_role" "ec2_s3_role" {
  name = "ec2-s3-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "://amazonaws.com"
        }
      }
    ]
  })
}

# Policy allowing read access to your specific S3 bucket
resource "aws_iam_role_policy" "s3_read_policy" {
  name = "s3-read-policy"
  role = aws_iam_role.ec2_s3_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:GetObject"]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::YOUR_BUCKET_NAME/*"
      }
    ]
  })
}

# Instance Profile to attach the role to an EC2 instance
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-s3-instance-profile"
  role = aws_iam_role.ec2_s3_role.name
}



resource "aws_instance" "example" {
  ami                  = "ami-0c55b159cbfafe1f0" # Replace with your region's AMI
  instance_type        = "t3.micro"
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOF
              #!/bin/bash
              # Update and install AWS CLI if not present in AMI
              yum update -y
              yum install -y aws-cli

              # Download the large script from S3
              aws s3 cp s3://YOUR_BUCKET_NAME/large-script.sh /tmp/large-script.sh
              
              # Make it executable and run it
              chmod +x /tmp/large-script.sh
              /tmp/large-script.sh
              EOF

  tags = {
    Name = "LargeUserDataInstance"
  }
}