provider "google" {
  version = "3.16.0"

  credentials = file(var.credentials_file)

  project = var.project
  region  = var.default_region
  zone    = var.default_zone
}

#
# Setting up the instance for folding, and the network for remote access
#
resource "google_compute_instance" "folding" {
  name         = var.instance_name
  machine_type = var.machine_type
  region       = var.compute_region
  zone         = var.compute_zone

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

resource "google_compute_firewall" "folding_access" {
  name    = "folding-remote-access"
  network = google_compute_network.default.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "36331"]
  }

  source_tags = ["folding"]
}

resource "google_compute_network" "vpc_network" {
  name = "vpc-network"
}


#
# Set up a scheduler job to trigger a function over pubsub to restart the instances periodically
#
resource "google_cloud_scheduler_job" "start_preemtive_vm" {
  name        = "start-preemptive-vm"
  description = "Start any preemptive vms in case any have gone down"
  schedule    = "*/5 * * * *"
  region      = var.scheduler_region

  pubsub_target {
    # topic.id is the topic's full resource name.
    topic_name = google_pubsub_topic.start_vm.id
    data = base64encode(jsonencode({
      zone  = var.zone
      label = "type=preempt"
    }))
  }
}

resource "google_cloudfunctions_function" "start_vm" {
  name        = "start-vm-event"
  description = "Starts vms with the given tag and region"
  runtime     = "nodejs8"
  region      = var.function_region

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.start_vm_function_archive.name
  timeout               = 60
  entry_point           = "startInstancePubSub"

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.start_vm.name
  }
}

resource "google_storage_bucket" "bucket" {
  name = "folding-bucket"
}

resource "google_storage_bucket_object" "start_vm_function_archive" {
  name   = "start_vm_function.zip"
  bucket = google_storage_bucket.bucket.name
  source = "./start-vm-function.zip"
}

resource "google_pubsub_topic" "start_vm" {
  name = "start-vm"
}