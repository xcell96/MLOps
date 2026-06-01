terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.7.6"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_pool" "vm_pool" {
  name = "vm_pool"
  type = "dir"
  path = "/var/lib/libvirt/vm_pool"
}

resource "libvirt_volume" "rocky_base" {
  name   = "rocky-base.qcow2"
  pool   = libvirt_pool.vm_pool.name
  source = "/var/lib/libvirt/images/base/rocky-base.qcow2"
}

resource "libvirt_volume" "rocky_disk" {
  name           = "rocky-vm.qcow2"
  pool           = libvirt_pool.vm_pool.name
  base_volume_id = libvirt_volume.rocky_base.id
  size           = 40 * 1024 * 1024 * 1024
}

resource "libvirt_cloudinit_disk" "init" {
  name = "rocky-init.iso"
  pool = libvirt_pool.vm_pool.name

  user_data = <<EOF
#cloud-config
users:
  - name: root
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL9AtQqc6nW8MSU8KxlE3a6MxfjcEK9p4AQuU3dkqBDH rocky-vm

ssh_pwauth: true

packages:
  - qemu-guest-agent

runcmd:
  - systemctl enable --now qemu-guest-agent
EOF

  meta_data = <<EOF
instance-id: llm-rocky
local-hostname: llm-rocky
EOF
}

resource "libvirt_domain" "vm" {
  name   = "llm-rocky"
  memory = 4096
  vcpu   = 4

  cpu {
    mode = "host-passthrough"
  }

  disk {
    volume_id = libvirt_volume.rocky_disk.id
  }

  cloudinit = libvirt_cloudinit_disk.init.id

  network_interface {
    network_name    = "default"
    wait_for_lease  = true
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type        = "spice"
    listen_type = "none"
  }
}

output "vm_ip" {
  value = try(libvirt_domain.vm.network_interface[0].addresses[0], "not yet assigned")
}

resource "local_file" "inventory" {
  content = templatefile("${path.module}/inventory.tpl", {
    ip = try(libvirt_domain.vm.network_interface[0].addresses[0], "")
  })
  filename        = "${path.module}/../ansible/inventory.ini"
  depends_on      = [libvirt_domain.vm]
}
