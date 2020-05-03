resource "random_id" "instance_id" {
  byte_length = 2
  count       = var.machine_count
}

resource "google_compute_instance" "compute" {
  name         = "${var.instance_prefix}-${random_id.instance_id.*.dec[count.index]}"
  machine_type = var.machine_type
  count        = var.machine_count
  zone         = var.zone

  scheduling {
    preemptible         = true
    automatic_restart   = false
    on_host_maintenance = "TERMINATE"
  }

  guest_accelerator {
    type  = var.gpu_type
    count = var.gpu_count
  }

  labels = {
    type = "preempt"
  }

  metadata = var.metadata
  
  boot_disk {
    initialize_params {
      image = var.initial_image
    }
  }

  network_interface {
    network = var.network
    access_config {
      nat_ip = var.static_ip ? google_compute_address.static[count.index].address : ""
    }
  }
}

resource "google_compute_address" "static" {
  name  = "ipv4-address-${random_id.instance_id.*.dec[count.index]}"
  count = var.static_ip ? var.machine_count : 0
}
