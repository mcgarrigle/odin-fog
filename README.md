
Prerequisites
```
$ sudo dnf install libvirt guestfs-tools-1.54.0 virt-install
```
Example guest configuration
```
export HOST="tt"
export POOL="filesystems"
export IMAGE="rocky10.qcow2"
export OS="rocky9"
export CPUS="2"
export MEMORY="4096"

export ROOT_DEVICE="/dev/sda4"
export ROOT_SIZE="20G"

export NETWORK="default"
export NETWORK_DEVICE="enp1s0"
export IP_ADDRESS="192.168.1.24"
export GATEWAY_ADDRESS="192.168.1.254"
export DNS_SERVER="1.1.1.1"

export SSH_PUBLIC_KEY="$(cat ${HOME}/.ssh/id_rsa.pub)"
```
Guest Definition Variables

| Variable        | Purpose   |
| --------------- | --------- |
| HOST            | Guest hostname |
| POOL            | libvirt pool to store VM disk default: 'filesystems' |
| IMAGE           | Image file stored in {FOG_HOME}/images |
| MACHINE         | Emulated machine (use 'qemu-kvm -machine help' to find value to use; default 'q35')
| OS              | osinfo (use 'osinfo-query os' to find a value to use) |
| CPUS            | Number of vcpu to allocate |
| MEMORY          | Memory allocated (in MiB) |
| BOOT            | Boot order (default 'uefi') |
| -               |           |
| ROOT_DEVICE     | / device to expand (use virt-df to find root FS) |
| ROOT_SIZE       | Size to extend image by, the root FS will be expanded |
| -               |           |
| NETWORK         | libvirt network to attach to |
| NETWORK_DEVICE  | eth0 or enp0s1 or other |
| BOOTPROTO       | 'static' (default) or 'dhcp' |
| IP_ADDRESS      | Static IP address |
| GATEWAY_ADDRESS | Default route |
| DNS_SERVER      | DNS server |
| -               |           |
| USER            | Username to inject into VM |
| SSH_PUBLIC_KEY  | SSH public key to inject into ${USER} |

Operational Variables

| Variable        | Purpose   |
| --------------- | --------- |
| CONSOLE         | If 1 will start a console |
