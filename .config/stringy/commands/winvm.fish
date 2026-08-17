
if command -q qemu-system-x86_64
    set -g WINVM_DIR $HOME/.var/qemu/windows
    set -g WINVM_DISK $WINVM_DIR/windows.qcow2
    set -g WINVM_DISK_SIZE 60G
    set -g WINVM_RAM 8192
    set -g WINVM_CPUS 4

    function winvm --description 'Manage a Windows QEMU VM for firmware updates etc.'
        argparse 'h/help' -- $argv; or return

        if set -q _flag_help; or test (count $argv) -eq 0
            echo "Usage: winvm <command> [options]"
            echo ""
            echo "Commands:"
            echo "  download        Download a Windows 11 evaluation ISO"
            echo "  create <iso>    Create VM disk and boot from Windows ISO for installation"
            echo "  start           Start the VM (after Windows is installed)"
            echo "  usb             Start the VM with Dell monitor USB passthrough"
            echo "  stop            Stop the VM gracefully"
            echo "  kill            Force kill the VM"
            echo "  status          Show VM status"
            echo "  delete          Delete the VM disk"
            echo ""
            echo "The VM uses SPICE display on port 5930. Connect with:"
            echo "  remote-viewer spice://localhost:5930"
            echo "  or: virt-viewer spice://localhost:5930"
            echo ""
            echo "Files stored in: $WINVM_DIR"
            return 0
        end

        switch $argv[1]
            case download
                __winvm_download
            case create
                __winvm_create $argv[2..]
            case start
                __winvm_start
            case usb
                __winvm_start_usb
            case stop
                __winvm_stop
            case kill
                __winvm_kill
            case status
                __winvm_status
            case delete
                __winvm_delete
            case '*'
                echo >&2 "Unknown command: $argv[1]"
                winvm --help
                return 1
        end
    end

    function __winvm_download --description 'Download Windows 11 evaluation ISO'
        mkdir -p $WINVM_DIR

        set -l iso $WINVM_DIR/windows11.iso

        if test -f $iso
            echo "ISO already exists: $iso"
            echo "Delete it first if you want to re-download."
            return 0
        end

        # Windows 11 Enterprise Evaluation (90-day, no key needed)
        # from Microsoft Evaluation Centre
        set -l url "https://software-static.download.prss.microsoft.com/dbazure/888969d5-f34g-4e03-ac9d-1f9786c66749/26100.1742.240906-0331.ge_release_svc_refresh_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_en-gb.iso"

        echo "Downloading Windows 11 Enterprise Evaluation ISO (~6GB)..."
        echo "This is a 90-day evaluation, no product key required."
        echo ""
        echo "Saving to: $iso"
        echo ""

        curl -L -o $iso --progress-bar "$url"

        if test $status -eq 0; and test -f $iso
            echo ""
            echo "Download complete: $iso"
            echo "Now run: winvm create $iso"
        else
            echo >&2 "Download failed."
            rm -f $iso
            echo >&2 ""
            echo >&2 "The direct download URL may have changed."
            echo >&2 "Visit https://www.microsoft.com/en-gb/evalcenter/evaluate-windows-11-enterprise"
            echo >&2 "and download the ISO manually to: $iso"
            return 1
        end
    end

    function __winvm_create --description 'Create and boot VM from ISO'
        set -l iso
        if test (count $argv) -ge 1
            set iso $argv[1]
        else if test -f $WINVM_DIR/windows11.iso
            set iso $WINVM_DIR/windows11.iso
        else
            echo >&2 "Usage: winvm create [path-to-windows.iso]"
            echo >&2 ""
            echo >&2 "No ISO specified and none found at $WINVM_DIR/windows11.iso"
            echo >&2 "Run 'winvm download' first, or provide a path to an ISO."
            return 1
        end

        if not test -f "$iso"
            echo >&2 "ISO not found: $iso"
            return 1
        end

        mkdir -p $WINVM_DIR

        if not test -f $WINVM_DISK
            echo "Creating VM disk ($WINVM_DISK_SIZE)..."
            qemu-img create -f qcow2 $WINVM_DISK $WINVM_DISK_SIZE
        end

        # Download VirtIO drivers if not present
        set -l virtio_iso $WINVM_DIR/virtio-win.iso
        if not test -f $virtio_iso
            echo "Downloading VirtIO drivers ISO..."
            curl -L -o $virtio_iso \
                https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso
        end

        # Create UEFI vars copy if needed (plain OVMF, no secure boot)
        set -l ovmf_code /usr/share/edk2/ovmf/OVMF_CODE.fd
        set -l ovmf_vars_template /usr/share/edk2/ovmf/OVMF_VARS.fd
        set -l ovmf_vars $WINVM_DIR/OVMF_VARS.fd

        if not test -f $ovmf_code
            set ovmf_code /usr/share/OVMF/OVMF_CODE.fd
            set ovmf_vars_template /usr/share/OVMF/OVMF_VARS.fd
        end

        if not test -f $ovmf_code
            echo >&2 "OVMF not found. Install it with: sudo dnf install edk2-ovmf"
            return 1
        end

        if not test -f $ovmf_vars
            cp $ovmf_vars_template $ovmf_vars
        end

        echo "Starting VM for Windows installation..."
        echo "Connect with: remote-viewer spice://localhost:5930"

        sudo qemu-system-x86_64 \
            -machine q35,accel=kvm \
            -cpu host \
            -smp $WINVM_CPUS \
            -m $WINVM_RAM \
            -drive if=pflash,format=raw,readonly=on,file=$ovmf_code \
            -drive if=pflash,format=raw,file=$ovmf_vars \
            -drive file="$iso",media=cdrom,index=0 \
            -drive file=$virtio_iso,media=cdrom,index=1 \
            -drive file=$WINVM_DISK,format=qcow2,if=virtio \
            -boot order=d,menu=on \
            -device qemu-xhci \
            -device usb-tablet \
            -spice port=5930,disable-ticketing=on \
            -device virtio-vga \
            -device ich9-intel-hda -device hda-duplex \
            -netdev user,id=net0 \
            -device virtio-net-pci,netdev=net0,romfile= \
            -pidfile $WINVM_DIR/pidfile \
            -daemonize
    end

    function __winvm_start --description 'Start the VM'
        if not test -f $WINVM_DISK
            echo >&2 "VM disk not found. Run: winvm create <iso>"
            return 1
        end

        if __winvm_running
            echo "VM is already running."
            return 1
        end

        set -l ovmf_code /usr/share/edk2/ovmf/OVMF_CODE.fd
        set -l ovmf_vars $WINVM_DIR/OVMF_VARS.fd

        if not test -f $ovmf_code
            set ovmf_code /usr/share/OVMF/OVMF_CODE.fd
        end

        echo "Starting VM..."
        echo "Connect with: remote-viewer spice://localhost:5930"

        sudo qemu-system-x86_64 \
            -machine q35,accel=kvm \
            -cpu host \
            -smp $WINVM_CPUS \
            -m $WINVM_RAM \
            -drive if=pflash,format=raw,readonly=on,file=$ovmf_code \
            -drive if=pflash,format=raw,file=$ovmf_vars \
            -drive file=$WINVM_DISK,format=qcow2,if=virtio \
            -boot c \
            -drive file=$WINVM_DIR/virtio-win.iso,media=cdrom,readonly=on \
            -device qemu-xhci \
            -device usb-tablet \
            -spice port=5930,disable-ticketing=on \
            -device virtio-vga \
            -device ich9-intel-hda -device hda-duplex \
            -netdev user,id=net0 \
            -device virtio-net-pci,netdev=net0,romfile= \
            -pidfile $WINVM_DIR/pidfile \
            -daemonize
    end

    function __winvm_start_usb --description 'Start VM with Dell monitor USB passthrough'
        if not test -f $WINVM_DISK
            echo >&2 "VM disk not found. Run: winvm create <iso>"
            return 1
        end

        if __winvm_running
            echo "VM is already running."
            return 1
        end

        set -l ovmf_code /usr/share/edk2/ovmf/OVMF_CODE.fd
        set -l ovmf_vars $WINVM_DIR/OVMF_VARS.fd

        if not test -f $ovmf_code
            set ovmf_code /usr/share/OVMF/OVMF_CODE.fd
        end

        echo "Starting VM with Dell monitor USB hub passthrough..."
        echo "Connect with: remote-viewer spice://localhost:5930"
        echo ""
        echo "The Microchip USB4206 hub (0424:4206) will be passed through."
        echo "Dell Display and Peripheral Manager should see the monitor."

        sudo qemu-system-x86_64 \
            -machine q35,accel=kvm \
            -cpu host \
            -smp $WINVM_CPUS \
            -m $WINVM_RAM \
            -drive if=pflash,format=raw,readonly=on,file=$ovmf_code \
            -drive if=pflash,format=raw,file=$ovmf_vars \
            -drive file=$WINVM_DISK,format=qcow2,if=virtio \
            -boot c \
            -drive file=$WINVM_DIR/virtio-win.iso,media=cdrom,readonly=on \
            -device qemu-xhci \
            -device usb-tablet \
            -device usb-host,vendorid=0x0424,productid=0x4206 \
            -spice port=5930,disable-ticketing=on \
            -device virtio-vga \
            -device ich9-intel-hda -device hda-duplex \
            -netdev user,id=net0 \
            -device virtio-net-pci,netdev=net0,romfile= \
            -pidfile $WINVM_DIR/pidfile \
            -daemonize
    end

    function __winvm_stop --description 'Stop the VM gracefully'
        if not __winvm_running
            echo "VM is not running."
            return 1
        end

        echo "Sending shutdown signal..."
        set -l pid (cat $WINVM_DIR/pidfile 2>/dev/null)
        sudo kill -TERM $pid 2>/dev/null
        echo "VM should shut down shortly."
    end

    function __winvm_kill --description 'Force kill the VM'
        if not __winvm_running
            echo "VM is not running."
            return 1
        end

        set -l pid (cat $WINVM_DIR/pidfile 2>/dev/null)
        sudo kill -9 $pid 2>/dev/null
        rm -f $WINVM_DIR/pidfile
        echo "VM killed."
    end

    function __winvm_status --description 'Show VM status'
        if __winvm_running
            set -l pid (cat $WINVM_DIR/pidfile 2>/dev/null)
            echo "VM is running (PID: $pid)"
        else
            echo "VM is not running."
        end

        if test -f $WINVM_DISK
            echo "Disk: $WINVM_DISK"
            qemu-img info $WINVM_DISK 2>/dev/null | grep -E "virtual size|disk size"
        else
            echo "No VM disk found."
        end
    end

    function __winvm_delete --description 'Delete the VM'
        if __winvm_running
            echo >&2 "VM is still running. Stop it first."
            return 1
        end

        read -P "Delete VM disk and all data? [y/N] " confirm
        if test "$confirm" = y; or test "$confirm" = Y
            rm -rf $WINVM_DIR
            echo "VM deleted."
        else
            echo "Cancelled."
        end
    end

    function __winvm_running --description 'Check if VM is running'
        if test -f $WINVM_DIR/pidfile
            set -l pid (cat $WINVM_DIR/pidfile 2>/dev/null)
            if test -n "$pid"; and test -d /proc/$pid
                return 0
            else
                # Stale pidfile
                rm -f $WINVM_DIR/pidfile
                return 1
            end
        end
        return 1
    end

    complete -x --command winvm --condition __fish_use_subcommand \
        --arguments "download" --description "Download Windows 11 evaluation ISO"
    complete -x --command winvm --condition __fish_use_subcommand \
        --arguments "create" --description "Create VM from Windows ISO"
    complete -x --command winvm --condition __fish_use_subcommand \
        --arguments "start" --description "Start the VM"
    complete -x --command winvm --condition __fish_use_subcommand \
        --arguments "usb" --description "Start with Dell USB passthrough"
    complete -x --command winvm --condition __fish_use_subcommand \
        --arguments "stop" --description "Stop the VM"
    complete -x --command winvm --condition __fish_use_subcommand \
        --arguments "kill" --description "Force kill the VM"
    complete -x --command winvm --condition __fish_use_subcommand \
        --arguments "status" --description "Show VM status"
    complete -x --command winvm --condition __fish_use_subcommand \
        --arguments "delete" --description "Delete the VM"

    complete -F --command winvm --condition '__fish_seen_subcommand_from create'
end
