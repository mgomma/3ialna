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
├── core/
│   ├── constants/          # App constants and API endpoints
│   ├── models/            # Data models
│   ├── providers/         # State management providers
│   ├── routes/            # App routing
│   ├── services/          # API and business logic services
│   ├── theme/             # App theming
│   └── utils/             # Utilities and helpers
├── features/
│   ├── auth/              # Authentication pages
│   ├── child_devices/     # Child device management
│   ├── home/              # Home dashboard
│   ├── master_parents/    # Master parent features
│   ├── reports/           # Activity reports
│   └── settings/          # App settings
└── main.dart              # App entry point
```

## Setup Instructions

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Dart SDK
- Android Studio / VS Code
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd parental_control_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code (if needed)**
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Configuration

1. **API Configuration**
   - Update `lib/core/constants/app_constants.dart`
   - Set the correct base URL for your Drupal backend
   - Configure API endpoints as needed

2. **Localization**
   - Add translation files in `assets/translations/`
   - Update `lib/core/utils/app_localizations.dart` for new languages

3. **Theme Customization**
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

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions, please contact the development team or create an issue in the repository.

## Roadmap

### Phase 1 (Current)
- [x] Basic app structure
- [x] Authentication system
- [x] User role management
- [x] Prayer time integration
- [x] Localization support

### Phase 2 (Next)
- [ ] Child device management
- [ ] App usage tracking
- [ ] Daily reports
- [ ] Master parent profiles
- [ ] Push notifications

### Phase 3 (Future)
- [ ] Advanced analytics
- [ ] Machine learning insights
- [ ] Social features
- [ ] Web dashboard
- [ ] Multi-platform support
