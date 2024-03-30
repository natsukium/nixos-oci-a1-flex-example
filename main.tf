terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
    }
  }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  private_key_path = var.private_key_path
  fingerprint      = var.fingerprint
  region           = var.region
}

resource "oci_identity_compartment" "nixos-example-compartment" {
  description    = "The compartment for nixos-example"
  compartment_id = var.tenancy_ocid
  name           = "nixos-example"
}

resource "oci_core_vcn" "nixos-example-vcn" {
  cidr_block     = "10.0.0.0/16"
  compartment_id = oci_identity_compartment.nixos-example-compartment.id
  display_name   = "nixos-example"
}

resource "oci_core_subnet" "nixos-example-subnet" {
  cidr_block     = "10.0.0.0/24"
  compartment_id = oci_identity_compartment.nixos-example-compartment.id
  vcn_id         = oci_core_vcn.nixos-example-vcn.id
  route_table_id = oci_core_route_table.nixos-example-route_table.id
}

resource "oci_core_internet_gateway" "nixos-example-igw" {
  compartment_id = oci_identity_compartment.nixos-example-compartment.id
  vcn_id         = oci_core_vcn.nixos-example-vcn.id
  enabled        = "true"
}

resource "oci_core_route_table" "nixos-example-route_table" {
  compartment_id = oci_identity_compartment.nixos-example-compartment.id
  route_rules {
    network_entity_id = oci_core_internet_gateway.nixos-example-igw.id
    destination       = "0.0.0.0/0"
  }
  vcn_id = oci_core_vcn.nixos-example-vcn.id
}

resource "oci_core_security_list" "nixos-example-security_list" {
  compartment_id = oci_identity_compartment.nixos-example-compartment.id
  vcn_id         = oci_core_vcn.nixos-example-vcn.id
}

resource "oci_core_instance" "nixos-example-instance" {
  availability_domain = var.availability_domain
  compartment_id      = oci_identity_compartment.nixos-example-compartment.id
  shape               = "VM.Standard.A1.Flex"
  shape_config {
    memory_in_gbs = "24"
    ocpus         = "4"
  }
  display_name = "nixos-example"

  create_vnic_details {
    assign_ipv6ip             = "false"
    assign_private_dns_record = "true"
    assign_public_ip          = "true"
    subnet_id                 = oci_core_subnet.nixos-example-subnet.id
  }

  source_details {
    boot_volume_size_in_gbs = "200"
    boot_volume_vpus_per_gb = "10"
    source_id               = var.image_id
    source_type             = "image"
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }
}

module "deploy" {
  source                 = "github.com/nix-community/nixos-anywhere/terraform/all-in-one"
  nixos_system_attr      = ".#nixosConfigurations.nixos-example.config.system.build.toplevel"
  nixos_partitioner_attr = ".#nixosConfigurations.nixos-example.config.system.build.diskoScript"
  target_host            = oci_core_instance.nixos-example-instance.public_ip
  instance_id            = oci_core_instance.nixos-example-instance.public_ip
  install_user           = "ubuntu"
}

output "ip-address" {
  value = oci_core_instance.nixos-example-instance.public_ip
}
