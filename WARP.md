# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

**Barunay Super App** is a comprehensive Flutter-based super app for Brunei, featuring:
- **Marketplace** - Product listing, buying/selling with chat integration
- **Delivery Service** - On-demand delivery with runner system
- **Business Directory** - Local business discovery
- **Chat System** - Real-time messaging with typing indicators
- **User Management** - Multi-role system (buyer, seller, runner, admin)

The app uses **Supabase** as the backend (database + auth + real-time + storage) and is designed for cross-platform deployment (mobile + web).

## Architecture Overview

### Core Structure
```
lib/
├── core/                    # Core utilities and app exports
├── presentation/            # All UI screens (24+ screens)
├── routes/                  # Navigation and routing system
├── services/                # Business logic and API services
├── theme/                   # App theming system
├── widgets/                 # Reusable UI components
└── main.dart                # App entry point
```

### Key Architectural Patterns
- **Service Layer Pattern**: All business logic in dedicated service classes
- **Multi-Profile User System**: User profiles have sub-profiles for different roles
- **Real-time Communication**: Supabase real-time for chat and delivery tracking
- **Responsive Design**: Uses Sizer package for cross-device compatibility

### Database Design (Supabase)
- **User Management**: `user_profiles`, `user_sub_profiles`, `seller_profiles`, `runner_profiles`
- **Marketplace**: `products`, `product_images`, `favorites`, `categories`
- **Delivery System**: `delivery_requests`, `runner_proposals`, `delivery_tasks`, `runner_earnings`
- **Communication**: `conversations`, `messages`, `delivery_chat_messages`
- **Admin**: Admin functionality with document verification system

## Development Commands

### Environment Setup
```bash
# Install dependencies
flutter pub get

# Run with environment configuration (REQUIRED)
flutter run --dart-define-from-file=env.json
```

### Development Workflow
```bash
# Run in debug mode
flutter run --dart-define-from-file=env.json

# Hot reload is available during development
# Press 'r' to hot reload, 'R' to hot restart

# Run on specific device
flutter run -d chrome --dart-define-from-file=env.json     # Web
flutter run -d android --dart-define-from-file=env.json   # Android
flutter run -d ios --dart-define-from-file=env.json       # iOS
```

### Building and Deployment
```bash
# Build for production
flutter build apk --release --dart-define-from-file=env.json      # Android APK
flutter build appbundle --release --dart-define-from-file=env.json # Android App Bundle
flutter build ios --release --dart-define-from-file=env.json      # iOS
flutter build web --web-renderer html --release                    # Web (used in CI/CD)

# Test build locally
flutter build web --dart-define-from-file=env.json
```

### Code Quality
```bash
# Analyze code (linting is configured via flutter_lints)
flutter analyze

# Format code
flutter format .

# Run tests (if test files exist)
flutter test
```

## Environment Configuration

The app **requires** environment variables defined in `env.json`:

```json
{
  "SUPABASE_URL": "https://your-project.supabase.co",
  "SUPABASE_ANON_KEY": "your-anon-key",
  "OPENAI_API_KEY": "optional-for-ai-features",
  "GEMINI_API_KEY": "optional-for-ai-features",
  "ANTHROPIC_API_KEY": "optional-for-ai-features",
  "PERPLEXITY_API_KEY": "optional-for-ai-features"
}
```

**Critical**: Always use `--dart-define-from-file=env.json` when running the app.

## Key Services and Components

### Authentication Flow
- Supports email/password, phone number (+673), and social login
- Multi-step profile setup based on user role selection
- Session management via Supabase Auth

### Navigation System
- Central routing in `lib/routes/app_routes.dart`
- 20+ screens with helper methods for complex navigation
- Route-based navigation with proper argument passing

### State Management
- Stateful widgets with local state management
- Service classes handle business logic and API calls
- Real-time updates via Supabase subscriptions

### Critical Dependencies
**DO NOT REMOVE these dependencies:**
- `sizer: ^2.0.15` - Required for responsive design
- `flutter_svg: ^2.0.9` - Required for SVG icons
- `google_fonts: ^6.1.0` - Required for typography
- `shared_preferences: ^2.2.2` - Required for local storage
- `supabase_flutter: ^2.10.0` - Required for backend operations

## Testing and Demo

### Demo Credentials
The app includes built-in demo credentials for testing:
- **Buyer**: `buyer@marketplace.com` / `password123`
- **Seller**: `seller@marketplace.com` / `password123`
- **Runner**: `runner@marketplace.com` / `password123`
- **Admin**: `admin@marketplace.com` / `password123`

### Asset Management
- Assets in `assets/` and `assets/images/` directories only
- Uses Google Fonts instead of local fonts
- SVG icons handled via flutter_svg package

## Deployment Pipeline

### Automated Deployment (GitHub Actions + Netlify)
- **Trigger**: Push to `main` or `master` branch
- **Build**: Flutter web build with environment injection
- **Deploy**: Automatic deployment to Netlify
- **Secrets Required**: `NETLIFY_AUTH_TOKEN`, `NETLIFY_SITE_ID`, Supabase credentials

### Local Development Server
```bash
# Serve built web app locally
flutter build web --dart-define-from-file=env.json
cd build/web
python -m http.server 8080  # or any local server
```

## Common Issues and Solutions

### Environment Issues
- **Missing environment variables**: Ensure `env.json` exists with required Supabase credentials
- **Network initialization failures**: Check internet connection and Supabase URL/keys

### Development Issues
- **Hot reload not working**: Use `R` for hot restart, ensure no syntax errors
- **Widget overflow**: Check responsive design with Sizer values (`.w`, `.h`, `.sp`)
- **Supabase connection**: Verify credentials and network connectivity

### Database Issues
- **RLS policies**: User actions are controlled by Row Level Security policies
- **Real-time subscriptions**: Check Supabase real-time settings and table replication

## Key Files to Understand

- `lib/main.dart` - App initialization and error handling
- `lib/routes/app_routes.dart` - All navigation routes and helpers
- `lib/services/supabase_service.dart` - Database initialization
- `lib/services/auth_service.dart` - Authentication logic
- `supabase/migrations/` - Database schema and sample data
- `.github/workflows/deploy.yml` - CI/CD pipeline configuration

This is a production-ready super app with complex multi-role functionality. Always test thoroughly when making changes to core services or navigation flows.