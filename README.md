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

### instance_prefix : String
The prefix to use when generating names for the compute instances.
