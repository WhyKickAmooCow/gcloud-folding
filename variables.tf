variable "project" {}

variable "credentials_file" {}

variable "region" {}

variable "zone" {}

variable "startup_script_file" {
  default = "./startup.sh"
}

variable "shutdown_script_file" {
  default = "./shutdown.sh"
}

variable "provision_script_file" {
    default = "./provision.sh"
}

variable "initial_image" {}

variable "fah_version" {}
