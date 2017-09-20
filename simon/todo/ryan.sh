#!/bin/bash

# Copyright 2015 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -e
umask 022

DST_DRIVE="/dev/mmcblk1"
DST_FACTORY_KERNEL_PART=2
DST_FACTORY_PART=3
DST_RELEASE_KERNEL_PART=4
DST_STATE_PART=1

reload_partitions() {
  # Some devices, for example NVMe, may need extra time to update block device
  # files via udev. We should do sync, partprobe, and then wait until partition
  # device files appear again.
  local drive="$1"
  log "Reloading partition table changes..."
  sync

  # Reference: src/platform2/installer/chromeos-install#reload_partitions
  udevadm settle || true  # Netboot environment may not have udev.
  blockdev --rereadpt "${drive}"
}

disable_release_partition() {
  # Release image is not allowed to boot unless the factory test is passed
  # otherwise the wipe and final verification can be skipped.
  if ! cgpt add -i "${DST_RELEASE_KERNEL_PART}" -P 0 -T 0 -S 0 "${DST_DRIVE}"
  then
    # Destroy kernels otherwise the system is still bootable.
    dst="/dev/mmcblk1p4"
    dd if=/dev/zero of="${dst}" bs=1M count=1
    dst="/dev/mmcblk1p3"
    die "Failed to lock release image. Destroy all kernels."
  fi
  # cgpt changed partition table, so we have to make sure it's notified.
  reload_partitions "/dev/mmcblk1"
}

run_postinst() {
  local install_dev="$1"
  local mount_point="$(mktemp -d)"
  local result=0

  mount -t ext2 -o ro "${install_dev}" "${mount_point}"
  IS_FACTORY_INSTALL=1 "${mount_point}"/postinst \
    "${install_dev}" 2>&1 || result="$?"

  umount "${install_dev}" || true
  rmdir "${mount_point}" || true
  return ${result}
}

stateful_postinst() {
  local stateful_dev="$1"
  local mount_point="$(mktemp -d)"

  mount "${stateful_dev}" "${mount_point}"
#  mkdir -p "$(dirname "${output_file}")"

  # Update lsb-factory on stateful partition.
  local lsb_factory="${mount_point}/dev_image/etc/lsb-factory"

  log "Clone lsb-factory to stateful partition."
    cat "/usr/local/etc/lsb-factory" >>"${lsb_factory}"

  umount "${mount_point}" || true
  rmdir "${mount_point}" || true
}


factory_install_cros_payload() {
#  cros_payload install "${json_url}" "${DST_DRIVE}" test_image release_image
	/usr/local/factory/bin/cros_payload install http://101.1.2.4:8085/static/coral.json /dev/mmcblk1 test_image
  run_postinst "/dev/mmcblk1p3"
  stateful_postinst "/dev/mmcblk1p1"
}
factory_install_cros_payload
