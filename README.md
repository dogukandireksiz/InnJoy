# InnJoy — Smart Hotel Guest Experience App

**A full-featured Flutter & Firebase hotel management platform connecting guests with hotel services in real-time.**

---

## 📖 Overview

**InnJoy** is a cross-platform mobile application built with Flutter that reimagines the hotel stay experience. It bridges the gap between hotel guests and hotel staff through a real-time, feature-rich digital interface — eliminating the need for physical menus, front-desk visits, or paper forms.

The app supports two distinct user roles:

- 🧳 **Guest** — Books services, orders food, manages plans, monitors spending, and sends emergency alerts, all from their phone.
- 🛠️ **Admin (Hotel Staff)** — Manages rooms, guests, orders, events, housekeeping, and emergency responses from a dedicated control panel.

---

## ✨ Features

### 🧳 Guest Features

| Module | Description |
|--------|-------------|
| 🔐 **Authentication** | Email/Password signup & login, Google Sign-In, Facebook Login, password reset via Firebase Auth |
| 🏨 **Digital Hotel Card** | Personalized hotel card showing room number, check-in/out dates, and a QR code digital key |
| 🍽️ **Dining & Restaurant** | Browse restaurant menus, make table reservations with date/time/party size and special notes |
| 🛎️ **Room Service** | Browse categorized food/beverage menus, add items to cart, and place orders directly to the kitchen |
| 🧹 **Housekeeping** | Request room cleaning, extra towels, minibar refills, or any custom service from your room |
| 💆 **Spa & Wellness** | Browse spa packages, book appointments, and manage upcoming wellness sessions |
| 🏋️ **Fitness Center** | View gym amenities, hours, and access fitness center information |
| 🎉 **Events & Activities** | View hotel events, see details, and join activities (concerts, yoga, city tours, etc.) |
| 🚨 **Emergency SOS** | Send a categorized SOS alert (Medical / Fire / Security) with room number and GPS location |
| 🗺️ **Emergency Map** | View hotel floor plan and locate the nearest emergency exits in real time |
| 💳 **Spending Tracker** | Visualize all charges (restaurant, spa, room service) in a pie chart and request settlement |
| 📅 **My Plans** | See all upcoming reservations and bookings in a unified timeline view |
| 👤 **Profile & Preferences** | Update personal info, choose interests (Music, Sports, Art, etc.) for personalized event notifications |

---

### 🛠️ Admin (Staff) Features

| Module | Description |
|--------|-------------|
| 🏠 **Admin Dashboard** | Real-time overview of active guests, pending requests, and room statuses |
| 🏨 **Room Management** | Full CRUD for hotel rooms — set status (Occupied / Available / Cleaning / Maintenance), assign guests |
| 👥 **Guest Management** | Manage guest check-in/check-out, view guest details, and link guests to rooms |
| 📋 **Order & Request Tracking** | Live feed of all room service orders and housekeeping requests; update statuses (Pending → Preparing → Delivered) |
| 🍽️ **Menu Management** | Add/edit/remove menu items for Restaurant and Room Service in real time |
| 🎉 **Events Management** | Create hotel events with images, tags, categories, time and location; publish to all guests |
| 💆 **Spa Management** | Manage spa services, packages, and booking approvals |
| 🚨 **Emergency Admin Screen** | Receive real-time SOS alerts with siren sound and full-screen notification; view guest location and room |

---

## 🏗️ Architecture & Tech Stack

```
InnJoy/
├── innjoy/                  # Flutter application root
│   ├── lib/
│   │   ├── main.dart        # App entry point, global listeners (emergency, events)
│   │   ├── firebase_options.dart
│   │   ├── models/          # Data models (UserModel, MenuItemModel, ReservationModel)
│   │   ├── services/        # Business logic layer
│   │   │   ├── auth.dart               # Firebase Auth wrapper
│   │   │   ├── notification_service.dart
│   │   │   ├── database_service.dart   # Unified Firestore facade
│   │   │   └── database/               # Modular database services
│   │   │       ├── hotel_service.dart
│   │   │       ├── restaurant_service.dart
│   │   │       ├── event_service.dart
│   │   │       ├── spa_service.dart
│   │   │       ├── housekeeping_service.dart
│   │   │       ├── room_service_service.dart
│   │   │       ├── reservation_service.dart
│   │   │       ├── emergency_service.dart
│   │   │       └── user_data_service.dart
│   │   ├── screens/         # UI screens (feature-based folders)
│   │   │   ├── auth/        # Login, Signup, Forgot Password
│   │   │   ├── home/        # Guest Home, Admin Home, Hotel Selection
│   │   │   ├── admin/       # Admin panels (rooms, guests, housekeeping, requests)
│   │   │   ├── room_service/
│   │   │   ├── dining/
│   │   │   ├── services/spa_wellness/ & fitness/
│   │   │   ├── events_activities/
│   │   │   ├── emergency/   # Emergency screen, Admin emergency, Floor map
│   │   │   ├── housekeeping/
│   │   │   ├── payment/     # Spending tracker
│   │   │   ├── my_plans/
│   │   │   └── profile/
│   │   ├── widgets/         # Reusable UI components (AuthWrapper, etc.)
│   │   ├── utils/           # Utility helpers
│   │   ├── config/          # App-level constants and theme config
│   │   ├── location/        # Geolocation helpers
│   │   └── map/             # Flutter Map integration
│   └── assets/
│       ├── images/          # Hotel images, logos, floor plans
│       ├── avatars/         # User avatar assets
│       └── sounds/          # Emergency siren audio
└── use_cases.md             # Comprehensive use case documentation
```

### 🔧 Technology Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | Flutter 3.x (Dart 3.x) |
| **Authentication** | Firebase Auth (Email, Google, Facebook) |
| **Database** | Cloud Firestore (real-time listeners) |
| **Storage** | Firebase Storage (profile photos, event images) |
| **Notifications** | `flutter_local_notifications` + `audioplayers` |
| **Maps** | `flutter_map` + `geolocator` + `latlong2` |
| **QR Code** | `qr_flutter` |
| **Fonts** | Google Fonts |
| **State / Streams** | `rxdart` + Dart Streams |
| **Networking** | `connectivity_plus` |
| **Scheduling** | `timezone` + `flutter_local_notifications` |

---

## 🔥 Firebase Firestore Structure

```
Firestore
├── users/
│   └── {uid}                    ← User profile, role, hotel, interests, room assignment
├── hotels/
│   └── {hotelName}/
│       ├── rooms/               ← Room status, guest assignment
│       ├── events/              ← Hotel events with tags/categories
│       ├── restaurant_menu/     ← Dining menu items
│       ├── room_service_menu/   ← Room service items
│       ├── spa_services/        ← Spa packages and bookings
│       ├── housekeeping_requests/
│       ├── room_service_orders/
│       └── reservations/
└── emergency_alerts/            ← Global SOS alerts (real-time, admin notified)
```

---

## 🔔 Real-Time Notification System

InnJoy features a **dual notification system** built entirely in `main.dart` as global app-level listeners:

1. **Emergency SOS Alerts** — Listens to `emergency_alerts` collection globally. When a new active alert is created within the last 60 seconds, the admin receives a full-screen push notification **with an emergency siren sound** (played via `audioplayers`).

2. **Interest-Based Event Notifications** — After login, the app listens to the user's interest tags and sends a push notification whenever a new matching event is created at their hotel — fully personalized.

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) `>= 3.10.0`
- [Firebase CLI](https://firebase.google.com/docs/cli) configured
- Android Studio / Xcode for device targets

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/your-username/InnJoy.git
cd InnJoy/innjoy

# 2. Install dependencies
flutter pub get

# 3. Configure Firebase
# Place your google-services.json (Android) in android/app/
# Place your GoogleService-Info.plist (iOS) in ios/Runner/
# Or run: flutterfire configure

# 4. Run the app
flutter run
```

### Generate App Icons

```bash
flutter pub run flutter_launcher_icons
```

---

## 👥 User Roles & Access

| Feature | Guest | Admin |
|---------|:-----:|:-----:|
| Login / Signup | ✅ | ✅ |
| View hotel dashboard | ✅ | — |
| Digital room key (QR) | ✅ | — |
| Room service order | ✅ | — |
| Housekeeping request | ✅ | — |
| Spa booking | ✅ | — |
| Restaurant reservation | ✅ | — |
| Events & Activities | ✅ | — |
| Emergency SOS | ✅ | — |
| Spending tracker | ✅ | — |
| My Plans (timeline) | ✅ | — |
| Admin dashboard | — | ✅ |
| Room & guest management | — | ✅ |
| Order tracking (live) | — | ✅ |
| Menu management | — | ✅ |
| Event management | — | ✅ |
| Emergency alert panel | — | ✅ |
| Housekeeping management | — | ✅ |

Role is stored in Firestore (`users/{uid}.role`) and enforced at login via `AuthWrapper`.

---

## 📋 Use Cases

The full use case documentation covering all 21 scenarios (Guest, Admin, and System actors) is available in [`use_cases.md`](./use_cases.md).

---

## 📦 Key Dependencies

```yaml
firebase_core: ^4.2.1
firebase_auth: ^6.1.2
cloud_firestore: ^6.1.0
firebase_storage: ^13.0.5
google_sign_in: ^6.2.1
flutter_facebook_auth: ^7.1.2
flutter_local_notifications: ^18.0.1
audioplayers: ^6.1.0
flutter_map: ^8.2.2
geolocator: ^10.1.0
qr_flutter: ^4.1.0
rxdart: ^0.28.0
google_fonts: ^6.1.0
connectivity_plus: ^6.1.4
image_picker: ^1.2.1
timezone: ^0.10.0
```

---


