# Variables

variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "region" {
  default = "us-east-2"
}

variable "network_address_space" {
  default = "10.1.0.0/16"
}
variable "subnet1_address_space" {
  default = "10.1.0.0/24"
}
variable "subnet2_address_space" {
  default = "10.1.1.0/24"
}

variable "app_tag" {
    default = "howyadoing"
}

variable "site_bucket_name" {
    default = "howyadoing.coffeemonkey.net"
}

# Providers

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.region
}

# Remote storage

terraform {
  backend "s3" {
    bucket = "howyadoing-terraform-remote-state"
    key = "infrastructure/terraform.tfstate"
    region = "us-east-2"
  }
}

data "terraform_remote_state" "infrastructure" {
  backend = "s3"
  config = {
    bucket = "howyadoing-terraform-remote-state"
    key    = "infrastructure/terraform.tfstate"
    region = "us-east-2"
  }
}