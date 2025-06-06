# TakeTime-FocusApp
Taketime Focus – Smart Time Management App ( Vietnamese below)
This project consists of two main components:

Frontend: Built with Flutter (Taketime-focus Source)

Backend API: Built with .NET

📦 Requirements
Make sure your system has the following dependencies installed:

Flutter SDK

.NET SDK

Visual Studio Code (recommended over Android Studio for this setup due to lighter weight and better integration with required libraries)

Gradle (optional; needed in some device environments)

Java JDK 11 (required for Gradle)

desugar_jdk_libs version 2.0.3

⚙️ Setup Instructions
1. Set Up the Backend API
Clone the API source code:

bash
Copy
Edit
git clone <API-Repository-URL>
Open the project:

With Visual Studio: open the .sln file.

With Visual Studio Code: open the main folder (usually contains Controllers, Models, Views, etc.).

Run the project:

On Visual Studio: click the green "Run" arrow button to build and run the project.

On VS Code: open a terminal and run:

bash
Copy
Edit
dotnet run
Wait until the terminal displays the localhost address — this means the API is running successfully.

2. Set Up the Flutter App
Clone the Flutter app source code:

bash
Copy
Edit
git clone <Taketime-focus-Repository-URL>
Open the project using Visual Studio Code.

Make sure you have:

Flutter SDK installed

Android Virtual Device running Android 10 or later

Use flutter doctor to verify system readiness

Install project dependencies:

bash
Copy
Edit
flutter pub get
Open an Android Virtual Device using Android Studio.

Select the active mobile device.

Run the app:

In VS Code (blue), run the following command in the terminal:

bash
Copy
Edit
flutter run
Ensure the correct device is selected (bottom-right corner of VS Code).

Wait for the app to assemble the debug APK (x86). The app will be installed and launched automatically on the device.

⚠️ Note: Make sure the backend API is running before launching the app.

📌 Notes
This setup has been tested and optimized for Visual Studio Code.

Ensure all dependencies and environment variables are correctly set up before running the app.
-- Thư viện yêu cầu : 
Flutter SDK 
.NET
ưu tiên chạy trên Visual Studio Code ( Visual studio code có tối ưu cho các thư viện này hơn là android studio ngoài ra nhẹ hơn )
Gradle ( cho 1 vài trường hợp thiết bị không có )
Java version 11 ( cho Gradle )
desugar_jdk_libs:2.0.3
-- Các bước thiết lập chương trình khởi chạy
1. Tải chương trình API về thiết bị
 + Git clone API Source 
 + mở chương trình ( visual studio thì mở file .sln , visual studio code thì mở folder chính thường là folder chứa các controller | model | views )
 + Visual Studio thì chọn nút build ( nút mũi tên xanh để build ) Visual Studio Code thì gõ lệnh "dotnet run" vào terminal
 + Chờ terminal hiển thị localhost là thành công
2. Tải chương trình Code về thiết bị
 + Git clone Taketime-focus Source
 + Mở chương trình ( yêu cầu có sdk flutter , virtual device android 10+ , sử dụng flutter doctor để kiểm tra các yêu cầu nếu đủ mới chạy được )
 + gõ lệnh "flutter pub get" để tải các dependencies yêu cầu , ngoài ra kiểm tra phiên bản.
 + Sử dụng android studio để mở virtual device
 + chọn vào thiết bị mobile đang mở 
 + với Vscode ( xanh ) thì ở terminal sử dụng lệnh "flutter run" ( yêu cầu phải chỉ đúng vào thiết bị , xem thiết bị được chọn ở góc phải bên dưới )
 + Chờ apk assembling debug x86 và tự cài đặt ứng dụng
 + Nếu thành công ứng dụng sẽ tự cài đặt trên thiết bị và khởi chạy ứng dụng ( yêu cầu API phải được bật )
