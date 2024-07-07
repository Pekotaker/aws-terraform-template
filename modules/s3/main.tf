module "private_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket_prefix = var.private_bucket_prefix_name
  # acl           = "private"

  control_object_ownership = true
  object_ownership         = "BucketOwnerEnforced"

  versioning = {
    enabled = false
  }
}

module "public_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket_prefix = var.public_bucket_prefix_name
  # acl           = "public-read-write"

  control_object_ownership = true
  object_ownership         = "BucketOwnerEnforced"
  block_public_acls        = false
  block_public_policy      = false
  ignore_public_acls       = false
  restrict_public_buckets  = false
  # attach_policy            = true
  versioning = {
    enabled = false
  }
}



resource "aws_s3_bucket_policy" "s3_public_bucket_policy" {
  bucket = module.public_bucket.s3_bucket_id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : "s3:GetObject",
        "Resource" : "arn:aws:s3:::${module.public_bucket.s3_bucket_id}/*"
      }
    ]
  })
  depends_on = [module.public_bucket]
}

module "cdn" {
  source              = "terraform-aws-modules/cloudfront/aws"
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"
  retain_on_delete    = false
  wait_for_deployment = false

  create_origin_access_identity = true
  origin_access_identities = {
    s3_public_bucket = "CloudFront can access S3"
  }

  origin = {
    s3_public_bucket = {
      domain_name = module.public_bucket.s3_bucket_bucket_regional_domain_name
      s3_origin_config = {
        origin_access_identity = "s3_public_bucket"
      }
    }
  }

  default_cache_behavior = {
    target_origin_id       = "s3_public_bucket"
    viewer_protocol_policy = "redirect-to-https"
    # cache_policy_name      = "Managed-CachingOptimized" # cause error: Provider produced inconsistent final plan
    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true
    query_string    = true
  }

  # ordered_cache_behavior = [
  #   {
  #     path_pattern           = "/static/*"
  #     target_origin_id       = "s3_one"
  #     viewer_protocol_policy = "redirect-to-https"

  #     allowed_methods = ["GET", "HEAD", "OPTIONS"]
  #     cached_methods  = ["GET", "HEAD"]
  #     compress        = true
  #     query_string    = true
  #   }
  # ]

  depends_on = [aws_s3_bucket_policy.s3_public_bucket_policy]
}
