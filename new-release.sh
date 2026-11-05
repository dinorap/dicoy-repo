#!/usr/bin/env bash
# new-release.sh — sinh lại Packages / Packages.gz / Packages.bz2 / Release
# Chạy trong thư mục gốc repo, sau khi thêm .deb vào debs/.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

command -v dpkg-scanpackages >/dev/null || { echo "Thiếu dpkg-scanpackages (brew install dpkg)"; exit 1; }
[ -d debs ] || { echo "Không thấy thư mục debs/"; exit 1; }

# Chỉ mục (bản mới nhất của mỗi gói được chọn)
dpkg-scanpackages debs /dev/null > Packages 2>/dev/null
gzip -9 -c Packages > Packages.gz
bzip2 -9 -c Packages > Packages.bz2

# Release + SHA256
{
  echo "Origin: DiCoy Local"
  echo "Label: DiCoy Local"
  echo "Suite: stable"
  echo "Version: 1.0"
  echo "Codename: ios"
  echo "Architectures: iphoneos-arm64"
  echo "Components: main"
  echo "Description: VCAM local builds for iPhone 7 / iOS 15 (rootless)"
  echo "Date: $(LC_ALL=C date -u '+%a, %d %b %Y %H:%M:%S GMT')"
  echo "SHA256:"
  for f in Packages Packages.gz Packages.bz2; do
    printf " %s %s %s\n" "$(sha256sum "$f" | cut -d' ' -f1)" "$(wc -c < "$f" | tr -d ' ')" "$f"
  done
} > Release

echo "Đã sinh lại chỉ mục:"
grep -E '^Package:|^Version:' Packages | paste - - | sed 's/^/  /'
echo "Xong. Giờ: git add -A && git commit -m 'release' && git push"
