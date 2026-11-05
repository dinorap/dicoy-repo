#!/usr/bin/env bash
# install-vcam-macos.sh
#
# TỰ ĐỘNG HOÁ (CHƯA TEST TRÊN MÁY THẬT):
#   1. palera1n rootless (iPhone 7 = checkm8) để jailbreak
#   2. SSH vào máy, copy libSandy + VCAM .deb
#   3. dpkg -i, respring
#
# CHỈ dùng khi bạn hiểu rõ. Đây là scaffolding, KHÔNG phải bản phát hành
# đã kiểm chứng. Đường chính vẫn là repo Sileo (xem HUONG-DAN-CHO-NGUOI-NHAN.md).
set -euo pipefail

DEB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/debs"
[ -d "$DEB_DIR" ] || { echo "Không thấy debs/"; exit 1; }

echo "== VCAM one-shot installer (Mac/Linux) =="
echo "Thiết bị phải ở trạng thái DFU/đã kết nối. iPhone 7 chỉ hỗ trợ checkm8."
echo

# 1. Jailbreak bằng palera1n (rootless)
if command -v palera1n >/dev/null; then
  read -r -p "Chạy palera1n -l để jailbreak rootless? [y/N] " a
  case "$a" in
    y|Y) palera1n -l ;;
    *) echo "Bỏ qua bước jailbreak." ;;
  esac
else
  echo "Chưa có palera1n. Cài: brew install palera1n/palera1n/palera1n"
fi

echo
echo "Sau khi jailbreak, SSH thường bật port 22 (root/mobile, mật khẩu mặc định"
echo "của bản jailbreak). Nhập thông tin kết nối:"
read -r -p "IP iPhone (vd 192.168.1.50): " IP
read -r -p "User SSH [root]: " USER
USER="${USER:-root}"
read -r -s -p "Mật khẩu SSH: " PASS
echo

SSH_OPTS=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10)
export SSHPASS="$PASS"
command -v sshpass >/dev/null || {
  echo "Cần sshpass (brew install sshpass). Hoặc copy tay bằng scp."; exit 1; }

# 2. Copy + cài
for deb in "$DEB_DIR"/*.deb; do
  echo "→ copy $(basename "$deb")"
  sshpass -e scp "${SSH_OPTS[@]}" "$deb" "$USER@$IP:/var/mobile/vcam-install.deb"
  echo "→ dpkg -i"
  sshpass -e ssh "${SSH_OPTS[@]}" "$USER@$IP" \
    "sudo dpkg -i /var/mobile/vcam-install.deb || dpkg -i /var/mobile/vcam-install.deb"
done

# 3. Respring
echo "→ respring"
sshpass -e ssh "${SSH_OPTS[@]}" "$USER@$IP" \
  "sudo killall SpringBoard || killall SpringBoard || true"

echo "Xong. Mở Camera và bấm đồng thời nút tăng âm lượng + nút nguồn."
