provider "google" {
  version = "3.16.0"

  credentials = file(var.credentials_file)

  project = var.project
  region  = var.region
  zone    = var.zone
}


resource "google_compute_instance" "default" {
  name         = "instance-5"
  machine_type = var.machine_type

  scheduling {
    preemptible = false
    automatic_restart = false
    on_host_maintenance = "terminate"
  }

  guest_accelerator {
    type = var.gpu_type
    count = var.gpu_count
  }

  labels = {
      type = "preempt"
  }

  metadata = {
    startup-script = file(var.startup_script_file)
    shutdown-script = file(var.shutdown_script_file)
    user-data = file("cloud-init.yml")
  }

  boot_disk {
    initialize_params {
      image = var.initial_image
    }
  }

  network_interface {
    network = "default"
    access_config {
      // Ephemeral IP
    }
  }
}