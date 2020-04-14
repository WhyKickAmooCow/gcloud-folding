# gcloud-folding

## Variables

#### project : String
Project ID to create resources in.

#### credentials_file : String
Location of file with credentials/keys for account used to provision the infrastructure.

#### default_region : String
The default region to create resources in.

#### app_region : String
The region to create App Engine resources in (Cloud Scheduler included).

#### function_region : String
The region to create Cloud Functions in.

#### default_zone : String
The default zone to create resources in.

#### compute_zone : String
The zone to create compute instances in.

#### machine_type : String
The compute instance type to create.

#### machine_count : Number
The number of compute instances to be created.

#### static_ip : Boolean
Enable static IP addresses for the compute instances.

#### gpu_type : String
The type of GPU to attach to the compute instances.

#### gpu_count : Number
The number of GPUs of the given type to attach to each compute instance.

#### startup_script_file : String
Location of script file to have run on instance startup.

#### shutdown_script_file String
Location of script file to have run on instance shutdown.

#### initial_image : String
The initial boot image to use for the compute instances (e.g Ubuntu, Fedora, RHEL). the cloud-init.yml is setup assuming Ubuntu 18.04.

#### instance_prefix : String
The prefix to use when generating names for the compute instances.

#### fah_version : String
The version of the Folding at Home client to install (e.g. 7.5.1).

#### fah_username : String
Your Folding at Home username to have the client fold for.

#### fah_passkey : String
The passkey associated with your Folding at Home username.

#### fah_team : String
The team to have the client fold for. Go 223518!

#### fah_access_ip : String
The (space separated) list of IP addresses to allow remote access from. Can also accept ranges, e.g. 123.456.789.012-123.456.789.255 or 0.0.0.0/0). Recommended that you set this to your home IP address. 0.0.0.0/0 will allow access from all IPv4 addresses.

#### fah_access_password : String
The password the client will require for remote access.