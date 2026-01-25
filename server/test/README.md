# Testing Architecture

This project follows a testing strategy with clear separation between unit, integration, and component tests.

## Test Categories

### Unit Tests (`test/unit/`)

Fast, isolated tests with no external dependencies. Test business logic in isolation using mocked dependencies. Preferably tests collaborator modules through application service layer.

**Examples:**
- `unit/auth/token_generator_test.exs` - Pure JWT token generation logic
- `unit/auth/oauth2_flow_test.exs` - OAuth2 flow business logic with mocked Redis and email

**Characteristics:**
- Run with `async: true` for maximum speed
- Use Mox for mocking infrastructure dependencies
- No out-of-process services (Redis, databases, external APIs)
- Focus on business logic and domain rules

**Run command:**
```bash
mix test.unit
```

### Integration Tests (`test/integration/`)

Narrow integration tests that verify our adapters work correctly with external dependencies.

**Examples:**
- `integration/auth/authorization_code_store_test.exs` - Redis operations
- `integration/messaging/email_sender_test.exs` - Email sending with Swoosh

**Characteristics:**
- Run with `async: false` for tests sharing state (e.g., Redis)
- Use real external services (Redis, Swoosh test adapter)
- Validate infrastructure adapters function correctly
- May share coverage with component tests (expected and acceptable)

**Run command:**
```bash
mix test.integration
```

### Component Tests (`test/component/`)

Full HTTP stack tests through controller endpoints with real infrastructure.

**Examples:**
- `component/web/controllers/token_test.exs` - OAuth2 token endpoints
- `component/web/controllers/verification_email_controller_test.exs` - Email verification endpoint

**Characteristics:**
- Test through the HTTP interface (controllers)
- Use real infrastructure (Redis, Swoosh)
- Focus on edge cases that require full system behavior
- Examples: "authorization code can only be used once", token expiration flows

**Run command:**
```bash
mix test.component
```

## Running Tests

```bash
# Run all tests
mix test

# Run only unit tests (fast)
mix test.unit

# Run only integration tests
mix test.integration

# Run only component tests
mix test.component

# Run specific test file
mix test test/unit/auth/oauth2_flow_test.exs

# Run specific test by line number
mix test test/unit/auth/oauth2_flow_test.exs:42
```

## CI Strategy

For continuous integration, run tests in this order:

1. **Unit tests first** - Fast feedback on business logic
2. **Integration tests** - Validate infrastructure adapters
3. **Component tests** - Full system validation

Example CI pipeline:
```bash
mix test.unit && mix test.integration && mix test.component
```

## Testing Conventions

### FIRST Principles

All tests strictly follow FIRST principles:

- **Fast**: Tests run quickly
- **Independent/Isolated**: Each test is self-contained with no shared state
  - Tests use private helper functions instead of shared setup data
  - Redis cleanup ensures no test pollution
  - Tests pass in any order with any seed
- **Repeatable**: Tests produce consistent results across runs
- **Self-validating**: Clear pass/fail with descriptive assertions
- **Thorough**: They do not test just the happy path, they tests what's required to ensure functions are solid. Should try to cover every use case scenario and not just aim for 100% code coverage being pragmatic.


### Test Data Management

**Private Helper Functions** - Create test data explicitly in each test:
```elixir
defp create_test_email(address \\ "test@example.com") do
  {:ok, email} = EmailAddress.create(address)
  email
end

defp create_authorization_code(email, challenge) do
  {code, expires_at} = AuthorizationCodeGenerator.generate()
  :ok = AuthorizationCodeStore.store(code, expires_at, email, challenge)
  code
end
```

**Test Data Cleanup** - Use `on_exit` to clean up persistent data:
```elixir
setup do
  on_exit(fn ->
    flush_authorization_codes()  # From RedisHelpers
  end)
  :ok
end
```

### Mocking

- Use Mox for mocking dependencies in unit tests
- Behaviors are defined in `lib/pergamino/core/` and `lib/pergamino/infrastructure/*/` modules
- Mocks are configured in `test/test_helper.exs`
- Available mocks: `ClockMock`, `AuthorizationCodeStoreMock`, `EmailSenderMock`

### Module Naming

Tests follow a namespace pattern matching their directory:
- `Unit.*` for unit tests
- `Integration.*` for integration tests
- `Component.*` for component tests

### Test Helpers

Test helper modules are located in `test/support/`:

- **RedisHelpers** - Utilities for Redis cleanup in tests
  - `flush_authorization_codes()` - Removes all authorization codes from Redis
  - Import with `import RedisHelpers` in test modules

### Dependency Injection

Application services resolve dependencies through Application environment:

```elixir
# Production code uses defaults
OAuth2Flow.initiate(params)  # Uses real AuthorizationCodeStore and EmailSender

# Unit tests configure mocks in setup block
setup do
  Application.put_env(:pergamino, :authorization_code_store, AuthorizationCodeStoreMock)
  Application.put_env(:pergamino, :email_sender, EmailSenderMock)

  on_exit(fn ->
    Application.delete_env(:pergamino, :authorization_code_store)
    Application.delete_env(:pergamino, :email_sender)
  end)
end
```

## Architecture Layers

The codebase follows clean architecture principles:

- **Domain Layer** (`lib/pergamino/domain/`) - Value objects, tested through usage
- **Application Layer** (`lib/pergamino/application/`) - Business workflows, unit tested with mocks
- **Core Layer** (`lib/pergamino/core/`) - Shared utilities (Clock), tested with mocks where needed
- **Infrastructure Layer** (`lib/pergamino/infrastructure/`) - External adapters, integration tested
- **Web Layer** (`lib/pergamino/web/`) - HTTP controllers, component tested

Each layer is tested at the appropriate level to maintain fast, reliable test suites.
