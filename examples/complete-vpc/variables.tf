variable "region" {
  type        = string
  description = "The default region for the test."
  default     = ""
}

variable "contact" {
  type        = string
  description = "The contact for tagging"
}

variable "environment" {
  type        = string
  description = "The environment for the text (sbx, dev, qa, etc)"
  default     = "sbx"
}

variable "team" {
  type        = string
  description = "The team, used for tagging."
}

variable "purpose" {
  type        = string
  description = "The purpose of this resource, used for tagging"
  default     = "terratest"
}

variable "cluster_name" {
  type        = string
  description = "Cluster name used for ELB targetting."
  default     = ""
}