output "instance_ips" {
    value = google_compute_instance.folding[*].network_interface[0].access_config[0].nat_ip
}

output "fah_access_password" {
    value = data.template_file.fah_config.vars.fah_access_password
}