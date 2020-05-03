credentials_file        = "./resources/credentials.json"
default_region          = "us-west1"
default_zone            = "us-west1-b"
function_region         = "us-central1"
app_region              = "us-west2"
initial_image           = "ubuntu-os-cloud/ubuntu-minimal-1804-lts"
gpu_type                = "nvidia-tesla-p100"
gpu_count               = 1 # GPUs per instance
machine_type            = "n1-standard-2"
fah_version             = "7.5.1"
static_ip               = true                     # Use static ip addresses for all of the instances (at a cost of 1.46/month or 0.002 per hour)
project                 = "luminous-figure-273409" # GCP project ID
boinc_machine_count     = 0 # Instances exclusively running BOINC
fah_machine_count       = 1 # Instances exclusively running F@H
fah_boinc_machine_count = 0 # Instances running both BOINC and F@H
# fah_username            = ""                   # F@H username
# fah_passkey             = "" # F@H user passkey
# fah_team                = 223518                             # Team to fold for
# remote_access_password  = ""                 # What password to require for remote access
# remote_access_ip        = ""                   # What IP addresses that F@H will allow remote access from: 0.0.0.0/0 for all IP addresses, or put in your one