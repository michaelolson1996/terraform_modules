#############################################################
# PROVIDERS
#############################################################

terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      version = "0.9.4"
    }
  }
}

provider "libvirt" {
  uri = var.libvirt_uri
}

#############################################################
# LOCALS
#############################################################

locals {
  pool_path = "${var.pool_path}/${var.pool_name}"
  gb = 1024 * 1024 * 1024
}

#############################################################
# STORAGE POOL
#############################################################

resource "libvirt_pool" "lfs" {
  name   = var.pool_name
  type   = "dir"
  target = {
    path = local.pool_path
  }

  create = {
    build     = true
    start     = true
    autostart = true
  }
}

#############################################################
# OS DISK (BASE)
#############################################################

resource "libvirt_volume" "lfs_base" {
  name   = "${var.base_image_name}.qcow2"
  pool   = libvirt_pool.lfs.name

  target = {
    format = {
      type = "qcow2"
    }
  }

  create = {
    content = {
      url = var.base_image
    }
  }
}

#############################################################
# OS DISK (OVERLAY)
#############################################################

resource "libvirt_volume" "lfs_overlay" {
  name     = "${var.overlay_image_name}.qcow2"
  pool     = libvirt_pool.lfs.name
  capacity = var.overlay_image_size * local.gb

  target = {
    format = {
      type = "qcow2"
    }
  }

  backing_store = {
    path   = libvirt_volume.lfs_base.id
    format = {
      type = "qcow2"
    }
  }
}

#############################################################
# LFS DISK (LFS)
#############################################################

resource "libvirt_volume" "lfs" {
  name     = "${var.lfs_disk_name}.qcow2"
  pool     = libvirt_pool.lfs.name
  capacity = var.lfs_disk_size * local.gb

  target = {
    format = {
      type = "qcow2"
    }
  }
}

#############################################################
# CLOUD INIT
#############################################################

resource "libvirt_cloudinit_disk" "lfs_init" {
  name = "${var.vm_name}-init"

  user_data = templatefile("${path.module}/user-data.yml", {
    ssh_key = var.ssh_public_key
    lfs_disk = substr(sha256(libvirt_volume.lfs.key), 1, 20)
  })

  meta_data = yamlencode({
    instance-id    = var.vm_name
    local-hostname = var.vm_name
  })
}

#############################################################
# VM
#############################################################

resource "libvirt_domain" "lfs_vm" {
  name        = var.vm_name
  memory      = var.vm_memory
  memory_unit = "GiB"
  vcpu        = var.vm_vcpu

  type      = "kvm"
  autostart = true
  running   = true

  os = {
    type         = "hvm"
    type_machine = "q35"
    firmware     = var.vm_use_uefi ? "efi" : null
    boot         = [{ dev = "hd" }]
  }

  cpu = { 
    mode = "host-passthrough"
  }

  features = {
    acpi = true
  }

  devices = {
    disks = [
      {
        source = {
          file = {
            file = libvirt_volume.lfs_overlay.id
          }
        }
        target = {
          dev = "vda"
          bus = "virtio"
        }
        driver = {
          type = "qcow2"
        }
      },
      {
        source = {
          file = {
            file = libvirt_volume.lfs.id
          }
        }
        target = {
          dev = "vdb"
          bus = "virtio"
        }
        driver = {
          type = "qcow2"
        }
        serial = substr(sha256(libvirt_volume.lfs.key), 1, 20)
      },
      {
        source = {
          file = {
            file = libvirt_cloudinit_disk.lfs_init.path
          }
        }
        target = {
          dev = "sda"
          bus = "sata"
        }
        device   = "cdrom"
        readonly = true
      }
    ]

    interfaces = [
      {
        model = {
          type = "virtio"
        }
        source = {
          network = {
            network = "default"
          }
        }
      }
    ]

    serials = [
      {
        type = "pty"
        target_port = "0"
      }
    ]

    videos = var.vm_use_uefi == false ? [
      {
        model = {
          type    = "virtio"
          heads   = 1
          primary = "yes"
        }
      }
    ] : []
  }
}
