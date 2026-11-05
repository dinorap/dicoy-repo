# Đưa 2 file lớn lên GitHub Releases

Repo giữ **nhẹ (~170 KB)**, còn 2 file nặng đặt ở **Releases** (asset tới 2 GB
mỗi file, không nằm trong git). `index.html` tự trỏ tới:

```
https://github.com/<owner>/<repo>/releases/latest/download/<tên-file>
```

`latest/download/...` luôn trỏ bản release mới nhất → không cần sửa link khi
ra bản mới.

---

## Cách 1 — Giao diện web (không cần cài gì)

1. Mở repo trên GitHub → tab **Releases** → **Draft a new release**.
2. **Choose a tag** → gõ `tools-v1` → **Create new tag**.
3. Tiêu đề: `VCAM tools v1`.
4. Kéo–thả 2 file (hoặc **Attach binaries**):
   - `TrollRestore-1.0-macos-arm64.zip` (50 MB)
   - `Dopamine-3.0.12.ipa` (55 MB)
5. Bấm **Publish release**.

Xong. Trang `index.html` sẽ tự có link tải.

---

## Cách 2 — `gh` CLI

```sh
brew install gh          # macOS
gh auth login            # đăng nhập một lần

gh release create tools-v1 \
  --title "VCAM tools v1" \
  --notes "TrollRestore 1.0 + Dopamine 3.0.12" \
  /đường/dẫn/TrollRestore-1.0-macos-arm64.zip \
  /đường/dẫn/Dopamine-3.0.12.ipa
```

Kiểm tra:

```sh
gh release view tools-v1
```

---

## Cập nhật bản mới

Asset của release **không sửa tại chỗ** được. Hai cách:

**A. Release mới (khuyến nghị):**

```sh
gh release create tools-v2 --title "VCAM tools v2" \
  --notes "Cập nhật Dopamine mới" \
  /đường/dẫn/Dopamine-mới.ipa
```

`index.html` đang dùng `latest/download/...` nên **tự trỏ bản v2** — không sửa gì.
Nhớ đặt **đúng tên file** (`Dopamine-3.0.12.ipa`, `TrollRestore-1.0-macos-arm64.zip`)
hoặc sửa tên trong `index.html`.

**B. Ghi đè asset cũ:**

```sh
gh release upload tools-v1 /đường/dẫn/Dopamine-3.0.12.ipa --clobber
```

---

## Giới hạn cần biết

| Mục | Giá trị |
|---|---|
| Kích thước mỗi asset | tối đa **2 GB** |
| Tổng dung lượng repo | khuyến nghị dưới vài GB (105 MB ở đây thoải mái) |
| Asset có sửa được? | Không sửa tại chỗ; phải upload lại (`--clobber`) hoặc release mới |
| Link ổn định? | Có — `/releases/latest/download/<file>` |

## Vì sao cách này tốt

- **Repo nhẹ**: git chỉ ~170 KB, push/clone tức thì.
- **Một chỗ tải**: người nhận chỉ mở 1 URL, không phải lùng nhiều site.
- **Không phụ thuộc link bên thứ ba** (khác với cách chỉ-link): file nằm ngay
  trong repo của bạn, không sợ upstream xoá.
- **Vẫn đúng giấy phép**: ghi nguồn trong `CREDITS.md`, giữ nguyên file gốc.

## Lưu ý

- Đây vẫn là **bản sao** công cụ của tác giả khác → ghi rõ nguồn/phiên bản.
- Nếu muốn **luôn mới nhất**, có thể để 2 nút này trỏ link chính thức thay vì
  release asset (đổi trong `index.html`).
- Không đưa khoá SSH, pairing, Apple ID hay mật khẩu vào release.
