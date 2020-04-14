locals {
  fah_version_major = split(".", var.fah_version)[0]
  fah_version_minor = split(".", var.fah_version)[1]
}

provider "archive" {
  version = "~> 1.3"
}

provider "random" {
  version = "~> 2.2"
}

provider "template" {
  version = "~> 2.1"
}

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
resource "random_id" "instance_id" {
  byte_length = 2
  count       = var.machine_count
}

resource "google_compute_address" "static" {
  name  = "ipv4-address"
  count = var.static_ip ? var.machine_count : 0
}

data "template_file" "gpu_slots" {
  template = file("./resources/gpu-slot.xml")
  count    = var.gpu_count
  vars = {
    slot_id = count.index + 1
  }
}

data "template_file" "fah_config" {
  template = file("./resources/fah-config.xml")
  vars = {
    fah_access_port     = var.fah_access_port
    fah_access_ip       = var.fah_access_ip
    fah_access_password = var.fah_access_password
    fah_username        = var.fah_username
    fah_passkey         = var.fah_passkey
    fah_team            = var.fah_team
    gpu_slots           = join("\n  ", data.template_file.gpu_slots[*].rendered)
  }
}

data "template_file" "cloud_init" {
  template = file("./resources/cloud-init.yml")
  vars = {
    fah_config        = data.template_file.fah_config.rendered
    fah_version       = var.fah_version
    fah_version_major = local.fah_version_major
    fah_version_minor = local.fah_version_minor
  }
}

resource "google_compute_instance" "folding" {
  name         = "${var.instance_prefix}-${random_id.instance_id.*.dec[count.index]}"
  machine_type = var.machine_type
  zone         = coalesce(var.compute_zone, var.default_zone)
  count        = var.machine_count

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

  metadata = {
    startup-script  = file(var.startup_script_file)
    shutdown-script = file(var.shutdown_script_file)
    user-data       = data.template_file.cloud_init.rendered
    fah-config      = data.template_file.fah_config.rendered
  }

  boot_disk {
    initialize_params {
      image = var.initial_image
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
      nat_ip = var.static_ip ? google_compute_address.static[count.index].address : ""
    }
  }
}

resource "google_compute_firewall" "folding_access" {
  name    = "folding-remote-access"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "36331"]
  }
}

resource "google_compute_firewall" "ssh_access" {
  name    = "folding-allow-ssh"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_network" "vpc_network" {
  name = "folding"
}


#
# Set up a scheduler job to trigger a function over pubsub to restart the instances periodically
#
resource "google_cloud_scheduler_job" "start_preemtive_vm" {
  name        = "start-preemptive-vm"
  description = "Start any preemptive vms in case any have gone down"
  schedule    = "*/5 * * * *"
  region      = coalesce(var.app_region, var.default_region)
  time_zone   = var.time_zone

  pubsub_target {
    # topic.id is the topic's full resource name.
    topic_name = google_pubsub_topic.start_vm.id
    data = base64encode(jsonencode({
      zone  = coalesce(var.compute_zone, var.default_zone)
      label = "type=preempt"
    }))
  }
}

resource "google_cloudfunctions_function" "start_vm" {
  name        = "start-vm-event"
  description = "Starts vms with the given tag and region"
  runtime     = "nodejs8"
  region      = coalesce(var.function_region, var.default_region)

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
  source = data.archive_file.start_vm_function_source.output_path
}

data "archive_file" "start_vm_function_source" {
  type        = "zip"
  source_dir  = "./resources/start-vm-function"
  output_path = "./output/start_vm_function.zip"
}

resource "google_pubsub_topic" "start_vm" {
  name = "start-vm"
}