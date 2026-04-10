# Terraform Konfiguration für zwei VMs (Prod & Test)

terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.73.0"
    }
  }
}

# Sensible Werte per Umgebungsvariablen übergeben:
# export TF_VAR_proxmox_endpoint="https://pve.example.com:8006/"
# export TF_VAR_proxmox_api_token="terraform-user@pve!terraform-token=..."
# export TF_VAR_vm_clone_ssh_public_key="ssh-ed25519 ..."
variable "proxmox_endpoint" {
  description = "Proxmox API endpoint URL"
  type        = string
}

variable "proxmox_api_token" {
  description = "Proxmox API token (inject via TF_VAR_proxmox_api_token)"
  type        = string
  sensitive   = true
}

variable "vm_clone_ssh_public_key" {
  description = "SSH public key for cloned VM"
  type        = string
}

output "fastapi_vm_test_ip_hint" {
  description = "Static inventory target currently used for the cloned Kubernetes VM"
  value       = "10.10.10.51"
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = true
}

# 1. DEINE BESTEHENDE VM (Importiert & Managed)
resource "proxmox_virtual_environment_vm" "fastapi_vm" {
  node_name = "sd-177082"
  vm_id     = 102
  name      = "VM2"

  on_boot         = true
  keyboard_layout = "en-us"
  scsi_hardware   = "virtio-scsi-single"

  cpu {
    cores = 4
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 8192
  }

  agent {
    enabled = true
    type    = "virtio"
  }

  network_device {
    bridge   = "vmbr1"
    firewall = true
  }

  operating_system {
    type = "l26"
  }

  disk {
    datastore_id = "local"
    interface    = "ide2"
    size         = 3
  }

  disk {
    datastore_id = "local"
    interface    = "scsi0"
    size         = 57
    iothread     = true
  }
}

# 2. DIE NEUE TEST-VM (Klon von VM 102)
resource "proxmox_virtual_environment_vm" "fastapi_vm_test" {
  node_name = "sd-177082"
  vm_id     = 104
  name      = "fastapi-test-clone"
  tags      = ["test", "terraform"]

  clone {
    vm_id = 102
    full  = true
  }

  cpu {
    cores = 2
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 4096
  }

  agent {
    enabled = true
  }

  network_device {
    bridge = "vmbr1"
  }

  initialization {
    user_account {
      username = "ipatsaf"
      keys     = [var.vm_clone_ssh_public_key]
    }

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }
}
