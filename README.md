# 🌿 Velmora Health Ecosystem

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Platform](https://img.shields.io/badge/Platforms-Mobile%20%7C%20Web-blue?style=for-the-badge)]()

**Velmora** is a comprehensive dual-platform wellness ecosystem. It combines a premium Flutter mobile application for couples with a powerful administrative dashboard for system-wide orchestration.

---

<p align="center">
  <a href="#-mobile-app-demo">
    <img src="https://img.shields.io/badge/%F0%9F%93%B1%20Mobile%20App-View%20Demo-615ced?style=for-the-badge&logoWidth=40" alt="Mobile App" />
  </a>
  &nbsp;&nbsp;
  <a href="#-admin-panel-demo">
    <img src="https://img.shields.io/badge/%F0%9F%92%BB%20Admin%20Panel-View%20Demo-ff8c00?style=for-the-badge&logoWidth=40" alt="Admin Panel" />
  </a>
</p>

---

## 🚀 Dual-Platform Architecture

Velmora is built to scale, providing dedicated experiences for both end-users and administrators:

### 1. 👤 User Application (Mobile)
A high-end Flutter application designed for couples to manage their wellness journey.
*   **Intelligent Onboarding**: Tailored experience setup.
*   **Intimate Wellness**: Guided Kegel routines with progress analytics.
*   **Connection Games**: Gamified interactions ("Truth or Truth") to deepen partner proximity.
*   **AI Relationship Guru**: Real-time guidance and support.

### 2. 🛠 Admin Control Center (Web)
A data-driven administrative interface for platform oversight.
*   **Dashboard Analytics**: Monitor user growth, subscription distribution, and engagement metrics.
*   **User Lifecycle Management**: Real-time oversight of user profiles and platform access.
*   **Content Orchestration**: Manage Games, Kegel Exercises, and System Notifications.
*   **AI Configuration**: Control AI system prompts and behavioral logic.

---

## 🔄 Ecosystem Flow

```mermaid
graph LR
    subgraph "Admin Panel"
    A[Dashboard] --> B[Manage Content]
    B --> C[Configure AI]
    end
    
    subgraph "Mobile App"
    D[User Onboarding] --> E[Daily Routines]
    E --> F[AI Support]
    end
    
    C -.-> F
    B -.-> E
```

---

## 📱 Mobile App Demo

<div align="center">

| Home & Dashboard | Connection Games | Wellness Progress |
|:---:|:---:|:---:|
| <img src="demo/1.png" width="200" /> | <img src="demo/2.png" width="200" /> | <img src="demo/3.png" width="200" /> |
| **Main Hub** | **Gamification** | **Guided Routines** |

| Levels & Control | Daily Challenges | Interaction Data |
|:---:|:---:|:---:|
| <img src="demo/4.png" width="200" /> | <img src="demo/5.png" width="200" /> | <img src="demo/6.png" width="200" /> |

| Community | Personalization | Settings |
|:---:|:---:|:---:|
| <img src="demo/7.png" width="200" /> | <img src="demo/8.png" width="200" /> | <img src="demo/9.png" width="200" /> |

| AI Guidance | Future Roadmap |
|:---:|:---:|
| <img src="demo/10.png" width="200" /> | <img src="demo/11.png" width="200" /> |

</div>

---

## 💻 Admin Panel Demo

<div align="center">

| Dashboard Overview | User Management | Subscription Data |
|:---:|:---:|:---:|
| <img src="demo/12.png" width="400" /> | <img src="demo/13.png" width="400" /> | <img src="demo/14.png" width="400" /> |
| **Comprehensive Analytics** | **User Oversight** | **Revenue Tracking** |

| AI Configuration | Content Management | Exercise Routines |
|:---:|:---:|:---:|
| <img src="demo/15.png" width="400" /> | <img src="demo/16.png" width="400" /> | <img src="demo/17.png" width="400" /> |
| **System Prompts** | **Games Library** | **Kegel Modules** |

| Notifications | Support Center | System Settings |
|:---:|:---:|:---:|
| <img src="demo/18.png" width="400" /> | <img src="demo/19.png" width="400" /> | <img src="demo/20.png" width="400" /> |
| **Push Management** | **Ticketing System** | **Global Configs** |

| Security Logs |
|:---:|
| <img src="demo/21.png" width="400" /> |
| **System Audits** |

</div>

---

## 🛠 Technical Stack

### Mobile (Flutter)
- **Framework**: `Flutter ^3.8.1`
- **Backend**: Firebase Auth, Firestore, DBs

### Admin (Web)
- **Framework**: `React js`
- **Admin Panel Demo**: https://together-wellness.web.app/

### DataBase
- **Platform**: `Firebase`
- **Database**: `Firestore`
- **Authentication**: `Firebase Firestore 90% + Firebase Auth 10%`
- **Storage**: `DBS`

### Getting Started
1. **Clone**: `git clone https://github.com/HassanAmeer/velmora_health_app.git`
2. **Install**: `flutter pub get`
3. **Run**: `flutter run`

---

## 🔒 License
Proprietary Software. © 2024 Velmora Team. All rights reserved.