#!/bin/bash
# Must be run as root
if [[ $EUID -ne 0 ]]; then
  echo "run as root bro (sudo)"
  exit 1
fi

# Check if macchanger is installed
if ! command -v macchanger &> /dev/null; then
  echo "macchanger not found. Installing..."
  apt update && apt install -y macchanger
fi

echo "detecting network interfaces..."
echo "--------------------------------"

# Get interfaces except loopback
interfaces=($(ip -o link show | awk -F': ' '{print $2}' | grep -v lo))

# Check if interfaces exist
if [[ ${#interfaces[@]} -eq 0 ]]; then
  echo "no interfaces found"
  exit 1
fi

# Display interfaces
for i in "${!interfaces[@]}"; do
  echo "[$i] ${interfaces[$i]}"
done

echo
read -p "select interface number: " idx
iface=${interfaces[$idx]}

# Validate selection
if [[ -z "$iface" ]]; then
  echo "invalid selection"
  exit 1
fi

echo
echo "selected interface: $iface"
macchanger -s $iface

echo
echo "choose MAC change method:"
echo "[1] random MAC"
echo "[2] random MAC (same vendor)"
echo "[3] custom MAC"
echo
read -p "choice: " choice

# Bring interface down
ip link set $iface down

case $choice in
  1)
    macchanger -r $iface
    ;;
  2)
    macchanger -a $iface
    ;;
  3)
    read -p "enter custom MAC (XX:XX:XX:XX:XX:XX): " custom_mac
    macchanger -m $custom_mac $iface
    ;;
  *)
    echo "invalid choice"
    ip link set $iface up
    exit 1
    ;;
esac

# Bring interface up
ip link set $iface up

echo
echo "MAC address updated successfully!"
macchanger -s $iface