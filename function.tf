resource "google_cloudfunctions_function" "start_vm" {
  name        = "start-vm-event"
  description = "Starts vms with the given tag and region"
  runtime     = "nodejs8"

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.start_vm_function_archive.name
  timeout               = 60
  entry_point           = "startInstancePubSub"

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource = google_pubsub_topic.start_vm.name
  }
}