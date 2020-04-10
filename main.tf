provider "google" {
  version = "3.16.0"

  credentials = file(var.credentials_file)

  project = var.project
  region  = var.region
  zone    = var.zone
}


resource "google_compute_instance" "default" {
  name         = "instance-5"
  machine_type = "n1-standard-1"

  labels = {
      type = "preempt"
  }

  metadata = {
    startup-script = file(var.startup_script_file)
    shutdown-script = file(var.shutdown_script_file)
    user-data = file("cloud-init.yml")
    fah-version = "fahclient_7.4.4"
  }

  boot_disk {
    initialize_params {
      image = var.initial_image
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
      // Ephemeral IP
    }
  }

  provisioner "local-exec" {
    command = "echo ${google_compute_instance.vm_instance.name}:  ${google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip} >> ip_address.txt"
  }
}

resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
}