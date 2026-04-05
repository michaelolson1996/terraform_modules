variable "libvirt_uri" {
  description = "Specifies connection to libvirt driver, defaults to local system."
  type        = string
  default     = "qemu:///system"
}

variable "pool_name" {
  description = "Name of libvirt storage pool to create for managing volumes."
  type        = string
  default     = "linux-from-scratch"
}

variable "pool_path" {
  description = "The storage pool path where the directory will be created."
  type        = string
  default     = "/var/lib/libvirt/images"
}

variable "ssh_public_key" {
  description = "SSH public key for passwordless connection to host post boot."
  type        = string
  default     = null
}

variable "base_image_name" {
  type       = string
  default    = "base"
}

variable "base_image" {
  description = "Location of image to base overlay image on, supports downloading via URL."
  type       = string
  default    = null
}

variable "overlay_image_name" {
  type       = string
  default    = "overlay"
}

variable "overlay_image_size" {
  description = "Size of overlay image (GiB)"
  type        = number
  default     = 20
}

variable "lfs_disk_name" {
  type        = string
  default     = "lfs"
}

variable "lfs_disk_size" {
  description = "Size of lfs disk (GiB)"
  type        = number
  default     = 30
}

variable "vm_name" {
  type        = string
  default     = "linux-from-scratch"
}

variable "vm_memory" {
  description = "Size of vm memory (GiB)"
  type        = number
  default     = 8
}

variable "vm_vcpu" {
  description = "Number of CPU cores"
  type        = number
  default     = 4
}

variable "vm_use_uefi" {
  description = "Boot via UEFI or BIOS, defaults to UEFI"
  type        = bool
  default     = true
}
