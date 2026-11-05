# Hướng dẫn cho người nhận máy — cài VCAM lên iPhone 7

Bạn nhận được một iPhone 7 đã **jailbreak** (Dopamine, rootless) + Sileo.
Mục tiêu: cài VCAM trong **3 bước**, không cần máy tính.

> Nếu máy **chưa jailbreak**: làm mục A trước. Jailbreak là bước buộc phải làm,
> không có cách "tải 1 file là xong" cho máy chưa jailbreak.

## A. Nếu máy chưa jailbreak (làm 1 lần)

iPhone 7 dùng chip A10 (checkm8) nên có 2 cách:

1. **Trên máy (khuyến nghị)** — qua TrollStore:
   - Cài **TrollStore** (TrollInstallerX / TrollRestore).
   - Cài **Dopamine** (.ipa) qua TrollStore.
   - Mở **Dopamine → Jailbreak**, chờ máy tải lại giao diện.
   - Mở **Sileo** để xác nhận jailbreak đã bật.

2. **Qua máy tính** — palera1n (Mac/Linux), rootless:
   ```sh
   palera1n -l
   ```
   (chỉ làm nếu bạn quen; Dopamine là cách chính trong bộ này.)

## B. Thêm nguồn VCAM vào Sileo

1. Mở **Sileo**.
2. Tab **Sources** → dấu **+** (góc trên).
3. Dán URL:
   ```
   https://<TÊN-BẠN>.github.io/dicoy-repo/
   ```
4. **Add Source** → chờ tải xong.

## C. Cài VCAM

1. Trong nguồn vừa thêm, mở gói **VCAM**.
2. Bấm **Get / Install**.
3. Sileo tự cài kèm **libSandy** (dependency). Nếu hỏi, chọn **Confirm**.
4. Sau khi cài xong: **Respring** (hoặc khởi động lại jailbreak).
5. Mở **Camera** → **bấm đồng thời nút tăng âm lượng + nút nguồn** → menu hiện.

## D. Dùng nhanh

- **Bật VCAM:** mở app (Camera/BeautyCam/Google) → bấm đồng thời **nút tăng âm lượng + nút nguồn**
  → *Chọn video…* → chọn clip → chọn **5 hoặc 10 phút**.
- **Tắt riêng app:** bấm lại tổ hợp → *Dừng ngay*.
- **Tắt tất cả:** Cài đặt → **VCAM** → *Tắt tất cả phiên VCAM*.
- Hết thời gian đã chọn, phiên tự tắt và trở về camera thật.

## E. Nếu có sự cố

| Hiện tượng | Cách xử lý |
|---|---|
| Bấm tổ hợp không hiện menu | Kiểm tra Dopamine đang bật; respring; mở lại app |
| Không thấy gói trong Sileo | Bấm **Refresh** nguồn; kiểm tra URL đúng `.../` |
| Cài lỗi thiếu `mobilesubstrate` | Đảm bảo ElleKit/Substrate đã có (Dopamine lo sẵn) |
| Muốn quay lại bản cũ | Cài `debs/...local23....deb` thủ công rồi respring |

## F. Ghi chú

- VCAM thay camera thật bằng clip bạn chọn — chỉ dùng cho mục đích hợp pháp
  trên thiết bị của bạn.
- Không dùng cho xác thực danh tính / liveness / KYC.
