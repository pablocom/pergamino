# Pergamino Android App

A WhatsApp-like messaging application for Android with email-based authentication.

## Architecture

This project follows **Clean Architecture** with **MVVM** pattern, implementing industry best practices recommended by Google, Martin Fowler, and leading Android engineers.

### Key Architectural Decisions

1. **Feature-Based Modularization** (not layer-based)
   - Each feature module is internally layered (domain/data/presentation)
   - Avoids the "distributed monolith" anti-pattern
   - Follows Martin Fowler's recommendation

2. **Domain Layer** (following Google's official guide)
   - Use cases sit between ViewModels and repositories
   - Entities are use case agnostic
   - Single Responsibility Principle for use cases

3. **State Management** (Droidcon best practices)
   - StateFlow for observable state
   - Stateless composables (state hoisted to ViewModels)
   - StateHolder Pattern for modular, testable state

4. **Navigation**
   - LaunchedEffect for auth state observation
   - popUpTo with inclusive=true for back stack clearing
   - Single source of truth for auth state

## Project Structure

```
android/
├── app/                          # Application module
├── core/
│   ├── core-common/              # Result type, extensions, qualifiers
│   ├── core-ui/                  # Theme, design system, common composables
│   ├── core-data/                # DataStore, data abstractions
│   └── core-testing/             # Test utilities, fakes
└── feature/
    └── feature-auth/             # Authentication feature
        ├── domain/               # Models, repository interface, use cases
        ├── data/                 # Repository impl, data sources, DTOs
        ├── presentation/         # Screens, ViewModels, UI states
        └── di/                   # Hilt module
```

## Tech Stack

- **UI**: Jetpack Compose
- **Architecture**: Clean Architecture + MVVM
- **Dependency Injection**: Hilt
- **Navigation**: Navigation Compose
- **Persistence**: DataStore Preferences
- **Async**: Kotlin Coroutines & Flow
- **Testing**: JUnit, MockK, Truth, Turbine

## Features

### Email Authentication Flow

1. **Email Entry**: User enters email address with real-time validation
2. **Verification Request**: System sends verification link to email
3. **Pending Screen**: User waits for email, can resend with cooldown
4. **Deep Link**: User clicks link in email (pergamino://verify?token=XXX)
5. **Token Verification**: System validates token and authenticates user
6. **Success**: User proceeds to main app

## Getting Started

### Prerequisites

- Android Studio Hedgehog or later
- JDK 17
- Android SDK 34
- Gradle 8.2+

### Building the Project

```bash
cd android
./gradlew build
```

### Running Tests

```bash
# Unit tests
./gradlew test

# UI tests (requires connected device/emulator)
./gradlew connectedAndroidTest
```

### Running the App

1. Open the `android` folder in Android Studio
2. Sync Gradle files
3. Run the `app` configuration

## Testing Email Verification

The app uses a fake backend (FakeAuthRemoteDataSource) that logs verification tokens to Logcat.

### Testing Deep Links

1. Run the app
2. Enter an email and tap Continue
3. Check Logcat for the verification token (tag: FakeAuthRemoteDataSource)
4. Use ADB to simulate clicking the verification link:

```bash
adb shell am start -a android.intent.action.VIEW -d "pergamino://verify?token=YOUR_TOKEN_HERE"
```

Example Logcat output:
```
FakeAuthRemoteDataSource: ============================================================
FakeAuthRemoteDataSource: Verification email sent to: user@example.com
FakeAuthRemoteDataSource: Deep link for testing: pergamino://verify?token=abc-123-def
FakeAuthRemoteDataSource: Test with: adb shell am start -a android.intent.action.VIEW -d "pergamino://verify?token=abc-123-def"
FakeAuthRemoteDataSource: ============================================================
```

## Key Classes

### Domain Layer
- **Email**: Value object with validation (immutable, self-validating)
- **AuthState**: Sealed interface representing auth state machine
- **AuthRepository**: Repository contract defining auth operations
- **Use Cases**: Single-responsibility use cases for each operation

### Data Layer
- **AuthRepositoryImpl**: Coordinates remote and local data sources
- **FakeAuthRemoteDataSource**: Stubbed API for development
- **AuthLocalDataSourceImpl**: DataStore-based local persistence

### Presentation Layer
- **EmailEntryViewModel**: Manages email entry screen state
- **EmailEntryScreen**: Stateful wrapper, handles events
- **EmailEntryContent**: Stateless composable for rendering
- **AuthNavHost**: Navigation graph with proper back stack handling

### Deep Links
- **DeepLinkActivity**: Handles verification links from email

## Code Quality

### Testing
- **Email validation**: 10+ test cases covering edge cases
- **Use cases**: Mocked repository testing
- **ViewModels**: Coroutine testing with Turbine for flows
- **Repository**: Integration testing with fake data sources

### Design Principles
- **SOLID Principles**: Single Responsibility, Dependency Inversion
- **DDD**: Value objects, entities, domain events
- **Clean Code**: Meaningful names, small functions, clear intent

## TODO: Backend Integration

When the backend is ready, replace `FakeAuthRemoteDataSource` in `AuthModule`:

```kotlin
@Binds
@Singleton
abstract fun bindAuthRemoteDataSource(impl: AuthRemoteDataSourceImpl): AuthRemoteDataSource
```

Create `AuthRemoteDataSourceImpl` with Retrofit/Ktor for real API calls.

## Resources

- [Google: Architecture Recommendations](https://developer.android.com/topic/architecture/recommendations)
- [Google: Domain Layer Guide](https://developer.android.com/topic/architecture/domain-layer)
- [Droidcon: Global State Management](https://www.droidcon.com/2025/01/23/mastering-global-state-management-in-android-with-jetpack-compose/)
- [ProAndroidDev: Modularization Anti-patterns](https://proandroiddev.com/structural-and-navigation-anti-patterns-in-modularized-android-applications-a7d667e35cd6)

## License

Copyright © 2026 Pergamino
