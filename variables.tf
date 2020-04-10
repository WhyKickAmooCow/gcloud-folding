variable "project" {}

variable "credentials_file" {}

variable "region" {}

variable "zone" {}

variable "machine_type" {
  default = "n1-highcpu-2"
}

variable "gpu_type" {}

variable "gpu_count" {}

variable "startup_script_file" {
  default = "./startup.sh"
}

variable "shutdown_script_file" {
  default = "./shutdown.sh"
}

variable "initial_image" {}

variable "instance_name" {}