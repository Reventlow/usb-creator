# usb-creator

> Create verified bootable USB installers for Linux and BSD.
> Downloads are checksum- and GPG-verified; system disks are never writable.
> More information: <https://github.com/Reventlow/usb-creator>.

- Start the interactive wizard (pick desktop/server, system, and device):

`usb-creator`

- List candidate USB devices:

`usb-creator list`

- List all supported systems:

`usb-creator distros`

- Show what "latest" resolves to for a system, including its verification:

`usb-creator info {{arch}}`

- Download and verify an image into the cache without writing it:

`usb-creator download {{fedora}}`

- Write the latest release of a system to a USB device:

`usb-creator write --distro {{debian}} --device {{/dev/sdb}}`

- Write a local image file to a USB device:

`usb-creator write --iso {{path/to/image.iso}} --device {{/dev/sdb}}`

- Write non-interactively for scripts (still refuses system disks):

`usb-creator write --distro {{ubuntu-server}} --device {{/dev/sdb}} --yes`
