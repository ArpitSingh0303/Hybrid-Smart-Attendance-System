# Hybrid Smart Attendance System

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)
![Node.js](https://img.shields.io/badge/Node.js-Express-green)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Prisma-blue)
![JWT](https://img.shields.io/badge/Auth-JWT-orange)

A full-stack attendance management system built using **Flutter**, **Express.js**, **PostgreSQL**, and **Prisma ORM**. The system provides secure attendance marking through persistent device binding, role-based authentication, and administrator approval.

---

## Features

### Student
- Secure Signup & Login
- JWT Authentication
- Active Session Detection
- Attendance Marking
- Attendance History
- Attendance Statistics
- Device Registration
- Profile Management

### Teacher
- Secure Login
- Session Creation
- Dashboard & Analytics
- Attendance Reports
- Device Approval/Rejection
- Student Monitoring
- Profile Dashboard

### Security
- JWT Authentication
- Role-Based Access Control
- Persistent UUID Device Binding
- One Active Device Policy
- Administrator Approval Workflow

---

## Tech Stack

| Category | Technology |
|----------|------------|
| Frontend | Flutter |
| Backend | Express.js |
| Database | PostgreSQL |
| ORM | Prisma ORM |
| Authentication | JWT |
| Deployment | Railway |
| Device Identity | UUID + SHA-256 |

---

## System Architecture

> *(Add architecture diagram here)*

```
Flutter App
      │
 REST APIs (JWT)
      │
Express.js Backend
      │
Prisma ORM
      │
PostgreSQL
      │
Railway
```

---

## Project Structure

```
Hybrid-Smart-Attendance-System
│
├── backend/
├── flutter_app/
├── docs/
├── assets/
└── README.md
```

---

## Setup

### Backend

```bash
cd backend
npm install
npx prisma migrate dev
npm start
```

### Flutter

```bash
cd flutter_app
flutter pub get
flutter run
```

---

## API Overview

| Endpoint | Purpose |
|----------|---------|
| POST /student/signup | Student Registration |
| POST /student/login | Student Login |
| POST /teacher/login | Teacher Login |
| POST /session/create | Create Attendance Session |
| GET /session/active | Active Session |
| POST /attendance/mark | Mark Attendance |
| GET /attendance/history | Attendance History |
| GET /teacher/dashboard | Teacher Dashboard |
| POST /teacher/approve-device | Approve Device |

---

## Screenshots

> Add screenshots here

- Student Login
- Student Dashboard
- Attendance Flow
- Attendance History
- Teacher Dashboard
- Device Approval
- Analytics

---

## My Contribution

As part of a **5-member capstone team**, I was responsible for:

- Backend Architecture
- Express.js REST APIs
- PostgreSQL Database Design
- Prisma ORM Integration
- JWT Authentication
- Device Binding Workflow
- Railway Deployment
- Flutter Backend Integration
- API Contract Design
- End-to-End Testing

---

## Future Improvements

- Subject-wise Attendance Analytics
- Timetable Integration
- Notification System
- Real-time Updates
- Offline Support

---

## License

This project is licensed under the MIT License.
