# Wajeeh Mobile Application Travle Itineray


## 🧭 Project Overview
Wajeeh is a mobile application that generates personalized travel itineraries for Oman and GCC destinations, integrating AI-powered recommendations, multilingual translation, cultural & heritage exploration, and offline navigation. The system helps travelers choose hotels, restaurants, heritage sites, transportation, souvenirs, and more based on their budget, duration of stay, and preferences.

The project supports Oman Vision 2040 goals through digital transformation, tourism innovation, and smarter travel experiences.

## 🔑 Key Features
**Trip Planning:**
- Select hotels, transportation, restaurants, souvenirs, cultural sites, and heritage attractions
- AI-based suggestions according to budget & duration
- Save, edit, share itineraries

**AI & Smart Assistance:**
- Multilingual Translation (Arabic/English)
- AI Recommendation Engine
- Autocomplete search & personalized suggestions

**Navigation:**
- Google Maps Integration
- Search and filter by location, distance, budget
- Offline mode using SQLite (no internet required)

**Support & Notifications:**
- Smart reminders
- Weather alerts (future update)
- Feedback & ratings

**Admin Dashboard:**
- Manage user accounts
- Manage system content
- View user feedback

## 🧰 Tech Stack

| Layer        | Technology                     |
|--------------|--------------------------------|
| **Frontend** | Flutter (Dart), Material Design|
| **Backend**  | Firebase (Auth, Firestore DB, Storage)|
| **AI/ML**    | Firebase ML Kit, Google Cloud Translation API|
| **Database** | Firebase Firestore, SQLite (offline) |
| **DevOps**   | GitHub, GitHub Actions (CI/CD), Firebase Hosting|


## 👥 Team Structure
| Team           | Members                                                                 |
|----------------|-------------------------------------------------------------------------|
| **Team Leader**| Jokha Al-Harthy                                                         |
| **Contributors**| Rayan Al-Rawahi & Nairoz Al-Alwai                                      |
| **Supervisor**| Ruel Micheal                                                             |


## 📱 Run the Flutter App
- Install Flutter (version 3.x or above)
- Open the project in VS Code or Android Studio
- cd folder
- flutter pub get
- Connect an Android device or emulator
- flutter run

## 📂 Folder Structure
```
├── android/                      # Native Android project files
│
├── lib/                          # Main Flutter application source code
│   ├── pages/                    # All UI screens (onboarding, auth, home, etc.)
│   ├── providers/                # State management using Provider
│   ├── services/                 # App backend services (Firebase, API helpers, auth logic)
│   ├── widgets/                  # Reusable UI components
│   ├── app_theme.dart            # App color theme & styles
│   ├── firebase_options.dart     # Firebase initialization (auto-generated)
│   └── main.dart                 # Application entry point
│
├── functions/                    # Firebase Cloud Functions (backend)
│   ├── index.js                  # Main cloud function
│   ├── package.json              # Dependencies
│   └── package-lock.json
│
├── images/                       # Image assets used throughout the UI
│
├── pubspec.yaml                  # Flutter dependencies & assets config
├── firebase.json                 # Firebase tools config
├── .firebaserc                   # Firebase project reference
├── .gitignore                    # Ignored files for version control
└── README.md                     # Project documentation
```


