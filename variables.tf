variable "project" {}

variable "credentials_file" {}

variable "default_region" {}

variable "compute_region" {
  default = default_region
}

variable "function_region" {
  default = default_region
}

variable "scheduler_region" {
  default = default_region
}

variable "default_zone" {}

variable "compute_zone" {
  default = default_zone
}

variable "machine_type" {
  default = "n1-highcpu-2"
}

variable "gpu_type" {}

variable "gpu_count" {}

variable "startup_script_file" {
  default = "./resources/startup.sh"
}

variable "shutdown_script_file" {
  default = "./resources/shutdown.sh"
}

variable "initial_image" {}

variable "instance_name" {}