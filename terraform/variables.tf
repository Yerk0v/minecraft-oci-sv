variable "tenancy_ocid" {
  description = "OCI tenancy OCID."
  type        = string
}

variable "compartment_ocid" {
  description = "Compartment where the Minecraft host is created. Use the tenancy OCID for a first personal deployment."
  type        = string
}

variable "availability_domain" {
  description = "Availability domain for the instance and data volume."
  type        = string
}

variable "ssh_public_key" {
  description = "Contents of your public SSH key, for example ~/.ssh/id_ed25519.pub."
  type        = string
}

variable "admin_cidrs" {
  description = "CIDRs allowed to access SSH and the panel HTTPS endpoint. Replace the example with your public IP/CIDR."
  type        = list(string)

  validation {
    condition     = length(var.admin_cidrs) > 0 && !contains(var.admin_cidrs, "0.0.0.0/0")
    error_message = "Use one or more specific admin CIDRs; do not expose SSH or the panel to the whole internet."
  }
}

variable "vcn_cidr" {
  description = "CIDR range for the virtual cloud network."
  type        = string
  default     = "10.42.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR range for the public subnet."
  type        = string
  default     = "10.42.1.0/24"
}

variable "instance_display_name" {
  description = "Display name for the OCI instance."
  type        = string
  default     = "minepanel"
}

variable "ocpus" {
  description = "Ampere A1 OCPUs allocated to this instance. Keep all A1 instances within your tenancy's Always Free allowance."
  type        = number
  default     = 2
}

variable "memory_in_gbs" {
  description = "Memory allocated to the Ampere A1 instance."
  type        = number
  default     = 12
}

variable "data_volume_size_gbs" {
  description = "Persistent volume for Minepanel data, worlds, and backups."
  type        = number
  default     = 150
}

variable "enable_bedrock" {
  description = "Open UDP 19132 for a Bedrock server."
  type        = bool
  default     = false
}

