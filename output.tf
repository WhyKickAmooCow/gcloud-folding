output "fah_instance_ips" {
  description = "IP addresses of all instance with Folding at Home installed"
  value       = concat(module.fah_instance.instance_ips, module.fah_boinc_instance.instance_ips)
}

output "boinc_instance_ips" {
  description = "IP addresses of all instance with BOINC installed"
  value       = concat(module.boinc_instance.instance_ips, module.fah_boinc_instance.instance_ips)
}

output "remote_access_password" {
  value = data.template_file.fah_config.vars.fah_access_password
}