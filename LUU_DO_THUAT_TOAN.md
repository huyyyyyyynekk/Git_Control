# Lưu đồ thuật toán — Button_Nhung_2026

Các sơ đồ dưới đây được đọc từ [`Button_Nhung_2026.ino`](./Button_Nhung_2026.ino). Mỗi sơ đồ là một khối riêng và đi theo chiều ngang từ trái sang phải.

## 1. Khởi động và kiến trúc chương trình

```mermaid
flowchart LR
    A([Bắt đầu]) --> B["setup(): khởi tạo Serial,<br/>Wi-Fi, nút bấm, âm thanh"]
    B --> C["Khởi tạo mutex RTC<br/>và hàng đợi lịch uống"]
    C --> D{"RTC hoạt động?"}
    D -- Không --> E["In lỗi; chờ vô hạn"]
    D -- Có --> F{"RTC đã chạy?"}
    F -- Chưa --> G["Đặt thời gian RTC<br/>theo thời điểm biên dịch"]
    F -- Rồi --> H["Khởi tạo màn hình TFT"]
    G --> H
    H --> I["WiFiManager tự kết nối<br/>hoặc mở cổng cấu hình"]
    I --> J["Tạo TaskNetwork<br/>(Core 0, ưu tiên 1)"]
    J --> K["Tạo TaskUI<br/>(Core 1, ưu tiên 2)"]
    K --> L["loop(): ngủ 1 giây;<br/>FreeRTOS điều phối các task"]
    L --> L
    J -. chạy song song .-> N["TaskNetwork:<br/>đồng bộ lịch với máy chủ"]
    K -. chạy song song .-> U["TaskUI:<br/>đọc nút, màn hình,<br/>quản lý lịch và báo giờ"]
```

## 2. TaskUI — chọn thuốc và đặt giờ uống

```mermaid
flowchart LR
    A([Vòng lặp TaskUI]) --> B["Đọc giờ RTC và quét 3 nút<br/>(MODE, UP, DOWN; chống dội)"]
    B --> C{"Cùng lúc nhấn<br/>cả 3 nút?"}
    C -- Có, lần đầu --> D["Xóa hàng đợi gửi; đặt yêu cầu<br/>xóa lịch trên máy chủ"]
    D --> E["Xóa lịch local của 3 hộp,<br/>trạng thái chọn và cờ báo"]
    E --> F["Về danh sách thuốc;<br/>bật giao diện và phát âm báo"]
    F --> Z["Chờ 15 ms"]
    C -- Không --> G{"Chế độ danh sách<br/>(Mode = 0)?"}
    G -- Có --> H{"Giữ MODE khoảng<br/>2,7 giây?"}
    H -- Có --> I["Bật giao diện (Power = 1);<br/>hiển thị danh sách thuốc"]
    H -- Không --> J{"Nhấn MODE ngắn<br/>khi giao diện bật?"}
    J -- Có --> K["Lấy thuốc đang chọn;<br/>chọn hộp trống đầu tiên<br/>(Box 1 → Box 2 → Box 3)"]
    K --> L{"Có hộp trống?"}
    L -- Có --> M["Gán thuốc vào hộp;<br/>mở màn hình đặt giờ<br/>(Mode = 1)"]
    L -- Không --> N["Không gán thêm hộp"]
    J -- Không --> O["UP/DOWN di chuyển<br/>con trỏ trong danh sách thuốc"]
    G -- Không --> P["Trong Mode 1: đặt giờ cho<br/>hộp đang được cấu hình"]
    M --> P
    P --> Q["UP/DOWN tăng/giảm<br/>giá trị trường đang chọn"]
    Q --> R["MODE chuyển trường:<br/>giây → phút → giờ"]
    R --> S{"Đã xác nhận trường giờ?"}
    S -- Có --> T["Phát âm báo; đưa tên thuốc,<br/>số hộp và giờ vào hàng đợi"]
    S -- Chưa --> V["Tiếp tục chỉnh giờ"]
    T --> W{"Nhấn UP và DOWN<br/>đồng thời?"}
    V --> W
    W -- Có --> X["Thoát đặt giờ;<br/>quay về danh sách thuốc"]
    W -- Không --> Y["Kiểm tra lịch đến giờ,<br/>cập nhật màn hình lịch web"]
    X --> Y
    O --> Y
    I --> Y
    N --> Y
    Y --> Z
    Z --> A
```

## 3. TaskUI — kiểm tra giờ và phát báo thuốc

```mermaid
flowchart LR
    A["Mỗi vòng lặp: lấy giờ hiện tại<br/>từ RTC"] --> B{"Hộp 1 có lịch đang hoạt động<br/>và giờ:phút:giây trùng RTC?"}
    B -- Có --> C["Phát âm báo hộp 1;<br/>xóa lịch và tên thuốc hộp 1"]
    B -- Không --> D{"Hộp 2 có lịch đang hoạt động<br/>và giờ:phút:giây trùng RTC?"}
    C --> D
    D -- Có --> E["Phát âm báo hộp 2;<br/>xóa lịch và tên thuốc hộp 2"]
    D -- Không --> F{"Hộp 3 có lịch đang hoạt động<br/>và giờ:phút:giây trùng RTC?"}
    E --> F
    F -- Có --> G["Phát âm báo hộp 3;<br/>xóa lịch và tên thuốc hộp 3"]
    F -- Không --> H["Giữ các lịch chưa đến giờ"]
    G --> I["Chờ 15 ms"]
    H --> I
    I --> A
```

## 4. TaskNetwork — đồng bộ hai chiều với máy chủ

```mermaid
flowchart LR
    A([Vòng lặp TaskNetwork]) --> B{"Wi-Fi đã kết nối<br/>và có yêu cầu xóa lịch?"}
    B -- Có --> C["Gửi DELETE /api/device/schedules<br/>(tối đa 3 lần)"]
    C --> D{"Xóa thành công?"}
    D -- Có --> H["Tiếp tục vòng lặp"]
    D -- Không --> E["Đặt lại yêu cầu xóa<br/>và chờ 1 giây"]
    E --> H
    B -- Không --> F{"Wi-Fi đã kết nối<br/>và hàng đợi có lịch gửi?"}
    F -- Có --> G["Lấy một lịch khỏi hàng đợi;<br/>POST /api/device/sync-pill<br/>(tối đa 3 lần)"]
    G --> I{"Gửi thành công?"}
    I -- Có --> H
    I -- Không --> J["Đưa lịch về đầu hàng đợi;<br/>chờ 1 giây"]
    J --> H
    F -- Không --> H
    H --> K{"Đã đến chu kỳ<br/>10 giây?"}
    K -- Có --> L["GET /api/device/schedules;<br/>phân tích JSON"]
    L --> M{"HTTP 200 và JSON hợp lệ?"}
    M -- Có --> N["Cập nhật lịch web<br/>cho hộp 1–3"]
    M -- Không --> O["In lỗi HTTP hoặc lỗi JSON"]
    N --> P{"Wi-Fi mất kết nối?"}
    O --> P
    K -- Không --> P
    P -- Có --> Q["WiFiManager.process():<br/>xử lý kết nối/cấu hình Wi-Fi"]
    P -- Không --> A
    Q --> A
```

**Ghi chú:** Lịch được kích hoạt khi thời gian hộp khớp chính xác với giờ, phút và giây RTC; đây là phép so khớp thời điểm, không phải bộ đếm ngược. Lịch local được gửi qua hàng đợi FreeRTOS; lịch tải từ máy chủ được cập nhật vào các hộp tương ứng.
