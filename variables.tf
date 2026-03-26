


variable "aws_region" {
  type    = string
  default = "us-west-2"
}

variable "cluster_name" {
  type    = string
  default = "mmejia-eks-llm"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  type    = list(string)
  default = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "instance_types" {
  type    = list(string)
  default = ["m6i.xlarge"]
}

variable "desired_size" {
  type    = number
  default = 2
}

variable "min_size" {
  type    = number
  default = 1
}

variable "max_size" {
  type    = number
  default = 3
}

variable "app_namespace" {
  type    = string
  default = "chatbot"
}

variable "app_hostname" {
  type    = string
  default = "mmejia.sb.anacondaconnect.com"
}

variable "app_image" {
  type    = string
  default = "REPLACE_ME.dkr.ecr.us-west-2.amazonaws.com/llama3-gradio-ui:latest"
}
