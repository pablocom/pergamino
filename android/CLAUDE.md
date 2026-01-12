# Claude Code Guide - Pergamino Android

**Purpose**: Help Claude Code understand this project's architecture and conventions for efficient, accurate iterations.

---

## Quick Context

**What**: WhatsApp-like messaging app with email authentication
**Architecture**: Clean Architecture + MVVM
**Language**: Kotlin
**UI**: Jetpack Compose
**DI**: Hilt

---

## Core Principles

### 1. Feature-Based Modules (NOT Layer-Based)
```
✅ CORRECT: feature-auth/ contains domain/, data/, presentation/
❌ WRONG: Top-level domain/, data/, presentation/ modules
```

**Why**: Avoids distributed monolith. Each feature is independently layered.

### 2. Dependency Rule
```
presentation/ → domain/ ← data/
```
- Domain has NO dependencies on other layers
- Presentation and Data both depend on Domain
- Data implements Domain interfaces

### 3. Value Objects are Self-Validating
```kotlin
✅ CORRECT:
Email.create("test@example.com") // Returns Result<Email, ValidationError>

❌ WRONG:
Email("test@example.com") // No validation
```

---

## Project Structure

```
android/
├── app/                              # App module - wires everything together
│   └── src/main/java/com/pergamino/
│       ├── PergaminoApplication.kt   # @HiltAndroidApp
│       ├── MainActivity.kt           # Entry point
│       └── DeepLinkActivity.kt       # Handles pergamino:// links
│
├── core/                             # Shared infrastructure
│   ├── core-common/                  # Result<T,E>, Dispatchers, extensions
│   ├── core-ui/                      # Theme, colors, reusable composables
│   ├── core-data/                    # DispatcherModule
│   └── core-testing/                 # Test utilities, fakes
│
└── feature/                          # Feature modules
    └── feature-auth/                 # Authentication feature
        ├── domain/                   # Business logic (NO Android deps)
        │   ├── model/                # Email, User, AuthState, AuthError
        │   ├── repository/           # AuthRepository interface
        │   └── usecase/              # RequestEmailVerification, VerifyToken, etc.
        ├── data/                     # Data sources & repository impl
        │   ├── datasource/           # Remote & Local interfaces + impls
        │   └── repository/           # AuthRepositoryImpl
        ├── presentation/             # UI layer
        │   ├── email/                # EmailEntryScreen + ViewModel
        │   ├── verification/         # VerificationPendingScreen + ViewModel
        │   └── navigation/           # AuthNavHost, routes
        └── di/                       # AuthModule (Hilt bindings)
```

---

## File Naming Conventions

| Type | Pattern | Example |
|------|---------|---------|
| Value Object | `{Name}.kt` | `Email.kt` |
| Entity | `{Name}.kt` | `User.kt` |
| State | `{Name}State.kt` | `AuthState.kt` |
| Error | `{Name}Error.kt` | `AuthError.kt` |
| Use Case | `{Verb}{Noun}UseCase.kt` | `RequestEmailVerificationUseCase.kt` |
| Repository Interface | `{Name}Repository.kt` | `AuthRepository.kt` |
| Repository Impl | `{Name}RepositoryImpl.kt` | `AuthRepositoryImpl.kt` |
| ViewModel | `{Screen}ViewModel.kt` | `EmailEntryViewModel.kt` |
| UI State | `{Screen}UiState.kt` | `EmailEntryUiState.kt` |
| Screen (stateful) | `{Screen}Screen.kt` | `EmailEntryScreen.kt` |
| Screen (stateless) | `{Screen}Content.kt` | `EmailEntryContent.kt` |
| Data Source Interface | `{Name}DataSource.kt` | `AuthRemoteDataSource.kt` |
| Data Source Impl | `{Name}DataSourceImpl.kt` | `AuthLocalDataSourceImpl.kt` |
| Fake Impl | `Fake{Name}.kt` | `FakeAuthRemoteDataSource.kt` |
| Hilt Module | `{Feature}Module.kt` | `AuthModule.kt` |

---

## Architecture Patterns

### Domain Layer (Pure Kotlin - No Android)

**Value Objects**: Immutable, self-validating
```kotlin
@JvmInline
value class Email private constructor(val value: String) {
    companion object {
        fun create(value: String): Result<Email, EmailValidationError> {
            // Validation logic
        }
    }
}
```

**Use Cases**: Single responsibility, one operation
```kotlin
class RequestEmailVerificationUseCase @Inject constructor(
    private val authRepository: AuthRepository
) {
    suspend operator fun invoke(emailString: String): Result<AuthState.VerificationPending, AuthError> {
        return Email.create(emailString)
            .mapError { AuthError.InvalidEmail(it) }
            .flatMap { email -> authRepository.requestEmailVerification(email) }
    }
}
```

**Repository Interface**: Defines contract, returns Flow for state
```kotlin
interface AuthRepository {
    val authState: Flow<AuthState>
    suspend fun requestEmailVerification(email: Email): Result<AuthState.VerificationPending, AuthError>
}
```

### Data Layer

**Repository Implementation**: Coordinates data sources, executes on IO dispatcher
```kotlin
@Singleton
class AuthRepositoryImpl @Inject constructor(
    private val remoteDataSource: AuthRemoteDataSource,
    private val localDataSource: AuthLocalDataSource,
    @IoDispatcher private val ioDispatcher: CoroutineDispatcher
) : AuthRepository {
    override val authState: Flow<AuthState> =
        localDataSource.authStateData
            .map { it.toDomain() }
            .flowOn(ioDispatcher)
}
```

**Data Sources**: Separate interfaces for remote (API) and local (DataStore)
- Remote: API calls, network operations
- Local: Persistence, caching

### Presentation Layer

**ViewModel**: Manages UI state, delegates to use cases
```kotlin
@HiltViewModel
class EmailEntryViewModel @Inject constructor(
    private val requestEmailVerificationUseCase: RequestEmailVerificationUseCase
) : ViewModel() {
    private val _uiState = MutableStateFlow(EmailEntryUiState())
    val uiState: StateFlow<EmailEntryUiState> = _uiState.asStateFlow()

    private val _events = Channel<EmailEntryEvent>(Channel.BUFFERED)
    val events = _events.receiveAsFlow()
}
```

**UI State**: Immutable data class with computed properties
```kotlin
data class EmailEntryUiState(
    val email: String = "",
    val isLoading: Boolean = false,
    val error: AuthError? = null
) {
    val canSubmit: Boolean
        get() = email.isNotBlank() && !isLoading
}
```

**Events**: One-time actions (navigation, snackbars)
```kotlin
sealed interface EmailEntryEvent {
    data class NavigateToScreen(val route: String) : EmailEntryEvent
    data class ShowError(val error: AuthError) : EmailEntryEvent
}
```

**Composables**: Stateful wrapper + stateless content
```kotlin
// Stateful - connects to ViewModel
@Composable
fun EmailEntryScreen(
    viewModel: EmailEntryViewModel = hiltViewModel(),
    onNavigate: (String) -> Unit
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    LaunchedEffect(Unit) {
        viewModel.events.collect { event ->
            when (event) {
                is EmailEntryEvent.NavigateToScreen -> onNavigate(event.route)
            }
        }
    }

    EmailEntryContent(
        uiState = uiState,
        onEmailChanged = viewModel::onEmailChanged
    )
}

// Stateless - receives state, emits events
@Composable
fun EmailEntryContent(
    uiState: EmailEntryUiState,
    onEmailChanged: (String) -> Unit
) {
    // Pure UI rendering
}
```

---

## Common Tasks

### Adding a New Use Case

1. Create in `domain/usecase/`
2. Inject repository
3. Return `Result<T, AuthError>`
4. Write tests in `src/test/`

```kotlin
class NewUseCase @Inject constructor(
    private val authRepository: AuthRepository
) {
    suspend operator fun invoke(param: String): Result<Output, AuthError> {
        // Logic here
    }
}
```

### Adding a New Screen

1. Create folder: `presentation/{screen-name}/`
2. Create files:
   - `{Screen}UiState.kt` - UI state data class
   - `{Screen}Event.kt` - One-time events (optional)
   - `{Screen}ViewModel.kt` - State management
   - `{Screen}Screen.kt` - Stateful + stateless composables
3. Add route to `navigation/AuthNavigation.kt`
4. Write tests in `src/test/`

### Adding a New Module Dependency

Edit `settings.gradle.kts`:
```kotlin
include(":feature:feature-chat")  // Add new module
```

Edit module's `build.gradle.kts`:
```kotlin
dependencies {
    implementation(project(":core:core-common"))  // Add dependency
}
```

---

## Testing Conventions

### Unit Test Structure
```kotlin
class EmailTest {
    @Test
    fun `create returns success for valid email`() {
        // Given
        val validEmail = "test@example.com"

        // When
        val result = Email.create(validEmail)

        // Then
        assertThat(result).isInstanceOf(Result.Success::class.java)
    }
}
```

### ViewModel Test Setup
```kotlin
@OptIn(ExperimentalCoroutinesApi::class)
class EmailEntryViewModelTest {
    private lateinit var mockUseCase: RequestEmailVerificationUseCase
    private lateinit var viewModel: EmailEntryViewModel
    private val testDispatcher = StandardTestDispatcher()

    @Before
    fun setup() {
        Dispatchers.setMain(testDispatcher)
        mockUseCase = mockk()
        viewModel = EmailEntryViewModel(mockUseCase)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }
}
```

### Testing Flows
```kotlin
@Test
fun `event is emitted on success`() = runTest {
    viewModel.events.test {
        viewModel.onAction()
        advanceUntilIdle()

        val event = awaitItem()
        assertThat(event).isInstanceOf(SomeEvent::class.java)
    }
}
```

---

## Critical Rules

### ✅ DO

1. **Use Result<T, E>** for operations that can fail
2. **Make value objects immutable** with private constructors
3. **Put validation in domain models**, not ViewModels
4. **Use sealed interfaces** for states and errors (exhaustive when clauses)
5. **Inject use cases** into ViewModels, not repositories
6. **Use StateFlow** for state, Channel for one-time events
7. **Test domain logic** thoroughly (pure Kotlin, easy to test)
8. **Use @HiltViewModel** for all ViewModels
9. **Add @Singleton** to repositories and data sources
10. **Use IoDispatcher** for IO operations

### ❌ DON'T

1. **Don't put Android types in domain layer** (Context, Bundle, etc.)
2. **Don't use LiveData** (use StateFlow instead)
3. **Don't make repositories depend on each other**
4. **Don't put business logic in composables**
5. **Don't create God classes** (keep use cases small)
6. **Don't skip validation** in value objects
7. **Don't use `!!` (non-null assertion)** without good reason
8. **Don't catch generic exceptions** in domain layer
9. **Don't make stateful composables without stateless counterparts**
10. **Don't put navigation logic in ViewModels** (emit events instead)

---

## Module Dependencies

```
app
 ├── feature-auth
 ├── core-common
 ├── core-ui
 └── core-data

feature-auth
 ├── core-common
 ├── core-ui
 └── core-data

core-ui
 └── (no internal dependencies)

core-data
 └── core-common

core-common
 └── (no internal dependencies)

core-testing
 └── core-common
```

**Rule**: Features can depend on core modules, but NOT on other features.

---

## Dependency Injection

### Providing Dependencies

In `di/AuthModule.kt`:
```kotlin
@Module
@InstallIn(SingletonComponent::class)
abstract class AuthModule {
    @Binds
    @Singleton
    abstract fun bindAuthRepository(impl: AuthRepositoryImpl): AuthRepository

    // Use @Binds for interfaces
    // Use @Provides for concrete types or when logic is needed
}
```

### Injecting Dependencies

```kotlin
// ViewModel
@HiltViewModel
class MyViewModel @Inject constructor(
    private val useCase: MyUseCase
) : ViewModel()

// Repository
@Singleton
class MyRepositoryImpl @Inject constructor(
    private val dataSource: MyDataSource,
    @IoDispatcher private val ioDispatcher: CoroutineDispatcher
) : MyRepository

// Use Case
class MyUseCase @Inject constructor(
    private val repository: MyRepository
)
```

---

## Navigation

### Defining Routes
```kotlin
sealed class AuthRoute(val route: String) {
    data object EmailEntry : AuthRoute("auth/email")

    data object VerificationPending : AuthRoute("auth/verification/{email}") {
        fun createRoute(email: String): String {
            val encoded = URLEncoder.encode(email, StandardCharsets.UTF_8.toString())
            return "auth/verification/$encoded"
        }
    }
}
```

### Navigation in Composables
```kotlin
composable(route = AuthRoute.EmailEntry.route) {
    EmailEntryScreen(
        onNavigateToNext = { email ->
            navController.navigate(AuthRoute.VerificationPending.createRoute(email))
        }
    )
}
```

### Clearing Back Stack
```kotlin
navController.navigate(AuthRoute.Success.route) {
    popUpTo(AuthRoute.EmailEntry.route) { inclusive = true }
}
```

---

## Error Handling

### Domain Errors
```kotlin
sealed interface AuthError {
    data class InvalidEmail(val validationError: EmailValidationError) : AuthError
    data class NetworkError(val message: String? = null) : AuthError
    data object TokenExpired : AuthError
}
```

### Using Result Type
```kotlin
// Success
return Result.success(value)

// Failure
return Result.failure(AuthError.NetworkError("Connection failed"))

// Mapping
result.map { value -> transformedValue }
result.mapError { error -> transformedError }

// Flat mapping (chaining)
result.flatMap { value -> anotherOperation(value) }

// Side effects
result.onSuccess { value -> logSuccess(value) }
result.onFailure { error -> logError(error) }
```

---

## State Management

### ViewModel Pattern
```kotlin
@HiltViewModel
class MyViewModel @Inject constructor(
    private val useCase: MyUseCase
) : ViewModel() {

    // State - StateFlow for UI
    private val _uiState = MutableStateFlow(MyUiState())
    val uiState: StateFlow<MyUiState> = _uiState.asStateFlow()

    // Events - Channel for one-time actions
    private val _events = Channel<MyEvent>(Channel.BUFFERED)
    val events = _events.receiveAsFlow()

    // User actions
    fun onAction() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }

            useCase()
                .onSuccess { result ->
                    _events.send(MyEvent.NavigateNext)
                }
                .onFailure { error ->
                    _uiState.update { it.copy(error = error) }
                }

            _uiState.update { it.copy(isLoading = false) }
        }
    }
}
```

### Observing in Composables
```kotlin
@Composable
fun MyScreen(viewModel: MyViewModel = hiltViewModel()) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    LaunchedEffect(Unit) {
        viewModel.events.collect { event ->
            when (event) {
                is MyEvent.NavigateNext -> onNavigate()
            }
        }
    }
}
```

---

## Replacing Fake Backend

When backend is ready:

1. Create `AuthRemoteDataSourceImpl.kt` in `data/datasource/`
2. Implement using Retrofit/Ktor:
```kotlin
@Singleton
class AuthRemoteDataSourceImpl @Inject constructor(
    private val api: AuthApi
) : AuthRemoteDataSource {
    override suspend fun requestVerification(email: String): Result<VerificationResponse, AuthError> {
        return try {
            val response = api.requestVerification(EmailRequest(email))
            Result.success(response)
        } catch (e: Exception) {
            Result.failure(AuthError.NetworkError(e.message))
        }
    }
}
```

3. Update `AuthModule.kt`:
```kotlin
@Binds
@Singleton
abstract fun bindAuthRemoteDataSource(
    impl: AuthRemoteDataSourceImpl  // Changed from FakeAuthRemoteDataSource
): AuthRemoteDataSource
```

---

## Debugging Tips

### Check Logcat Tags
- `FakeAuthRemoteDataSource` - Verification tokens
- `DeepLinkActivity` - Deep link handling
- `AuthRepositoryImpl` - Repository operations

### Common Issues

**Issue**: ViewModel not surviving rotation
**Fix**: Use `hiltViewModel()`, not `viewModel()`

**Issue**: State not updating in UI
**Fix**: Use `collectAsStateWithLifecycle()`, not `collectAsState()`

**Issue**: Hilt compilation errors
**Fix**: Ensure `@HiltAndroidApp` on Application class, `@AndroidEntryPoint` on Activities

**Issue**: Deep link not working
**Fix**: Check AndroidManifest has correct intent filters, app is in foreground

---

## Version Information

- **Min SDK**: 26 (Android 8.0)
- **Target SDK**: 34 (Android 14)
- **Compile SDK**: 34
- **Kotlin**: 1.9.22
- **Compose BOM**: 2024.02.00
- **Hilt**: 2.50

---

## Quick Reference

### Adding New Feature Module

1. Create folder: `feature/feature-{name}/`
2. Add to `settings.gradle.kts`
3. Create `build.gradle.kts` (copy from feature-auth)
4. Create package structure: `domain/`, `data/`, `presentation/`, `di/`
5. Create `AndroidManifest.xml` (empty `<manifest />`)

### Running Tests
```bash
# All tests
./gradlew test

# Specific module
./gradlew :feature:feature-auth:test

# Single test class
./gradlew :feature:feature-auth:test --tests EmailTest
```

### Building
```bash
# Debug build
./gradlew assembleDebug

# Release build
./gradlew assembleRelease

# Clean build
./gradlew clean build
```

---

## Key Files to Reference

When working on authentication:
- **Domain models**: `feature-auth/domain/model/Email.kt`
- **Use case example**: `feature-auth/domain/usecase/RequestEmailVerificationUseCase.kt`
- **Repository impl**: `feature-auth/data/repository/AuthRepositoryImpl.kt`
- **ViewModel example**: `feature-auth/presentation/email/EmailEntryViewModel.kt`
- **Screen example**: `feature-auth/presentation/email/EmailEntryScreen.kt`
- **Test example**: `feature-auth/src/test/.../EmailTest.kt`

---

## Summary

**Architecture**: Clean Architecture with feature-based modules
**Pattern**: MVVM with StateFlow and unidirectional data flow
**Key Type**: `Result<T, E>` for error handling
**Testing**: JUnit + MockK + Truth + Turbine
**DI**: Hilt with @Binds for interfaces

**Remember**: Domain layer is pure Kotlin. Presentation depends on Domain. Data depends on Domain. Features don't depend on each other.
