# **🌿 Aura Track**

**Gamify your wellness journey. Grow your garden, grow yourself.**

Aura Track is a Flutter-based habit tracking application that blends wellness with gamification. Unlike standard habit trackers that rely solely on checkboxes, Aura Track utilizes device sensors (accelerometer, pedometer) to verify interactive habits, rewarding users with a blooming digital garden.

## **📱 Features**

### **🎮 Interactive Sensor Habits**

Aura Track uses hardware sensors to ensure you are actually performing the habit:

* **💧 Hydration Game:** Uses the **accelerometer**. Tilt your phone to pour water into a virtual glass.  
* **🧘 Meditation Mode:** Uses the **gyroscope/accelerometer**. Detects movement to ensure you stay perfectly still for 60 seconds.  
* **🏃 Walking Challenge:** Uses the **pedometer**. Tracks your real-world steps to verify movement goals.

### **🌻 Gamified Dashboard**

* **Digital Garden:** Your home screen features a procedural garden. The more points you earn, the more flowers bloom.  
* **Streaks & Glow:** Maintain a 7-day streak to make your garden "glow" at night.  
* **Daily Quotas:** visual progress bars for daily interactive goals.

### **📊 Social & Tracking**

* **Leaderboard:** Compete with other users in the "Community Garden".  
* **Calendar View:** Track your consistency with a monthly history view.  
* **Profile Customization:** Choose avatars and update your display name.

### **🛡️ Role-Based Access**

* **User Portal:** Standard habit tracking.  
* **Admin Console:** Dedicated dashboard for managing users and creating global challenges.

## **🛠️ Tech Stack**

* **Framework:** [Flutter](https://flutter.dev/) (Dart)  
* **Backend as a Service:** [Supabase](https://supabase.com/)  
* **State Management:** setState & Streams  
* **Key Packages:**  
  * supabase\_flutter (Auth & Database)  
  * sensors\_plus (Accelerometer/Gyroscope)  
  * pedometer (Step counting)  
  * audioplayers (Sound effects)  
  * table\_calendar (History view)  
  * flutter\_dotenv (Environment security)

## **📂 Project Structure**

lib/  
├── common/             \# Reusable widgets and utils  
│   ├── utils/          \# Validators, Snackbars  
│   └── widgets/        \# CustomTextField, UserAvatar, Dialogs  
├── core/  
│   └── services/       \# AuthService, HabitRepository  
├── features/  
│   ├── admin\_panel/    \# Admin Dashboard logic  
│   ├── auth/           \# Login, Signup, OTP, AuthGate  
│   ├── dashboard/      \# UserHome, Leaderboard, Profile  
│   └── sensor\_games/   \# Logic for Water, Walking, and Meditation games  
├── assets/             \# Images and Sound effects  
└── main.dart           \# Entry point

## **📄 License**

Distributed under the MIT License. See LICENSE for more information.

\<p align="center"\>  
Built with 💙 and Flutter  
\</p\>