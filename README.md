<div align="center">
  <h1>🏙️ CivicWatch</h1>
  <p><em>Empowering Citizens, Streamlining City Management.</em></p>

  <p>
    <a href="https://flutter.dev/"><img src="https://img.shields.io/badge/Made_with-Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"></a>
    <a href="https://dart.dev/"><img src="https://img.shields.io/badge/Language-Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart"></a>
    <a href="https://firebase.google.com/"><img src="https://img.shields.io/badge/Backend-Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=white" alt="Firebase"></a>
    <a href="https://developers.google.com/maps"><img src="https://img.shields.io/badge/Maps-Google_Maps-4285F4?style=for-the-badge&logo=google-maps&logoColor=white" alt="Google Maps"></a>
  </p>
</div>

<hr />

## 📖 Overview

**CivicWatch** is a next-generation civic engagement platform that bridges the communication gap between citizens and government authorities. Whether it's a pothole, a broken streetlight, or a public safety hazard, CivicWatch makes it incredibly simple to report, track, and resolve structural issues inside your city. 

With interactive maps, real-time push notifications, and a multi-tiered governing hierarchy, we provide a structured, transparent, and swift approach to urban maintenance.

---

## ✨ Key Features

### 👤 For Citizens
- **📍 Real-time Spatial Reporting**: Drop a pin on the integrated Google Map or let GPS auto-detect your location. Upload images and describe the issue instantly.
- **🗺️ Interactive Map View**: Explore issues around you via an immersive Map view. Tap on issue markers for beautifully animated quick-insight cards.
- **🔔 Push Notifications** *(Configured)*: Stay completely up-to-date with alerts when authorities recognize, work on, or resolve your issues.
- **💬 Community Interactions**: Comment on issues and communicate directly with authorities to foster transparency.
- **📊 Real-time Dashboard**: View issue status progression (*Reported* → *Recognized* → *In Work* → *Resolved*) seamlessly.

### 🏛️ For City & State Authorities
- **🏢 Territory Scoping**: City authorities are conditionally restricted to viewing and managing issues exclusively within their registered municipality.
- **⚙️ Workflow Management**: Easily toggle report statuses and keep citizens informed natively.
- **📈 Escalation System**: Issues taking too long dynamically escalate to **State Authorities** for higher-level intervention.
- **🔐 Secure RBAC**: Strict Role-Based Access Control enforcing robust database safety via Firebase Security Rules.

---

## 🛠 Tech Stack

**Frontend Framework**
- **Flutter** & **Dart**: Crafting natively compiled applications for mobile from a single codebase.
- **Google Maps Flutter**: Driving interactive, fluid mapping and customized UI annotations.

**Backend Services (Firebase)**
- **Cloud Firestore**: Our incredibly fast NoSQL database for syncing issues, comments, and users in real-time.
- **Firebase Auth**: Robust login/signup flow mapping 4 distinct user roles dynamically.
- **Cloud Storage**: Highly scalable cloud bucket storing citizen upload evidence.
- **Cloud Functions (Node/TypeScript)**: Backend serverless logic seamlessly managing automated push notifications.
- **Cloud Messaging (FCM)**: Dedicated infrastructure ensuring background notifications.

---

## 📸 App Interface

> *Below are placeholders representing the interface flow. Actual screenshots can be found in ssets/screenshots/.*

<div align="center">
  <img src="https://raw.githubusercontent.com/yasar-pathan/CivicWatch/main/assets/screenshots/dashboard.png" width="24%" alt="Dashboard" onerror="this.onerror=null; this.src='https://via.placeholder.com/200x400?text=Dashboard';" />&nbsp;
  <img src="https://raw.githubusercontent.com/yasar-pathan/CivicWatch/main/assets/screenshots/map_view.png" width="24%" alt="Interactive Map" onerror="this.onerror=null; this.src='https://via.placeholder.com/200x400?text=Map+View';" />&nbsp;
  <img src="https://raw.githubusercontent.com/yasar-pathan/CivicWatch/main/assets/screenshots/report.png" width="24%" alt="Report Issue" onerror="this.onerror=null; this.src='https://via.placeholder.com/200x400?text=Report';" />&nbsp;
  <img src="https://raw.githubusercontent.com/yasar-pathan/CivicWatch/main/assets/screenshots/details.png" width="24%" alt="Issue Details" onerror="this.onerror=null; this.src='https://via.placeholder.com/200x400?text=Details';" />
</div>

---

## 🚀 Getting Started

Follow these instructions to build and run the project on your local machine.

### Prerequisites
1. **[Flutter SDK](https://docs.flutter.dev/get-started/install)**
2. Application simulators (Android Studio / Xcode)
3. **Google Maps Platform API Key**
4. Active **Firebase Project**

### 📦 Installation

**1. Clone the repository:**
\\\ash
git clone https://github.com/yasar-pathan/CivicWatch.git
cd CivicWatch
\\\

**2. Install dependencies:**
\\\ash
flutter pub get
\\\

**3. Configure Google Maps:**
Inside the \ndroid/local.properties\ file, insert your API key:
\\\properties
MAPS_API_KEY=AIzaSy...Your_Google_Maps_Api_Key_Here
\\\

**4. Link Firebase Backend:**
Ensure your \google-services.json\ is placed strictly inside \ndroid/app/\ matching the active package name.

**5. Ignite the app:**
\\\ash
flutter run
\\\

---

## 📂 Project Architecture

A peek into the beautifully decoupled structure:

\\\	ext
lib/
 ├── core/                 # Typography, Custom App Themes, Configurations
 ├── models/               # Structured domain entities (Issues, Users, etc.)
 ├── providers/            # State Management implementations
 ├── services/             # Core business, Authentication & Cloud triggers
 ├── utils/                # Date formatters, validators & shared logic
 └── views/                # Presentation Layer
      ├── admin/           # Super-User controls
      ├── authority/       # State & City Authority dashboard interfaces 
      ├── citizen/         # Map instances, Dashboard panels & Report flows
      └── authentication/  # Login, Registration & Route Guards
\\\

---

## 🤝 Contributing

Contributions, issues, and feature requests are highly welcomed! Feel free to check the [issues page](https://github.com/yasar-pathan/CivicWatch/issues). 

1. Fork the Project
2. Create your Feature Branch (\git checkout -b feature/AmazingIdea\)
3. Commit your Changes (\git commit -m 'Implement amazing idea'\)
4. Push to the Branch (\git push origin feature/AmazingIdea\)
5. Open a Pull Request.

---

<div align="center">

**[⬆ Back to Top](#-civicwatch)**

*Designed, structured and built for the Community.* 🌍

</div>