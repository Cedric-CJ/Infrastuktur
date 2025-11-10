resource "aws_s3_bucket" "this" {
  bucket_prefix = var.bucket_name_prefix
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.public_read.json
}

data "aws_iam_policy_document" "public_read" {
  statement {
    sid     = "PublicRead"
    effect  = "Allow"
    actions = ["s3:GetObject"]

    resources = [
      "${aws_s3_bucket.this.arn}/*"
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_website_configuration" "this" {
  count  = var.enable_website_host ? 1 : 0
  bucket = aws_s3_bucket.this.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}
