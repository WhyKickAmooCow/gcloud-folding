resource "google_compute_instance" "folding" {
  name         = var.instance_name
  machine_type = var.machine_type

  scheduling {
    preemptible         = false
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

  metadata = {
    startup-script  = file(var.startup_script_file)
    shutdown-script = file(var.shutdown_script_file)
    user-data       = file("cloud-init.yml")
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