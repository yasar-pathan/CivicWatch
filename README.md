# 🏙️ Civic Watch

**Empowering Citizens, Improving Cities.**

Civic Watch is a modern Flutter application designed to bridge the gap between citizens and municipal authorities. It allows users to report civic issues (like potholes, garbage, streetlights) in real-time, track their resolution status, and contribute to a better living environment.

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/firebase-%23039BE5.svg?style=for-the-badge&logo=firebase)

---

## ✨ Features

### 👤 For Citizens
- **Real-time Reporting**: Capture photos, auto-detect location, and describe issues in seconds.
- **Smart Dashboard**: View city-wide statistics, impact scores, and recent reports.
- **Location Privacy**: Reports are filtered by city, ensuring you focus on your local community.
- **Track Status**: Monitor your reports as they move from 'Reported' to 'In Progress' to 'Resolved'.
- **Interactive UI**: Beautiful animated interfaces, dark mode support, and smooth transitions.
- **My Reports**: Manage your history with options to View, Edit, or Delete reports.

### 🏛️ For Authorities (Planned)
- View heatmaps of issues.
- Update status of reported issues.
- Prioritize tasks based on upvotes and severity.

---

## 📱 Screenshots

| Dashboard | Report Issue | details |
|:---------:|:------------:|:-------:|
| <img src="assets/screenshots/dashboard.png" width="200" alt="Dashboard" /> | <img src="assets/screenshots/report.png" width="200" alt="Report Issue" /> | <img src="assets/screenshots/details.png" width="200" alt="Issue Details" /> |

*(Note: Add screenshots to an `assets/screenshots` folder)*

---

## 🛠️ Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase
  - **Authentication**: secure email/password login.
  - **Firestore**: NoSQL database for real-time data syncing.
  - **Storage**: Scalable image hosting for issue photos.
- **State Management**: Stateful Widgets + Streams
- **Maps**: Geolocation & Geocoding

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) installed.
- A Firebase project set up.

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yasar-pathan/CivicWatch.git
   cd civic_watch
   ```

2. **Install Connections**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a project on [Firebase Console](https://console.firebase.google.com/).
   - Add Android/iOS apps to the project.
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS).
   - Place them in `android/app/` and `ios/Runner/` respectively.
   - Enable **Authentication** (Email/Password).
   - Create **Firestore Database** and **Storage** bucket.

4. **Run the App**
   ```bash
   flutter run
   ```

---

## 📂 Project Structure

```
lib/
├── config/              # App configuration & routes
├── core/                # Constants, themes, utilities
├── models/              # Data models (Issue, User)
├── services/            # Firebase services (Auth, DB)
├── views/
│   ├── authentication/  # Login, Signup screens
│   ├── citizen/         # Dashboard, Report, My Reports
│   └── widgets/         # Reusable UI components
└── main.dart            # Entry point
```

---

## 🔒 Security & Privacy

- **Data Isolation**: Users only see issues relevant to their registered city.
- **Secure Storage**: API keys and sensitive configuration files (`google-services.json`) are git-ignored for security.

---

## 🤝 Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---

<p align="center">
  Built with ❤️ by Yasar Pathan
</p>
