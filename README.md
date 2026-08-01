# Hybrid Smart Attendance System

A comprehensive, production-ready attendance management solution featuring device fingerprinting, real-time analytics, and role-based access control.

## 🚀 Overview
The Hybrid Smart Attendance System is designed to streamline classroom attendance through a secure mobile application and a robust Node.js backend. It solves common attendance issues like proxy marking by using unique device identification and session-based windows.

### Key Features
- **Dual Role Support**: Custom dashboards and workflows for both Students and Faculty.
- **Device Fingerprinting**: Ensures each student can only mark attendance from their registered, approved device.
- **Real-time Session Management**: Faculty can create and manage live attendance windows.
- **Advanced Analytics**: Dynamic reports and statistics for monitoring attendance trends.
- **Secure Authentication**: JWT-based security with session restoration and auto-login.
- **Modern UI**: Built with Flutter following Material 3 design principles.

## 📂 Project Structure
```text
├── flutter_app/      # Cross-platform Flutter mobile application
├── backend/          # Node.js API with Prisma ORM and PostgreSQL
├── docs/             # Technical documentation and diagrams
├── assets/           # UI assets and screenshots
├── README.md
├── LICENSE
└── .gitignore
```

## 🛠️ Tech Stack
- **Frontend**: Flutter, Dart, Google Fonts, Flutter Secure Storage
- **Backend**: Node.js, Express, Prisma ORM
- **Database**: PostgreSQL (Supabase/Railway compatible)
- **Security**: JWT (JSON Web Tokens), Device UUID & Hash verification

## ⚙️ Setup Instructions

### Backend Setup
1. Navigate to the `backend/` directory.
2. Install dependencies: `npm install`.
3. Configure your environment: Copy `.env.example` to `.env` and fill in your database URL and JWT secret.
4. Run migrations: `npx prisma migrate dev`.
5. Start the server: `npm start`.

### Flutter App Setup
1. Navigate to the `flutter_app/` directory.
2. Install dependencies: `flutter pub get`.
3. Update API configuration in `lib/core/constants/api_constants.dart` to point to your backend URL.
4. Run the app: `flutter run`.

## 📸 Screenshots
*Placeholders available in `docs/screenshots/`*

## 📜 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing
Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.
