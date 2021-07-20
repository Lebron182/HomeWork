#!/user/bin/bash
clear

echo "PC architecture:"
arch

echo "CPU info:"
cat /proc/cpuinfo

echo "Memory info:"
cat /proc/meminfo

echo "PCI info:"
lspci -tv
