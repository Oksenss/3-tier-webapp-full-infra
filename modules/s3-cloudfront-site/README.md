# Secure Static Content S3 Bucket (for frontend React)

### What It Does

Deploys a secure S3 bucket optimized for hosting static web assets

- Bucket Creation (`aws_s3_bucket.site`): Creates a private S3 bucket with a user-defined name (`var.bucket_name`).
- Default Security: Enforces strict privacy using the Public Access Block (`aws_s3_bucket_public_access_block.site`), ensuring the bucket and its objects are not publicly accessible (block public policies, block public ACLs, etc.).
- Durability: Enables versioning (`aws_s3_bucket_versioning.site_versioning`) by default to protect against accidental deletion or overwrites.
