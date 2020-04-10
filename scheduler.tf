resource "google_cloud_scheduler_job" "start_preemtive_vm" {
  name        = "start-preemptive-vm"
  description = "Start any preemptive vms in case any have gone down"
  schedule    = "*/5 * * * *"

  pubsub_target {
    # topic.id is the topic's full resource name.
    topic_name = google_pubsub_topic.start_vm.id
    data       = base64encode(jsonencode({
      zone = var.zone
      label = "type=preempt"
    }))
  }
}