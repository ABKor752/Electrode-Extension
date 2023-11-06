#!/bin/bash
# Running setup as per README

if [ ! -d "Electrode-Extension" ] || [ ! -d "Electrode-Extension" ]
then
    echo "Electrode-Extension not found"
    exit 1
fi

if ! (uname -r | grep -q "5.8.0-050800-generic")
then
    wget https://raw.githubusercontent.com/pimlie/ubuntu-mainline-kernel.sh/master/ubuntu-mainline-kernel.sh
    sudo bash ubuntu-mainline-kernel.sh -i 5.8.0
    echo "Must load linux kernel version 5.8.0-050800-generic. Please run sudo reboot and rerun the script."
else
    echo "Linux kernel version 5.8.0-050800-generic found. Continuing..."
fi

sudo apt update
sudo apt install llvm clang gpg curl tar xz-utils make gcc flex bison libssl-dev libelf-dev protobuf-compiler pkg-config libunwind-dev libssl-dev libprotobuf-dev libevent-dev libgtest-dev

bash kernel-src-download.sh
bash kernel-src-prepare.sh

cd xdp-handler
make clean && make
cd ..
make clean && make PARANOID=0

sudo ifconfig ens1f1np1 mtu 3000 up
sudo ethtool -C ens1f1np1 adaptive-rx off adaptive-tx off rx-frames 1 rx-usecs 0  tx-frames 1 tx-usecs 0
sudo ethtool -C ens1f1np1 adaptive-rx off adaptive-tx off rx-frames 1 rx-usecs 0  tx-frames 1 tx-usecs 0
sudo ethtool -L ens1f1np1 combined 1
sudo service irqbalance stop
(let CPU=0; cd /sys/class/net/ens1f1np1/device/msi_irqs/;
    for IRQ in *; do
    echo $CPU | sudo tee /proc/irq/$IRQ/smp_affinity_list
    done)

echo "Setup almost done. Please add MAC addresses to xdp-handler/fast_user.c on line 281, then run the following:"
echo '[Client]\t  cd xdp-handler && make clean && make EXTRA_CFLAGS="-DTC_BROADCAST -DFAST_QUORUM_PRUNE -DFAST_REPLY"'
echo '[Replica idx]\t make clean && make CXXFLAGS="-DTC_BROADCAST -DFAST_QUORUM_PRUNE -DFAST_REPLY"'
echo '[Client]\t  sudo ./fast ens1f1np1'
echo '[Replica idx]\t sudo taskset -c 1 ./bench/replica -c config.txt -m vr -i {idx}'
echo '[Separate Client]\t ./bench/client -c config.txt -m vr -n 10000'



