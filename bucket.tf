resource "google_storage_bucket" "bucket" {
  name = "folding-bucket"
}

resource "google_storage_bucket_object" "start_vm_function_archive" {
  name   = "start_vm_function.zip"
  bucket = google_storage_bucket.bucket.name
  source = "./start-vm-function.zip"
}