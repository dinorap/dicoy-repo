# DiCoy / VCAM — Sileo repo (GitHub Pages)

Repo tĩnh để cài **VCAM (`com.dicoy.dicoy`)** lên iPhone 7 đã jailbreak
(rootless, iOS 15+) qua Sileo. Không cần server, không cần `.exe`.

## Nội dung

| Tệp | Vai trò |
|---|---|
| `Packages`, `Packages.gz`, `Packages.bz2` | Chỉ mục gói cho Sileo/APT |
| `Release` | Metadata + SHA256 của chỉ mục |
| `debs/` | Gói `.deb` (VCAM + libSandy) |
| `index.html` | Trang "Bắt đầu" + link tải công cụ chính thức |
| `new-release.sh` | Sinh lại `Packages`/`Release` sau khi thêm `.deb` |
| `QUY-TRINH-TU-DAU.md` | **Quy trình từ số 0 cho người mới** (chưa jailbreak → dùng) |
| `HUONG-DAN-CHO-NGUOI-NHAN.md` | Hướng dẫn nhanh cho người đã có máy jailbreak |
| `CREDITS.md` | Nguồn gốc, tác giả, giấy phép các công cụ |
| `RELEASES.md` | Cách đưa 2 file lớn lên GitHub Releases |
| `setup-github.sh` | **Một lệnh**: tạo repo + push + Release + bật Pages |

## Setup một lệnh (khuyến nghị)

Cần `gh` CLI (`brew install gh && gh auth login`). Chuẩn bị thư mục chứa 2 file
lớn (TrollRestore zip, Dopamine ipa) rồi:

```sh
TOOLS_DIR=/đường/dẫn/tới/thư-mục ./setup-github.sh dicoy-repo public
```

Script sẽ: tạo repo public → push → tạo Release `tools-v1` + upload 2 file lớn
→ bật GitHub Pages. Xong, mở `https://<bạn>.github.io/dicoy-repo/`.

> **Public vs private:** bản phát cho người khác phải là **public** — GitHub
> Pages công khai và file Release tải được **không cần đăng nhập**. Repo
> private sẽ chặn người nhận.

## Đưa lên GitHub Pages (thủ công, một lần)

```sh
cd dicoy-repo
git init
git add .
git commit -m "VCAM Sileo repo"
git branch -M main
git remote add origin https://github.com/<TÊN-BẠN>/dicoy-repo.git
git push -u origin main
```

Trên GitHub: **Settings → Pages → Build and deployment**
→ Source: *Deploy from a branch* → Branch: `main` / `/ (root)` → Save.

Sau ~1 phút, URL nguồn Sileo là:

```
https://<TÊN-BẠN>.github.io/dicoy-repo/
```

> Nếu đặt tên repo là `<TÊN-BẠN>.github.io` thì URL là `https://<TÊN-BẠN>.github.io/`.

## Bản gộp — tải đủ mọi thứ (~110 MB)

Repo có sẵn `tools/` chứa **TrollRestore + Dopamine**, nên người nhận chỉ mở
1 trang là tải được tất cả, không cần tạo Release, không phụ thuộc link ngoài.

| Tệp | Kích thước |
|---|---|
| `tools/TrollRestore-1.0-macos-arm64.zip` | 50 MB |
| `tools/Dopamine-3.0.12.ipa` | 55 MB |

`index.html` tự kiểm tra: nếu `tools/<file>` có sẵn thì link trực tiếp, nếu không
thì rơi về Release (`RELEASES.md`). Nên **cả hai kiểu đều chạy**.

- Chất lượng VCAM **không đổi** — `.deb` trong `debs/` là file gốc, cùng SHA256.
- File đều **dưới 100 MB** (giới hạn cứng của GitHub), push bình thường.
- Muốn repo nhẹ lại: xoá 2 file trong `tools/` và làm theo `RELEASES.md`.

## Cập nhật bản mới (quy trình)

1. Build `.deb` mới (xem `tools/DiCoy`), tăng `Version` trong `control`.
2. Copy `.deb` vào `debs/`.
3. Chạy lại chỉ mục:
   ```sh
   ./new-release.sh
   ```
4. `git add -A && git commit -m "local25" && git push`.
5. Trên iPhone: Sileo → nguồn này → **Refresh** → cập nhật.

`new-release.sh` tự chạy `dpkg-scanpackages`, nén `Packages`, và sinh `Release`
với SHA256 đúng. Không sửa tay `Packages`/`Release`.

## Bản đang phát

- `com.dicoy.dicoy` **1.2.3+local24** — bản hiện tại trong `Packages`.
  Có thêm filter `com.demaecan.DemaecanDriver` (chưa kiểm chứng đầy đủ).
- `com.dicoy.dicoy` **1.2.3+local23** — bản đã kiểm chứng, nằm trong `debs/`
  nhưng **không** nằm trong `Packages` (để rollback thủ công).

### Rollback về local23

Cài trực tiếp file trong `debs/` (qua Filza/Sileo file, hoặc `dpkg -i` qua SSH):

```
debs/com.dicoy.dicoy_1.2.3+local23_iphoneos-arm64.deb
```

Sau đó respring. Không cần xoá nguồn.

## Ghi chú phạm vi (quan trọng)

- VCAM chỉ nạp vào **Camera, BeautyCam, Google/Lens** (và Preferences cho nút
  dừng tất cả). `local24` có thêm **Demaecan** — đây là app có luồng xác thực
  danh tính/liveness. Bàn giao gốc ghi rõ **không dùng cho xác thực danh tính**;
  nếu phát hành cho người khác, cân nhắc bỏ Demaecan khỏi filter.
- Chỉ dùng trên thiết bị **của bạn hoặc được phép**. Không dùng để giả mạo
  danh tính, liveness hay bất kỳ luồng KYC nào.
- Không kèm khoá SSH, pairing hay mật khẩu trong repo này.
