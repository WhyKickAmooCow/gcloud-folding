variable "project" {}

variable "credentials_file" {}

variable "default_region" {}

variable "app_region" {
  default = ""
}

variable "function_region" {
  default = ""
}


variable "default_zone" {}

variable "compute_zone" {
  default = ""
}

variable "machine_type" {}

variable "machine_count" {}

variable "static_ip" {
  default = false
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

variable "instance_prefix" {}