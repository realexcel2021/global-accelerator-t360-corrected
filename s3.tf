locals {
  public_bucket_name = "t360-photos-bucket-public-00220011202220"
}

module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "t360-photos-bucket-private-00220011202220"
  acl    = "private"
  force_destroy = true

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  versioning = {
    enabled = false
  }
}

module "s3_bucket_public" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "t360-photos-bucket-public-00220011202220"
  acl    = "public-read-write"
  block_public_acls = false
  block_public_policy = false
  ignore_public_acls = false
  restrict_public_buckets = false
  force_destroy = true


  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  attach_policy = true
  policy = <<EOF

  {
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${local.public_bucket_name}/*"
    }
  ]
}


EOF

  versioning = {
    enabled = false
  }
}