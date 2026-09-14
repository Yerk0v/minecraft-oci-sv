output "instance_public_ip" {
  description = "Public IPv4 address of the Minepanel host."
  value       = oci_core_instance.minepanel.public_ip
}

output "ssh_command" {
  description = "SSH command after apply."
  value       = "ssh ubuntu@${oci_core_instance.minepanel.public_ip}"
}

output "data_volume_id" {
  description = "OCI block volume containing Minepanel runtime data."
  value       = oci_core_volume.minepanel_data.id
}

