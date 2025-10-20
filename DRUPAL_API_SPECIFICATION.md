# Drupal Backend API Specification
## 3ialna Parental Control System

**Base URL:** `https://3ialna.net/api/v1`

---

## 🔐 Authentication & Authorization

### 1. User Registration
```http
POST /auth/register
Content-Type: application/json

{
  "email": "parent@example.com",
  "password": "securePassword123",
  "firstName": "Ahmed",
  "lastName": "Ali",
  "phone": "+966501234567",
  "country": "SA",
  "language": "ar"
}
```

**Response:**
```json
{
  "success": true,
  "message": "User registered successfully",
  "data": {
    "user": {
      "id": 123,
      "email": "parent@example.com",
      "firstName": "Ahmed",
      "lastName": "Ali",
      "role": "parent",
      "isActive": true,
      "createdAt": "2024-01-15T10:30:00Z"
    },
    "tokens": {
      "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "expiresIn": 3600
    }
  }
}
```

### 2. User Login
```http
POST /auth/login
Content-Type: application/json

{
  "email": "parent@example.com",
  "password": "securePassword123"
}
```

### 3. Token Refresh
```http
POST /auth/refresh
Content-Type: application/json
Authorization: Bearer {refreshToken}

{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### 4. Password Reset
```http
POST /auth/reset-password
Content-Type: application/json

{
  "email": "parent@example.com"
}
```

### 5. Logout
```http
POST /auth/logout
Authorization: Bearer {accessToken}
```

---

## 👤 User Management

### 1. Get User Profile
```http
GET /user/profile
Authorization: Bearer {accessToken}
```

### 2. Update User Profile
```http
PUT /user/profile
Authorization: Bearer {accessToken}
Content-Type: application/json

{
  "firstName": "Ahmed",
  "lastName": "Ali",
  "phone": "+966501234567",
  "language": "ar",
  "country": "SA"
}
```

### 3. List Parent Accounts (Admin Only)
```http
GET /admin/parents?page=1&limit=20&search=ahmed
Authorization: Bearer {adminToken}
```

---

## 🧑‍💼 Master Parent Features

### 1. Create Master Parent Profile
```http
POST /master-profiles
Authorization: Bearer {masterParentToken}
Content-Type: application/json

{
  "title": "Experienced Child Psychologist",
  "description": "Specialized in Islamic parenting and child development",
  "experience": "15 years of experience in child psychology and Islamic education",
  "specializations": ["Child Psychology", "Islamic Education", "Behavioral Therapy"],
  "yearsOfExperience": 15,
  "profileImage": "base64_encoded_image_or_url"
}
```

### 2. Update Master Parent Profile
```http
PUT /master-profiles/{id}
Authorization: Bearer {masterParentToken}
Content-Type: application/json

{
  "title": "Updated Title",
  "description": "Updated description",
  "experience": "Updated experience"
}
```

### 3. List Master Parent Profiles
```http
GET /master-profiles?page=1&limit=20&search=psychology
Authorization: Bearer {accessToken}
```

### 4. Get Master Parent Profile Details
```http
GET /master-profiles/{id}
Authorization: Bearer {accessToken}
```

### 5. Create Default Settings Profile
```http
POST /master-profiles/{masterParentId}/default-profiles
Authorization: Bearer {masterParentToken}
Content-Type: application/json

{
  "name": "Boys 4-6 Years - Arabic",
  "description": "Default settings for Arabic-speaking boys aged 4-6",
  "gender": "male",
  "ageGroup": "4-6",
  "motherTongue": "ar",
  "countryOfOrigin": "SA",
  "countryOfResidence": "SA",
  "settings": {
    "lockDurationMinutes": 30,
    "appUsageLimitMinutes": 60,
    "notificationMessage": "وقت الصلاة، دعاء قبل الإغلاق",
    "language": "ar",
    "appLimits": {
      "com.android.games": 30,
      "com.social.media": 15
    },
    "prayerSettings": {
      "fajrLockMinutes": 20,
      "dhuhrLockMinutes": 15,
      "asrLockMinutes": 15,
      "maghribLockMinutes": 20,
      "ishaLockMinutes": 25,
      "fridayDhuhrLockMinutes": 30,
      "notificationMessage": "وقت الصلاة، دعاء قبل الإغلاق",
      "isEnabled": true
    }
  }
}
```

### 6. List Default Profiles by Master Parent
```http
GET /master-profiles/{masterParentId}/default-profiles
Authorization: Bearer {accessToken}
```

### 7. Update Default Profile
```http
PUT /master-profiles/{masterParentId}/default-profiles/{profileId}
Authorization: Bearer {masterParentToken}
Content-Type: application/json
```

### 8. Delete Default Profile
```http
DELETE /master-profiles/{masterParentId}/default-profiles/{profileId}
Authorization: Bearer {masterParentToken}
```

---

## 📱 Parent App Features

### 1. Register Child Device
```http
POST /child-devices
Authorization: Bearer {parentToken}
Content-Type: application/json

{
  "deviceName": "Ahmed's Tablet",
  "deviceId": "unique_device_identifier",
  "deviceType": "android",
  "childName": "Ahmed",
  "childAge": 5,
  "childGender": "male"
}
```

### 2. List Child Devices
```http
GET /child-devices
Authorization: Bearer {parentToken}
```

### 3. Get Child Device Details
```http
GET /child-devices/{id}
Authorization: Bearer {parentToken}
```

### 4. Update Child Device Settings
```http
PUT /child-devices/{id}/settings
Authorization: Bearer {parentToken}
Content-Type: application/json

{
  "lockDurationMinutes": 45,
  "appUsageLimitMinutes": 90,
  "notificationMessage": "وقت الإغلاق، دعاء",
  "language": "ar",
  "appLimits": {
    "com.android.games": 45,
    "com.social.media": 20
  },
  "prayerSettings": {
    "fajrLockMinutes": 25,
    "dhuhrLockMinutes": 20,
    "asrLockMinutes": 20,
    "maghribLockMinutes": 25,
    "ishaLockMinutes": 30,
    "fridayDhuhrLockMinutes": 35,
    "notificationMessage": "وقت الصلاة، دعاء قبل الإغلاق",
    "isEnabled": true
  }
}
```

### 5. Apply Default Profile to Device
```http
POST /child-devices/{id}/apply-profile
Authorization: Bearer {parentToken}
Content-Type: application/json

{
  "profileId": 123
}
```

### 6. Lock/Unlock Device
```http
POST /child-devices/{id}/lock
Authorization: Bearer {parentToken}
Content-Type: application/json

{
  "isLocked": true,
  "lockUntil": "2024-01-15T15:30:00Z",
  "reason": "prayer_time"
}
```

### 7. Get Device Current Status
```http
GET /child-devices/{id}/status
Authorization: Bearer {parentToken}
```

---

## 🕌 Prayer Time Management

### 1. Get Prayer Times
```http
GET /prayer-times?latitude=24.7136&longitude=46.6753&date=2024-01-15
Authorization: Bearer {accessToken}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "date": "2024-01-15",
    "location": {
      "latitude": 24.7136,
      "longitude": 46.6753,
      "city": "Riyadh",
      "country": "SA"
    },
    "prayerTimes": [
      {
        "name": "fajr",
        "time": "2024-01-15T05:30:00Z",
        "isLocked": true,
        "lockDurationMinutes": 20
      },
      {
        "name": "dhuhr",
        "time": "2024-01-15T12:15:00Z",
        "isLocked": true,
        "lockDurationMinutes": 15
      },
      {
        "name": "asr",
        "time": "2024-01-15T15:45:00Z",
        "isLocked": true,
        "lockDurationMinutes": 15
      },
      {
        "name": "maghrib",
        "time": "2024-01-15T18:20:00Z",
        "isLocked": true,
        "lockDurationMinutes": 20
      },
      {
        "name": "isha",
        "time": "2024-01-15T19:50:00Z",
        "isLocked": true,
        "lockDurationMinutes": 25
      }
    ]
  }
}
```

### 2. Update Prayer Settings for Device
```http
PUT /child-devices/{id}/prayer-settings
Authorization: Bearer {parentToken}
Content-Type: application/json

{
  "fajrLockMinutes": 25,
  "dhuhrLockMinutes": 20,
  "asrLockMinutes": 20,
  "maghribLockMinutes": 25,
  "ishaLockMinutes": 30,
  "fridayDhuhrLockMinutes": 35,
  "notificationMessage": "وقت الصلاة، دعاء قبل الإغلاق",
  "isEnabled": true
}
```

---

## ⏱️ App Usage Management

### 1. Submit App Usage Data
```http
POST /child-devices/{id}/app-usage
Authorization: Bearer {deviceToken}
Content-Type: application/json

{
  "date": "2024-01-15",
  "usageData": [
    {
      "packageName": "com.android.games",
      "appName": "Kids Games",
      "category": "games",
      "usageTimeMinutes": 25,
      "lastUsed": "2024-01-15T14:30:00Z"
    },
    {
      "packageName": "com.social.media",
      "appName": "Social App",
      "category": "social",
      "usageTimeMinutes": 10,
      "lastUsed": "2024-01-15T15:00:00Z"
    }
  ]
}
```

### 2. Get Top 10 Most Used Apps
```http
GET /child-devices/{id}/top-apps?period=week
Authorization: Bearer {parentToken}
```

### 3. Set App Usage Limits
```http
PUT /child-devices/{id}/app-limits
Authorization: Bearer {parentToken}
Content-Type: application/json

{
  "appLimits": {
    "com.android.games": 45,
    "com.social.media": 20,
    "com.education.apps": 60
  }
}
```

### 4. Get Current App Usage Status
```http
GET /child-devices/{id}/app-usage/status
Authorization: Bearer {parentToken}
```

---

## 📊 Daily Activity Reports

### 1. Submit Daily Report
```http
POST /child-devices/{id}/daily-report
Authorization: Bearer {deviceToken}
Content-Type: application/json

{
  "date": "2024-01-15",
  "totalUsageMinutes": 120,
  "appUsage": {
    "com.android.games": 45,
    "com.education.apps": 30,
    "com.social.media": 15
  },
  "categoryUsage": {
    "games": 45,
    "education": 30,
    "social": 15,
    "browser": 30
  },
  "lockTimeMinutes": 60,
  "blockedApps": ["com.blocked.app"],
  "accessedApps": ["com.android.games", "com.education.apps"]
}
```

### 2. Get Daily Reports
```http
GET /child-devices/{id}/reports/daily?startDate=2024-01-01&endDate=2024-01-31
Authorization: Bearer {parentToken}
```

### 3. Get Activity Summary
```http
GET /child-devices/{id}/reports/summary?period=week
Authorization: Bearer {parentToken}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "period": "week",
    "totalUsageMinutes": 840,
    "averageDailyUsage": 120,
    "mostUsedApps": [
      {
        "packageName": "com.android.games",
        "appName": "Kids Games",
        "totalMinutes": 300,
        "percentage": 35.7
      }
    ],
    "categoryBreakdown": {
      "games": 300,
      "education": 240,
      "social": 180,
      "browser": 120
    },
    "lockTimeMinutes": 420,
    "complianceRate": 85.5
  }
}
```

---

## 🌍 Localization & Language Support

### 1. Get Available Languages
```http
GET /languages
Authorization: Bearer {accessToken}
```

### 2. Get Translations
```http
GET /translations?language=ar&module=parental_control
Authorization: Bearer {accessToken}
```

---

## 🔐 Security & Access Control

### Authentication Headers
All protected endpoints require:
```http
Authorization: Bearer {accessToken}
Content-Type: application/json
```

### Rate Limiting
- Login attempts: 5 per minute per IP
- API calls: 100 per minute per user
- Password reset: 3 per hour per email

### Input Validation
- Email format validation
- Password strength requirements (min 8 chars, mixed case, numbers)
- Phone number format validation
- Device ID uniqueness validation

### Error Responses
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid email format",
    "details": {
      "field": "email",
      "value": "invalid-email"
    }
  }
}
```

### Common Error Codes
- `UNAUTHORIZED`: Invalid or expired token
- `FORBIDDEN`: Insufficient permissions
- `VALIDATION_ERROR`: Invalid input data
- `NOT_FOUND`: Resource not found
- `RATE_LIMITED`: Too many requests
- `SERVER_ERROR`: Internal server error

---

## 📱 Device Integration

### Device Registration Flow
1. Parent registers device via mobile app
2. Device receives unique device token
3. Device uses token for all subsequent API calls
4. Device submits usage data and reports

### Real-time Updates
- WebSocket connection for real-time lock/unlock commands
- Push notifications for prayer time alerts
- Background sync for usage data

### Offline Support
- Device caches settings locally
- Queues usage data when offline
- Syncs when connection restored

---

## 🗄️ Database Schema (Drupal)

### Core Tables
- `users` - User accounts and authentication
- `user_roles` - Role assignments
- `child_devices` - Registered child devices
- `device_settings` - Device-specific settings
- `master_parent_profiles` - Master parent information
- `default_profiles` - Default settings profiles
- `prayer_settings` - Prayer time configurations
- `app_usage_logs` - Daily app usage data
- `daily_reports` - Daily activity reports
- `app_limits` - Per-app usage limits

### Relationships
- Users → Child Devices (1:many)
- Master Parents → Default Profiles (1:many)
- Child Devices → Daily Reports (1:many)
- Child Devices → App Usage Logs (1:many)

---

## 🚀 Deployment & Configuration

### Environment Variables
```bash
DRUPAL_BASE_URL=https://3ialna.net
JWT_SECRET=your_jwt_secret_key
ADHAN_API_KEY=your_adhan_api_key
RATE_LIMIT_ENABLED=true
WEBSOCKET_ENABLED=true
```

### Drupal Modules Required
- RESTful Web Services
- JSON:API
- JWT Authentication
- Rate Limiting
- WebSocket (custom module)
- Adhan Integration (custom module)

### Security Considerations
- HTTPS enforcement
- CORS configuration
- Input sanitization
- SQL injection prevention
- XSS protection
- CSRF tokens for state-changing operations
