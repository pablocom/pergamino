# CLAUDE.md - Pergamino Android Project



## Commands

> As a prerequisite JAVA_HOME environment variable must be present. Example to set up in Windows and Powershell: `$env:JAVA_HOME="C:\Program Files\Android\Android Studio\jbr"`

- **Build Debug**: `./gradlew assembleDebug`
- **Run Unit Tests**: `./gradlew testDebugUnitTest`
- **Run Lint**: `./gradlew lintDebug`
- **Clean**: `./gradlew clean`

## Architecture
This project follows the **[Now in Android](https://github.com/android/nowinandroid)** architecture guidelines.

### Layers
1.  **UI Layer**:
    -   **Composables**: Stateless, function-based components. State is hoisted.
    -   **ViewModels**: `HiltViewModel`. Exposes `StateFlow<UiState>`. Handles business logic delegation.
    -   **State**: Uses `sealed interface UiState` (Idle, Loading, Success, Error) for strict typing.
2.  **Domain Layer** (Optional):
    -   **UseCases**: Reusable business logic (e.g., `ValidateEmailUseCase`). Single-responsibility, operator `invoke`.
3.  **Data Layer**:
    -   **Repositories**: Expose data as `Flow` or `suspend` functions. Handle data coordination.
    -   **Data Sources**: Remote (Retrofit) or Local (Room/DataStore).

## Coding Conventions
-   **No Comments**: Code must be self-explanatory. Variable and function names must be descriptive enough to avoid comments.
-   **TDD**: Testing is mandatory. Write unit tests for ViewModels, UseCases, and Repositories.
-   **State Management**: Use `StateFlow` and `collectAsStateWithLifecycle` in Compose.
-   **Dependency Injection**: Use Hilt for all DI.
    -   `@HiltAndroidApp` on Application.
    -   `@AndroidEntryPoint` on Activities/Fragments.
    -   `@HiltViewModel` on ViewModels.
    -   `@Inject` for constructor injection.
-   **Strict Typing**: Use strict types (e.g., `DeviceBindingRequest` vs raw maps).

## References
-   [Now in Android Architecture](https://github.com/android/nowinandroid/blob/main/docs/ArchitectureLearningJourney.md)
-   [Jetpack Compose Documentation](https://developer.android.com/jetpack/compose)
-   [Hilt Dependency Injection](https://developer.android.com/training/dependency-injection/hilt-android)
