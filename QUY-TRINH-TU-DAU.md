# QUY TRÌNH TỪ ĐẦU — cho người mới (máy tính + iPhone 7)

> Mục tiêu: từ một iPhone 7 **chưa jailbreak** → cài được **VCAM** → dùng được.
> Đọc hết Phần 0 trước khi bấm bất cứ thứ gì.

---

## TÓM TẮT 30 GIÂY

```
Máy tính: TrollRestore  →  iPhone: Mở "Mẹo" cài TrollStore
        →  TrollStore cài Dopamine  →  Dopamine bấm Jailbreak
        →  Sileo thêm nguồn  →  cài VCAM  →  xong
```

Tổng thời gian: **30–60 phút**. Cần: 1 máy tính, 1 cáp Lightning, iPhone 7, WiFi.

---

## PHẦN 0 — ĐỌC TRƯỚC (bắt buộc)

### 0.1. Đây là gì và rủi ro
- **Jailbreak** = mở khoá sâu hệ thống để cài tweak. Nó **giảm bảo mật**, có thể
  gây **lỗi máy**, **mất dữ liệu**, và **có thể mất bảo hành**.
- **Sao lưu trước** (iCloud hoặc Finder/iTunes). Không bỏ qua.
- Chỉ làm trên máy **của bạn** hoặc được phép. **Không** dùng để giả mạo danh tính.

### 0.2. Kiểm tra máy có đúng điều kiện
Trên iPhone: **Cài đặt → Cài đặt chung → Giới thiệu**
- Model: **iPhone 7** (`iPhone9,1` hoặc `iPhone9,3`)
- iOS: phải trong khoảng **15.2 – 16.6.1** (hoặc 16.7 RC / 17.0).
  - Ví dụ trong bộ này: **15.8.8** → hợp lệ.
- **Không cập nhật iOS** trước khi làm, kể cả sau khi xong (kiểm tra lại tương thích).

### 0.3. Chuẩn bị
- [ ] Máy tính: **macOS 11+** hoặc **Windows 10+** (Windows cần cài **iTunes**).
- [ ] Cáp Lightning zin (cáp lởm dễ lỗi).
- [ ] iPhone đã **tin cậy máy tính** (bấm *Trust* khi hỏi).
- [ ] Biết **Apple ID + mật khẩu** (cần để tắt Find My).

### 0.4. TẮT Find My iPhone (bắt buộc với TrollRestore)
Trên iPhone: **Cài đặt → [tên bạn] → Find My (Tìm) → Find My iPhone → Tắt**
→ nhập Apple ID để xác nhận.
> Xong quy trình có thể bật lại.

---

## PHẦN 1 — CÀI TROLLSTORE (trên máy tính)

TrollStore là "cửa" để cài app vĩnh viễn không cần ký 7 ngày.

### 1.1. Tải TrollRestore
Vào: https://github.com/JJTech0130/TrollRestore/releases

| Máy tính | Tải file |
|---|---|
| Mac Apple Silicon (M1/M2/M3) | `TrollRestore_macOS_arm64.zip` |
| Mac Intel | `TrollRestore_macOS_amd64.zip` |
| Windows | `TrollRestore.exe` |

> Mac/Linux: **giải nén** file `.zip` ra trước.

### 1.2. Chạy TrollRestore
1. Cắm iPhone vào máy tính, bấm **Trust** trên iPhone.
2. Mở thư mục vừa giải nén.
3. **Mac:** double-click `TrollRestore`.
   - Nếu bị chặn "không mở được": chuột phải → **Open**, hoặc vào
     **System Settings → Privacy & Security → Open Anyway**.
   - **Windows:** double-click `TrollRestore.exe`.
4. Khi được hỏi *"nhập tên app hệ thống muốn ghi đè"* → gõ:
   ```
   Tips
   ```
   rồi Enter.
5. Chờ. **Trên iPhone chưa có gì hiện ra** — bình thường.
   Máy sẽ **tự khởi động lại** khi xong (1–3 phút).

### 1.3. Cài TrollStore trên iPhone
1. Mở khoá iPhone.
2. Mở app **Mẹo / Tips** (app vừa bị ghi đè).
3. Bấm **Install TrollStore**.
4. Máy respring → **TrollStore** xuất hiện ở màn hình chính. ✅

### 1.4. Cài Persistence Helper (quan trọng)
1. Mở **TrollStore**.
2. Bấm **Settings** (bánh răng).
3. Bấm **Install Persistence Helper**.
4. Chọn **Tips**.
> Nhờ bước này, sau khi iPhone khởi động lại vẫn cài/gỡ app TrollStore được.

---

## PHẦN 2 — CÀI DOPAMINE (qua TrollStore)

Dopamine là công cụ **bật jailbreak** ngay trên máy.

### 2.1. Tải Dopamine
Trên iPhone mở **Safari** vào:
```
https://ellekit.space/dopamine/
```
Bấm **"Open in TrollStore"** → TrollStore tự mở và cài Dopamine.
(Hoặc tải `Dopamine.tipa` từ GitHub releases rồi mở bằng TrollStore.)

### 2.2. Cài
- TrollStore hỏi → bấm **Install**.
- Xong: **Dopamine** xuất hiện ở màn hình chính.

---

## PHẦN 3 — BẬT JAILBREAK

1. Mở **Dopamine**.
2. Bấm **Jailbreak**.
3. Chờ máy tải lại giao diện (respring). Có thể mất 1–2 phút.
4. Nếu hiện nút **Apply Workaround** → bấm nó → máy respring →
   mở lại **Dopamine** → bấm **Jailbreak** lần nữa.
5. Khi xong: **Sileo** và **Zebra** xuất hiện (Dopamine cài sẵn 2 trình quản lý gói).

> **Lưu ý:** Dopamine là jailbreak **bán vĩnh viễn**. Khởi động lại iPhone là
> **mất jailbreak**; muốn dùng lại phải mở **Dopamine → Jailbreak**.

---

## PHẦN 4 — THÊM NGUỒN VCAM

1. Mở **Sileo**.
2. Tab **Sources** (nguồn) → bấm dấu **+** góc trên.
3. Dán URL nguồn (do người gửi cung cấp), dạng:
   ```
   https://<TÊN-BẠN>.github.io/dicoy-repo/
   ```
4. Bấm **Add Source** → chờ tải xong.

---

## PHẦN 5 — CÀI VCAM

1. Trong Sileo, mở nguồn vừa thêm → chọn gói **VCAM**.
2. Bấm **Get / Install**.
3. Sileo tự cài kèm **libSandy**. Nếu hỏi → **Confirm**.
4. Cài xong → bấm **Respring** (hoặc vào Cài đặt → VCAM).

---

## PHẦN 6 — DÙNG VCAM

1. Mở **Camera** (hoặc BeautyCam / Google).
2. **Bấm nút tăng âm lượng** (chỉ cần 1 nút).
3. Menu hiện → **Chọn video…** → chọn clip trong Ảnh.
4. Chọn **5 phút** hoặc **10 phút** để thực sự bật.
5. Chụp/quay bình thường; mở Ảnh kiểm tra file mới.

**Tắt:** bấm lại nút tăng âm lượng → **Dừng ngay**, hoặc Cài đặt → **VCAM** → *Tắt tất cả*.

---

## PHẦN 7 — SỰ CỐ THƯỜNG GẶP

| Hiện tượng | Cách xử lý |
|---|---|
| TrollRestore báo lỗi backup | Đảm bảo **Find My đã tắt**, cáp zin, đã Trust máy tính |
| Không thấy app "Mẹo" đổi giao diện | Khởi động lại iPhone, mở lại Tips |
| Mở Tips không có nút Install TrollStore | Chạy lại TrollRestore, nhập đúng `Tips` |
| TrollStore mở app bị crash | Settings → **Refresh App Registrations** |
| Dopamine báo lỗi / treo | Bấm **Apply Workaround**, respring, thử lại |
| Bấm tăng âm lượng không hiện menu | Dopamine chưa bật → mở Dopamine → Jailbreak |
| Sileo không thấy VCAM | Bấm **Refresh** nguồn; kiểm tra URL có `/` cuối |
| Cài báo thiếu `mobilesubstrate` | Dopamine/ElleKit chưa sẵn sàng → respring rồi thử lại |

---

## PHẦN 8 — GỠ / QUAY LẠI

- **Gỡ VCAM:** Sileo → VCAM → **Remove** → respring.
- **Tắt jailbreak tạm:** khởi động lại iPhone (Dopamine semi-untethered).
- **Khôi phục app Mẹo gốc:** xoá app **Tips** trên màn hình chính rồi tải lại
  từ App Store (TrollRestore đã thay binary của nó).
  > Nếu còn dùng Tips làm persistence helper thì **đừng xoá**.
- **Rollback VCAM:** cài trực tiếp `debs/...local23....deb` trong repo rồi respring.

---

## CÂU HỎI NHANH

**Hỏi: Có cách nào "tải 1 file là tự cài hết" không?**
Không. Bước **jailbreak** buộc phải làm trên máy/cáp — không có cách tự động
100% cho máy chưa jailbreak. Quy trình trên là mức gần nhất mà vẫn an toàn.

**Hỏi: Có cần máy tính không?**
Có, **1 lần** để cài TrollStore (TrollRestore). Sau đó mọi thứ làm trên iPhone.

**Hỏi: Làm trên Windows được không?**
Được, cần **iTunes** + `TrollRestore.exe`. Các bước còn lại giống hệt.

**Hỏi: Cập nhật iOS được không?**
Không, cho đến khi kiểm tra lại Dopamine/TrollStore có hỗ trợ bản mới không.
