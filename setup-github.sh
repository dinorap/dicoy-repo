#!/usr/bin/env bash
# setup-github.sh — đưa repo lên GitHub + tạo Release + bật Pages, một lệnh.
#
# Dùng:
#   ./setup-github.sh [tên-repo] [public|private]
#
# Để upload 2 file lớn vào Release, trỏ TOOLS_DIR tới thư mục chứa:
#   TrollRestore-1.0-macos-arm64.zip
#   Dopamine-3.0.12.ipa
#   TOOLS_DIR=/path/to/tools ./setup-github.sh
#
# Yêu cầu: gh CLI đã đăng nhập (brew install gh && gh auth login)
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

REPO_NAME="${1:-dicoy-repo}"
VISIBILITY="${2:-public}"
TOOLS_DIR="${TOOLS_DIR:-}"

command -v gh >/dev/null 2>&1 || {
  echo "Thiếu gh CLI. Cài: brew install gh && gh auth login" >&2; exit 1; }
gh auth status >/dev/null 2>&1 || {
  echo "Chưa đăng nhập gh. Chạy: gh auth login" >&2; exit 1; }

if [[ "$VISIBILITY" != "public" && "$VISIBILITY" != "private" ]]; then
  echo "Tham số 2 phải là public hoặc private" >&2; exit 1
fi
if [[ "$VISIBILITY" == "private" ]]; then
  echo "CẢNH BÁO: repo private → GitHub Pages không công khai và Release"
  echo "yêu cầu đăng nhập. Người nhận sẽ KHÔNG tải được nếu không có quyền." >&2
fi

[ -d .git ] || git init -q
git add -A
git commit -qm "VCAM repo" 2>/dev/null || true

OWNER=$(gh api user -q .login)

if gh repo view "$OWNER/$REPO_NAME" >/dev/null 2>&1; then
  echo "→ Repo đã tồn tại: $OWNER/$REPO_NAME"
  git remote get-url origin >/dev/null 2>&1 || \
    git remote add origin "https://github.com/$OWNER/$REPO_NAME.git"
else
  echo "→ Tạo repo $OWNER/$REPO_NAME ($VISIBILITY)"
  gh repo create "$OWNER/$REPO_NAME" "--$VISIBILITY" \
    --source=. --remote=origin --push
fi

git branch -M main
git push -u origin main --force

# ---- Release (2 file lớn) ----
if [[ -n "$TOOLS_DIR" \
      && -f "$TOOLS_DIR/TrollRestore-1.0-macos-arm64.zip" \
      && -f "$TOOLS_DIR/Dopamine-3.0.12.ipa" ]]; then
  if gh release view tools-v1 >/dev/null 2>&1; then
    echo "→ Release tools-v1 đã có, bỏ qua"
  else
    echo "→ Tạo Release tools-v1 + upload 2 file lớn"
    gh release create tools-v1 \
      --title "VCAM tools v1" \
      --notes "TrollRestore 1.0 + Dopamine 3.0.12" \
      "$TOOLS_DIR/TrollRestore-1.0-macos-arm64.zip" \
      "$TOOLS_DIR/Dopamine-3.0.12.ipa"
  fi
else
  echo "→ Bỏ qua Release (chưa set TOOLS_DIR). Xem RELEASES.md."
fi

# ---- Pages ----
if echo '{"source":{"branch":"main","path":"/"}}' \
   | gh api -X POST "repos/$OWNER/$REPO_NAME/pages" --input - >/dev/null 2>&1; then
  echo "→ Đã bật GitHub Pages"
else
  echo "→ Pages: có thể đã bật. Kiểm tra Settings → Pages (main / root)."
fi

echo
echo "Xong."
echo "  Repo : https://github.com/$OWNER/$REPO_NAME"
echo "  Pages: https://$OWNER.github.io/$REPO_NAME/"
echo "  (chờ ~1 phút để Pages build lần đầu)"
