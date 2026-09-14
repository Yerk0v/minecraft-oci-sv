data "oci_core_images" "ubuntu" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "24.04"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

resource "oci_core_instance" "minepanel" {
  compartment_id      = var.compartment_ocid
  availability_domain = var.availability_domain
  display_name        = var.instance_display_name
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    ocpus         = var.ocpus
    memory_in_gbs = var.memory_in_gbs
  }

  create_vnic_details {
    assign_public_ip = true
    display_name     = "minecraft-vnic"
    nsg_ids          = [oci_core_network_security_group.host.id]
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu.images[0].id
    boot_volume_size_in_gbs = 50
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data = base64encode(templatefile("${path.module}/../bootstrap/cloud-init.yaml.tftpl", {
      data_device    = "/dev/oracleoci/oraclevdb"
      enable_bedrock = var.enable_bedrock
    }))
  }
}

resource "oci_core_volume" "minepanel_data" {
  compartment_id      = var.compartment_ocid
  availability_domain = var.availability_domain
  display_name        = "minepanel-data"
  size_in_gbs         = var.data_volume_size_gbs

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_volume_attachment" "minepanel_data" {
  attachment_type = "paravirtualized"
  instance_id     = oci_core_instance.minepanel.id
  volume_id       = oci_core_volume.minepanel_data.id
  device          = "/dev/oracleoci/oraclevdb"
}
