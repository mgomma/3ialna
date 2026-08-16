# 3ialna Parental Control App

A comprehensive Flutter mobile application with Drupal backend integration for Islamic parental control and child device management.

## Features

### 👤 User Roles & Authentication
- **Admin**: Can list and audit parent accounts
- **Master Parent**: Can create and manage default child profiles
- **Parent**: Can register, manage child devices, and customize settings
- Secure JWT-based authentication
- Role-based access control

### 🧑‍💼 Master Parent Features
- Create default settings profiles based on:
  - Gender (Boys, Girls)
  - Age group (2-3 years, 4-6 years, etc.)
  - Mother tongue (Arabic, English)
  - Country of origin and residence
- Personal profile and introduction
- Default lock durations and app usage limits
- Custom notification messages (duas)

### 📱 Parent App Features
- View registered child devices
- Access daily activity reports
- Modify device-specific settings remotely
- Set time limits for top 10 most-used game apps
- Browse and apply default profiles from master parents

### 🕌 Prayer Time Lock Settings
- Integration with adhan package for prayer time calculations
- Set lock durations per prayer
- Special rules for Friday Dhuhr
- Custom notification messages 2 minutes before lock
- Location-based prayer time calculation

### ⏱️ App Usage Limits
- Automatic detection of top 10 most-used game apps
- Daily time limits via backend
- Prevention of access to apps exceeding limits
- Social media platform tracking via browser

### 📊 Daily Activity Reports
- Daily usage logs from child devices
- Data organized by app category and time spent
- Parent access to reports per child and per day

### 🌍 Localization & Language Support
- Full Arabic and English support
- RTL (Right-to-Left) layout for Arabic
- Localized prayer times and notifications
- Language-specific UI elements

## Project Structure

```
lib/
├── core/                  # App constants, models, providers, routes, services, theme, utils
├── features/              # Feature-specific modules (auth, child_devices, home, master_parents, reports, settings)
└── main.dart              # App entry point
```

## Setup Instructions

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Dart SDK
- Android Studio / VS Code
- Git

### Installation

1.  **Clone the repository**
    ```bash
    git clone <repository-url>
    cd parental_control_app
    ```

2.  **Install dependencies**
    ```bash
    flutter pub get
    ```

3.  **Generate code (if needed)**
    ```bash
    flutter packages pub run build_runner build
    ```

4.  **Run the app**
    ```bash
    flutter run
    ```

### Configuration

1.  **API Configuration**
    - Update `lib/core/constants/app_constants.dart`
    - Set the correct base URL for your Drupal backend
    - Configure API endpoints as needed

2.  **Localization**
    - Add translation files in `assets/translations/`
    - Update `lib/core/utils/app_localizations.dart` for new languages

3.  **Theme Customization**
    - Modify `lib/core/theme/app_theme.dart`
    - Update colors, fonts, and styling as needed

## Dependencies

### Core Dependencies
- `flutter`: Flutter SDK
- `provider`: State management
- `dio`: HTTP client for API calls
- `shared_preferences`: Local storage
- `flutter_localizations`: Internationalization
- `intl`: Date and number formatting

### Feature Dependencies
- `adhan`: Prayer time calculations
- `geolocator`: Location services
- `permission_handler`: Device permissions
- `device_info_plus`: Device information
- `package_info_plus`: App information
- `flutter_secure_storage`: Secure storage

### Development Dependencies
- `flutter_lints`: Code linting
- `json_annotation`: JSON serialization
- `json_serializable`: Code generation
- `build_runner`: Code generation runner

## API Integration

The app integrates with a Drupal backend at `https://3ialna.net`. See `DRUPAL_API_SPECIFICATION.md` for complete API documentation.

### Key API Endpoints
- Authentication: `/api/v1/auth/*`
- User Management: `/api/v1/user/*`
- Child Devices: `/api/v1/child-devices/*`
- Master Parents: `/api/v1/master-profiles/*`
- Prayer Times: `/api/v1/prayer-times`
- Reports: `/api/v1/reports/*`

## Development Guidelines

### Code Style
- Follow Flutter/Dart conventions
- Use meaningful variable and function names
- Add comments for complex logic
- Maintain consistent indentation

### State Management
- Use Provider for state management
- Keep providers focused on specific features
- Avoid deep nesting of providers

### Error Handling
- Implement proper error handling for API calls
- Show user-friendly error messages
- Log errors for debugging

### Testing
- Write unit tests for business logic
- Add widget tests for UI components
- Test API integration with mock data

## Contributing

1.  Fork the repository
2.  Create a feature branch
3.  Make your changes
4.  Add tests if applicable
5.  Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions, please contact the development team or create an issue in the repository.

## Development Roadmap

This roadmap outlines the planned development phases for the 3ialna Parental Control & Family Safety App, integrating core parental control features with Islamic functionalities and cultural considerations for Arab countries.

### Phase 1: Core Parental Control Features (MVP) - Android First

*   **User Authentication & Profile Management**:
    *   Implement secure JWT-based authentication.
    *   Develop user role management (Admin, Master Parent, Parent).
    *   Create UI for registration, login, and profile editing.
*   **App & Game Blocker**:
    *   **Android**: Implement `AccessibilityService` to detect and block app launches.
*   **Web Blocker (Basic)**:
    *   **Android**: Implement basic web filtering using a local VPN service.
*   **Daily Usage Limits**:
    *   **Android**: Utilize `UsageStatsManager` and `AccessibilityService` to track and enforce daily screen time limits.
*   **Family Locator**:
    *   Implement real-time location tracking and display on a map.
*   **SOS/Panic Button**:
    *   Implement sending emergency alerts with location data.

### Phase 2: Islamic Features Integration

*   **Prayer Time API Integration**:
    *   Integrate `adhan` package for prayer time calculations.
    *   Implement location-based prayer times and manual city selection.
    *   Develop customizable notification system for each prayer time with Adhan sounds.
*   **Qibla Direction**:
    *   Implement compass feature using device sensors.
*   **Islamic Content Filtering (Initial Halal Mode)**:
    *   Integrate with a chosen Islamic filtering service or implement basic keyword-based filtering.

### Phase 3: Advanced Features & Refinements

*   **Schedule Screen Time & Downtime**:
    *   Implement advanced scheduling for device usage.
*   **Individual App Limits**:
    *   Extend app limits to all installed applications.
*   **FamilyPause (Instant Lock)**:
    *   Implement instant device locking functionality.
*   **Activity Reports Enhancement**:
    *   Improve data visualization and reporting for app usage, browsing history, and location history.
*   **Social Media Monitoring (Enhanced)**:
    *   **Android**: Refine `AccessibilityService` for more comprehensive in-app monitoring.
    *   **iOS**: Investigate and implement any feasible (privacy-compliant) social media monitoring.
*   **TeenSafe Drive**:
    *   Implement speed monitoring and alert system.
*   **Low Battery Alerts**:
    *   Implement notifications for low battery levels.
*   **UI/UX Refinements**:
    *   Conduct user testing with Arab users and refine UI/UX based on feedback, ensuring cultural appropriateness.

### Phase 4: Testing & Deployment

*   **Comprehensive Testing**:
    *   Perform unit, integration, UI, performance, and security testing.
*   **Beta Testing**:
    *   Conduct beta testing with a diverse group of users in Arab countries.
*   **Deployment**:
    *   Prepare for deployment to Google Play Store.

### Future Enhancements

*   **iOS Version**: Develop an iOS version of the application.
*   **Multi-Language Support Expansion**:
    *   Expand language options beyond Arabic and English.
*   **Educational Content Integration**:
    *   Integrate Islamic educational content for children.
*   **Community Features**:
    *   Develop features for parents to connect and share.

## Changelog

### 2026-05-09

*   **Android Core Functionality Improvements**:
    *   **Unified Storage Layer**: Aligned Flutter `ParentalControlStorageService` with native Android background services. This ensures that app blocks, time limits, and schedules configured in the UI are now correctly recognized and enforced by the native layer.
    *   **Enhanced Schedule Enforcement**: Implemented more robust schedule checking in the native `MonitorForegroundService`. The service now correctly parses the JSON schedule format from Flutter and enforces restrictions during the specified time windows.
    *   **Robust System App Filtering**: Improved the filtering logic in both `AppBlockingAccessibilityService.kt` and `MonitorForegroundService.kt` to prevent essential system components (like settings, dialer, and the default launcher) from being accidentally blocked, ensuring the device remains functional.

## References

[1] Aladhan API. (n.d.). *Prayer Times API*. Retrieved from [https://aladhan.com/prayer-times-api](https://aladhan.com/prayer-times-api)
[2] Aladhan API. (n.d.). *Calculation Methods*. Retrieved from [https://aladhan.com/calculation-methods](https://aladhan.com/calculation-times-api)
[3] Kahf Guard. (n.d.). *Shield Up Against Online Haram*. Retrieved from [https://kahfguard.com/](https://kahfguard.com/)
[4] Al-Hudud. (n.d.). *Block Haram, Browse Halal for Muslims*. Retrieved from [https://github.com/HamzaaAkmal/Al-Hudud-Blocks-Haram-Browse-Halal](https://github.com/HamzaaAkmal/Al-Hudud-Blocks-Haram-Browse-Halal)
[5] Material Design. (n.d.). *Bidirectionality*. Retrieved from [https://m2.material.io/design/usability/bidirectionality.html](https://m2.material.io/design/usability/bidirectionality.html)
[6] Material Design 3. (n.d.). *Bidirectionality & RTL - Layout*. Retrieved from [https://m3.material.io/foundations/layout/understanding-layout/bidirectionality-rtl](https://m3.material.io/foundations/layout/understanding-layout/bidirectionality-rtl)
[7] Toru, C. (2021, July 26). *Supporting RTL Design on Android*. ProAndroidDev. Retrieved from [https://proandroiddev.com/supporting-rtl-design-on-android-d6ef0ac31874](https://proandroiddev.com/supporting-rtl-design-on-android-d6ef0ac31874)
[8] Alashwali, E. (2022). Saudi parents’ privacy concerns about their children’s smart device apps. *ScienceDirect*. Retrieved from [https://www.sciencedirect.com/science/article/abs/pii/S2212868922000216](https://www.sciencedirect.com/science/article/abs/pii/S2212868922000216)
