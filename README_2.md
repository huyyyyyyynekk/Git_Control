# Đồng Hồ Số Có Chức Năng Hẹn Giờ Sử Dụng SN32F407_EVK

## Giới thiệu

Đây là project xây dựng đồng hồ số có chức năng hẹn giờ sử dụng board SN32F407_EVK. Hệ thống sử dụng LED 7 đoạn để hiển thị thời gian theo định dạng HH.MM, hỗ trợ thay đổi giờ/phút, cài đặt báo thức, lưu dữ liệu bằng EEPROM, điều khiển buzzer và xử lý timeout khi không có thao tác người dùng.

---

## Chức năng chính

### 1. Chế độ hoạt động bình thường

Ngay sau khi cấp nguồn, đồng hồ sẽ hoạt động ở chế độ bình thường với giá trị mặc định:

```text
00.00
```

LED 7 đoạn hiển thị thời gian theo định dạng:

```text
HH.MM
```

Hệ thống sẽ:

* Tăng phút sau mỗi 60 giây
* Khi phút đạt 60:

  * Reset phút về 00
  * Tăng giờ lên 1
* Giờ được hiển thị từ:

  * 00 → 23

---

### 2. Nút SETUP (SW3)

#### Khi đang ở chế độ bình thường:

Ấn SW3 để vào chế độ thay đổi giờ.

* Hai LED HH sẽ nhấp nháy:

  * 0.5s ON
  * 0.5s OFF

#### Khi đang ở chế độ thay đổi giờ:

Ấn SW3 lần nữa để vào chế độ thay đổi phút.

* Hai LED MM sẽ nhấp nháy theo chu kỳ 1 giây.

#### Khi đang ở chế độ thay đổi phút:

Ấn SW3 lần nữa để quay về chế độ bình thường.

---

### 3. Nút Hẹn Giờ (SW16)

#### Khi đang ở chế độ bình thường:

Ấn SW16 để vào chế độ thay đổi giờ hẹn.

* Hai LED HH nhấp nháy theo chu kỳ 1 giây.

#### Khi đang ở chế độ thay đổi giờ hẹn:

Ấn SW16 để chuyển sang chế độ thay đổi phút hẹn.

* Hai LED MM nhấp nháy theo chu kỳ 1 giây.

#### Khi đang ở chế độ thay đổi phút hẹn:

Ấn SW16:

* Lưu giờ hẹn vào EEPROM
* Thoát về chế độ bình thường

---

### 4. Nút Tăng (SW6)

#### Trong chế độ thay đổi giờ hoặc giờ hẹn:

Ấn SW6:

* Tăng giờ lên 1
* Khi giờ = 24:

  * Reset về 0

#### Trong chế độ thay đổi phút hoặc phút hẹn:

Ấn SW6:

* Tăng phút lên 1
* Khi phút = 60:

  * Reset về 0

---

### 5. Nút Giảm (SW10)

#### Trong chế độ thay đổi giờ hoặc giờ hẹn:

Ấn SW10:

* Giảm giờ xuống 1
* Nếu giờ = 0:

  * Chuyển thành 23

#### Trong chế độ thay đổi phút hoặc phút hẹn:

Ấn SW10:

* Giảm phút xuống 1
* Nếu phút = 0:

  * Chuyển thành 59

---

### 6. Buzzer

#### Khi nhấn các nút:

* SW3
* SW6
* SW10
* SW16

Buzzer sẽ kêu:

```text
pip trong 0.3s
```

#### Khi đến giờ hẹn:

Buzzer sẽ kêu liên tục trong 5 giây với chu kỳ:

* 0.5s ON
* 0.5s OFF

#### Khi timeout:

Nếu hệ thống tự động thoát khỏi chế độ chỉnh giờ/phút hoặc giờ hẹn/phút hẹn:

* Buzzer sẽ kêu pip trong 0.3s

---

### 7. LED Báo Trạng Thái

Sử dụng:

* D4 đối với board SN8F5708_EVK
* D6 đối với board SN32F407_EVK

Trong các chế độ:

* Thay đổi giờ hẹn
* Thay đổi phút hẹn

LED sẽ nhấp nháy:

* 0.5s ON
* 0.5s OFF

Ngoài các chế độ trên:

* LED OFF

---

### 8. EEPROM

EEPROM được sử dụng để lưu:

* Giờ hẹn
* Phút hẹn

Giây hẹn mặc định:

```text
00
```

### 9. Timeout

Trong các chế độ:

* Chỉnh giờ/phút
* Chỉnh giờ hẹn/phút hẹn

Nếu không có thao tác nút nhấn trong vòng:

```text
30 giây
```

Hệ thống sẽ:

* Tự động thoát về chế độ bình thường
* Buzzer kêu pip trong 0.3s

---

## Tài nguyên phần cứng sử dụng

| Phần cứng       | Chức năng          |
| --------------- | ------------------ |
| LED 7 đoạn 4 số | Hiển thị thời gian |
| SW3             | Setup              |
| SW6             | Tăng giá trị       |
| SW10            | Giảm giá trị       |
| SW16            | Cài đặt báo thức   |
| BUZZER          | Âm báo             |
| EEPROM          | Lưu giờ hẹn        |
| LED D4/D6       | Báo trạng thái     |

---

## Kiến trúc phần mềm

Project gồm các module chính:

* Quản lý thời gian
* Điều khiển LED 7 đoạn
* Xử lý nút nhấn
* Điều khiển buzzer
* Giao tiếp EEPROM
* Xử lý timeout
* SysTick interrupt

---

## Môi trường phát triển

* Keil MDK-ARM
* Embedded C
* ARM Compiler 5 / ARM Compiler 6

Board hỗ trợ:

* SN8F5708_EVK
* SN32F407_EVK

---

MCU HANOI CONTEST
```
