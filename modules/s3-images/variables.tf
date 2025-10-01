variable "bucket_name" {
  type        = string
  description = "The name of the S3 bucket for product images."
}

variable "acl" {
  type        = string
  description = "The canned ACL to apply to the bucket."
  default     = "private"
}

variable "force_destroy" {
  type        = bool
  description = "Whether to force destroy the bucket."
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to apply to the bucket."
  default     = {}
}