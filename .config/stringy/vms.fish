set -g DEV_VM_NAME fedora
set -g DEV_DISK_URL 'https://download.fedoraproject.org/pub/fedora/linux/releases/38/Server/x86_64/images/Fedora-Server-KVM-38-1.6.x86_64.qcow2'

set -g DEV_VM_DIR $HOME/.var/qemu/$DEV_VM_NAME

function qemu-dev-vm-setup

    mkdir -p $DEV_VM_DIR

    if not test -f $DEV_VM_DIR/$DEV_VM_NAME.qcow2
        wget -O $DEV_VM_DIR/$DEV_VM_NAME.qcow2 $DISK_URL
        qemu-img resize $DEV_VM_DIR/$DEV_VM_NAME.qcow2 50G
    end

    sudo qemu-system-x86_64 -cpu host,-pdpe1gb -accel hvf -smp 6 -m 8192 \
        -hda $DEV_VM_DIR/$DEV_VM_NAME.qcow2 \
        -netdev user,id=net0 -nic vmnet-host -rtc base=localtime \
        -device virtio-net-pci,netdev=net0 \
        -display none -nographic \
        -pidfile $HOME/.var/qemu/pidfile

    echo "Waiting for system to come online..."

    if nc -zw 192.168.56.2 22 &>/dev/null
        echo "System up"
    else
        echo >&2 "Failed to connect"
    end
end

function qemu-dev-vm-provision
    if not test -f $DEV_VM_DIR/id_rsa
        ssh-keygen -t rsa -f $DEV_VM_DIR/id_rsa -N ''
    end

    ansible-playbook -i $HOME/.config/stringy/ansible/inventory/qemu.yml --ask-pass $HOME/.config/stringy/ansible/provision/provision.yml
end
