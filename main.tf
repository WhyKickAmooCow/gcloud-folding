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

locals {
  compute_zone = coalesce(var.compute_zone, var.default_zone)

  fah_version_major      = split(".", var.fah_version)[0]
  fah_version_minor      = split(".", var.fah_version)[1]
  remote_access_password = coalesce(var.remote_access_password, random_password.remote_access_password.result)

  boinc_metadata = {
    startup-script = templatefile(var.startup_script_file, {
      boic = true
      fah  = false
    })
    shutdown-script = templatefile(var.shutdown_script_file, {
      boinc = true
      fah   = false
    })
    user-data = templatefile("./resources/cloud-init.yml", {
      boinc             = true
      fah               = false
      fah_version       = var.fah_version
      fah_version_major = local.fah_version_major
      fah_version_minor = local.fah_version_minor
    })
    boinc-remote-hosts    = join("\n", split(" ", var.remote_access_ip))
    boinc-access-password = local.remote_access_password
  }

  fah_metadata = {
    startup-script = templatefile(var.startup_script_file, {
      boinc = false
      fah   = true
    })
    shutdown-script = templatefile(var.shutdown_script_file, {
      boinc = false
      fah   = true
    })
    user-data = templatefile("./resources/cloud-init.yml", {
      boinc             = false
      fah               = true
      fah_version       = var.fah_version
      fah_version_major = local.fah_version_major
      fah_version_minor = local.fah_version_minor
    })
    fah-config = data.template_file.fah_config.rendered
  }

  fah_boinc_metadata = {
    startup-script = templatefile(var.startup_script_file, {
      boinc = true
      fah   = true
    })
    shutdown-script = templatefile(var.shutdown_script_file, {
      boinc = true
      fah   = true
    })
    user-data = templatefile("./resources/cloud-init.yml", {
      boinc             = true
      fah               = true
      fah_version       = var.fah_version
      fah_version_major = local.fah_version_major
      fah_version_minor = local.fah_version_minor
    })
    fah-config            = data.template_file.fah_config.rendered
    boinc-remote-hosts    = join("\n", split(" ", var.remote_access_ip))
    boinc-access-password = local.remote_access_password
  }
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
    fah_access_ip       = var.remote_access_ip
    fah_access_password = local.remote_access_password
    fah_username        = var.fah_username
    fah_passkey         = var.fah_passkey
    fah_team            = var.fah_team
    gpu_slots           = join("\n  ", data.template_file.gpu_slots[*].rendered)
  }
}

resource "random_password" "remote_access_password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

module "boinc_instance" {
  source = "./modules/instance"

  network         = google_compute_network.vpc_network.name
  static_ip       = var.static_ip
  metadata        = local.boinc_metadata
  instance_prefix = "boinc"
  machine_type    = var.machine_type
  machine_count   = var.boinc_machine_count
  zone            = local.compute_zone
  gpu_type        = var.gpu_type
  gpu_count       = var.gpu_count
  initial_image   = var.initial_image
}

module "fah_instance" {
  source = "./modules/instance"

  network         = google_compute_network.vpc_network.name
  static_ip       = var.static_ip
  metadata        = local.fah_metadata
  instance_prefix = "folding"
  machine_type    = var.machine_type
  machine_count   = var.fah_machine_count
  zone            = local.compute_zone
  gpu_type        = var.gpu_type
  gpu_count       = var.gpu_count
  initial_image   = var.initial_image
}

module "fah_boinc_instance" {
  source = "./modules/instance"

  network         = google_compute_network.vpc_network.name
  static_ip       = var.static_ip
  metadata        = local.fah_boinc_metadata
  instance_prefix = "fah-boinc"
  machine_type    = var.machine_type
  machine_count   = var.fah_boinc_machine_count
  zone            = local.compute_zone
  gpu_type        = var.gpu_type
  gpu_count       = var.gpu_count
  initial_image   = var.initial_image
}

resource "google_compute_firewall" "folding_access" {
  name    = "folding-remote-access"
  network = google_compute_network.vpc_network.name
  count   = var.fah_machine_count > 0 || var.fah_boinc_machine_count > 0 ? 1 : 0

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["80", "443", var.fah_access_port]
  }
}

resource "google_compute_firewall" "boinc_access" {
  name    = "boinc-remote-access"
  network = google_compute_network.vpc_network.name
  count   = var.boinc_machine_count > 0 || var.fah_boinc_machine_count > 0 ? 1 : 0

  allow {
    protocol = "tcp"
    ports    = ["31416"]
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
  name = "${var.project}-folding-bucket"
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