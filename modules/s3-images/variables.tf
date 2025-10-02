variable "bucket_name" {
  description = "The name of the S3 bucket for product images."
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
  default     = {}
}