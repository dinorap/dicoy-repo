# QUY TRÌNH TỪ ĐẦU — Cho người chuẩn bị máy / Kỹ thuật viên

> Mục tiêu: từ một iPhone 7 **chưa jailbreak** → cài đặt hoàn chỉnh **VCAM** → dọn dẹp sạch sẽ (xóa Sileo & cache) → bàn giao cho khách sử dụng an toàn.

---

## TÓM TẮT QUY TRÌNH

```
Máy tính: TrollRestore  →  iPhone: Mở "Mẹo" cài TrollStore
        →  TrollStore cài Dopamine  →  Dopamine bấm Jailbreak
        →  Sileo thêm nguồn  →  Cài VCAM (kèm libSandy)
        →  Sileo cài VCAM Finalize (xóa Sileo + cache)  →  Xong bàn giao
```

Tổng thời gian: **20–30 phút**. Cần: 1 máy tính (Windows/Mac), cáp Lightning, iPhone 7, WiFi.

---

## PHẦN 0 — CHUẨN BỊ (BẮT BUỘC)

### 0.1. Kiểm tra điều kiện máy
Trên iPhone vào: **Cài đặt → Cài đặt chung → Giới thiệu**
- Model: **iPhone 7** (hoặc các dòng A10 checkm8)
- Phiên bản iOS: **15.0 – 16.6.1** (hoặc 16.7 RC / 17.0).
- **Không cập nhật iOS** trước và sau khi thực hiện.

### 0.2. Chuẩn bị công cụ
- Máy tính Windows (cần cài **iTunes** để nhận diện iPhone) hoặc macOS.
- Cáp Lightning truyền dữ liệu tốt.
- Mở khóa màn hình iPhone, khi cắm cáp chọn **Tin cậy (Trust)** máy tính.

### 0.3. TẮT Find My iPhone (bắt buộc trước khi chạy TrollRestore)
Trên iPhone vào: **Cài đặt → [Tên Apple ID] → Tìm (Find My) → Tìm iPhone → Tắt** (nhập mật khẩu Apple ID để xác nhận).

---

## PHẦN 1 — CÀI TROLLSTORE (TRÊN MÁY TÍNH)

TrollStore là công cụ cài app vĩnh viễn không bị thu hồi chứng chỉ.

### 1.1. Tải TrollRestore
Tải `TrollRestore.exe` (cho Windows) hoặc file `.zip` (cho macOS) từ thư mục `tools/` của repo hoặc GitHub Releases:
https://github.com/JJTech0130/TrollRestore/releases

### 1.2. Chạy TrollRestore
1. Cắm iPhone vào máy tính (đã bấm Trust).
2. Chạy tệp **`TrollRestore.exe`**.
3. Khi cửa sổ hỏi tên app hệ thống muốn ghi đè, gõ:
   ```
   Tips
   ```
   rồi nhấn **Enter**.
4. Chờ 1–2 phút để iPhone tự khởi động lại.

### 1.3. Cài TrollStore trên iPhone
1. Mở khóa màn hình iPhone → Tìm và mở ứng dụng **Mẹo (Tips)**.
2. Bấm vào **Install TrollStore**.
3. Chờ máy respring → Ứng dụng **TrollStore** xuất hiện trên màn hình chính.

### 1.4. Cài Persistence Helper
1. Mở ứng dụng **TrollStore**.
2. Vào tab **Settings** (hình bánh răng).
3. Bấm **Install Persistence Helper** → Chọn **Tips**.
*(Bước này đảm bảo sau khi máy khởi động lại vẫn giữ được TrollStore).*

---

## PHẦN 2 — CÀI DOPAMINE & BẬT JAILBREAK

Dopamine là công cụ jailbreak bán vĩnh viễn (rootless) hoạt động ổn định trên iOS 15–16.

### 2.1. Tải và cài Dopamine
- Trên iPhone mở trình duyệt Safari truy cập: `https://ellekit.space/dopamine/`
- Bấm **Open in TrollStore** → TrollStore sẽ tự động tải và hiện bảng cài đặt → Bấm **Install**.
*(Hoặc gửi file `tools/Dopamine-3.0.12.ipa` sang iPhone rồi mở bằng TrollStore).*

### 2.2. Kích hoạt Jailbreak
1. Mở ứng dụng **Dopamine** trên màn hình chính.
2. Bấm nút **Jailbreak**.
3. Chờ hệ thống chạy và respring (nếu xuất hiện nút *Apply Workaround*, bấm vào nó rồi mở lại Dopamine bấm *Jailbreak* lần nữa).
4. Sau khi hoàn thành, ứng dụng **Sileo** sẽ xuất hiện trên màn hình chính.

---

## PHẦN 3 — THÊM NGUỒN & CÀI ĐẶT VCAM

1. Mở ứng dụng **Sileo**.
2. Chuyển sang tab **Sources (Nguồn)** → bấm dấu **`+`** ở góc trên bên phải.
3. Dán địa chỉ nguồn của bạn:
   ```
   https://dinorap.github.io/dicoy-repo/
   ```
4. Bấm **Add Source (Thêm nguồn)** → Chờ tải danh sách gói rồi bấm **Refresh**.
5. Mở nguồn vừa thêm → Chọn gói **VCAM** → Bấm **Get (Nhận)**.
   *(Sileo sẽ tự động tích hợp kèm gói thư viện phụ thuộc `libSandy`)*.
6. Bấm **Confirm (Xác nhận)** để cài đặt → Sau khi cài xong, bấm **Respring**.

---

## PHẦN 4 — DỌN DẸP BÀN GIAO (XÓA SILEO & CACHE)

> 🔥 **Bước quan trọng nhất trước khi giao máy cho khách**:
> Xóa sạch kho ứng dụng Sileo và các dấu vết cài đặt để khách không bấm nhầm làm hỏng jailbreak, đồng thời máy hoàn toàn sạch sẽ như máy nguyên bản.

1. Mở lại ứng dụng **Sileo**.
2. Vào nguồn của bạn → Tìm và chọn gói **`VCAM Finalize`**.
3. Bấm **Get (Nhận)** → Chọn **Confirm** để chạy.
4. **Cơ chế tự động dọn dẹp của `VCAM Finalize`:**
   - 🧹 Tự động xóa danh sách nguồn APT của repo khỏi máy.
   - 🧹 Xóa sạch bộ nhớ đệm cache APT và các file deb cài đặt tạm trong máy.
   - 🧹 Chờ cài đặt xong sẽ tự động gỡ bỏ hoàn toàn ứng dụng **Sileo** (và tự hủy chính gói Finalize).
   - 🧹 Gọi lệnh `uicache` làm mới giao diện SpringBoard: biểu tượng Sileo sẽ biến mất hoàn toàn khỏi màn hình chính.
5. Sau bước này, máy hoàn toàn sạch bóng kho ứng dụng, nhưng **VCAM vẫn hoạt động ngầm 100%**.

---

## PHẦN 5 — TEST THỬ VÀ BÀN GIAO CHO KHÁCH

### 5.1. Test VCAM
1. Mở ứng dụng **Camera** (hoặc BeautyCam, Google Lens).
2. **Bấm đồng thời nút Tăng âm lượng + nút Nguồn** (giữ khoảng 0.4 giây rồi thả ra).
3. Menu VCAM sẽ hiện lên → Bấm **Chọn video…** → Chọn 1 video trong Thư viện Ảnh → Chọn **5 hoặc 10 phút**.
4. Kiểm tra camera đã thay bằng video vừa chọn hay chưa.
5. Tắt: Bấm lại tổ hợp phím → Chọn **Dừng ngay** (hoặc vào *Cài đặt > VCAM > Tắt tất cả*).

### 5.2. Hướng dẫn bàn giao cho khách
Gửi cho khách đường link rút gọn chỉ hướng dẫn cách dùng:
👉 **`https://dinorap.github.io/dicoy-repo/`**

**Dặn khách 2 điều duy nhất:**
1. **Cách bật video:** Mở Camera → Bấm đồng thời *Tăng âm lượng + Nguồn*.
2. **Nếu máy hết pin / khởi động lại:** Mở app **Dopamine** → bấm **Jailbreak** một lần là dùng lại bình thường (không mất cấu hình, không cần máy tính).
