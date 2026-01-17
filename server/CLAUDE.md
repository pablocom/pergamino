# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Pergamino is a minimal Phoenix JSON API server implementing Ed25519-based device binding authentication. The project follows clean architecture principles with clear separation between domain logic, application services, infrastructure adapters, and web layer.

## Development Commands

### Running the Server
```bash
# Install dependencies
mix setup

# Development server (interactive shell - RECOMMENDED)
iex -S mix phx.server

# Development server (non-interactive)
mix phx.server
```

### Testing
```bash
# Run all tests
mix test

# Run a specific test file
mix test test/pergamino/web/controllers/device_binding_controller_test.exs

# Run a specific test (by line number)
mix test test/pergamino/web/controllers/device_binding_controller_test.exs:5

# Run tests with coverage
mix test --cover
```

## Architecture

### Clean Architecture Layers

The codebase follows clean architecture principles with clear layer separation:

- **Domain Layer** (`lib/pergamino/domain/`): Core business logic and rules
  - Value Objects: `Pergamino.Domain.EmailAddress`
  - No dependencies on infrastructure or frameworks

- **Application Layer** (`lib/pergamino/application/`): Application services orchestrating use cases
  - Services: `Pergamino.Application.DeviceBinding`
  - Coordinates domain objects and infrastructure adapters
  - Contains business workflows

- **Infrastructure Layer** (`lib/pergamino/infrastructure/`): External service adapters
  - Auth adapters: `Pergamino.Infrastructure.Auth.TokenGenerator`
  - Messaging adapters: `Pergamino.Infrastructure.Messaging.EmailSender`
  - Implements external integrations (JWT, email, etc.)

- **Web Layer** (`lib/pergamino/web/`): HTTP interface and controllers
  - Endpoint: `Pergamino.Web.Endpoint`
  - Router: `Pergamino.Web.Router`
  - Controllers: `Pergamino.Web.Controllers.*`
  - Error handling: `Pergamino.Web.ErrorHandler`, `Pergamino.Web.ProblemDetails`
  - Telemetry: `Pergamino.Web.Telemetry`

### Namespace Structure (IMPORTANT)

This project uses `Pergamino.Web.*` namespace structure, NOT the Phoenix standard `PergaminoWeb.*`. This is an intentional architectural decision.

**Critical**:
- When adding new controllers, use `scope "/api", Pergamino.Web do` in the router
- Controller references in routes should be `Controllers.ControllerName`

### Module Organization

```
lib/pergamino.ex                              # Application supervisor + using macros
lib/pergamino/
  ├── domain/
  │   └── email_address.ex                    # EmailAddress value object
  ├── application/
  │   └── device_binding/
  │       └── device_binding.ex               # DeviceBinding application service
  ├── infrastructure/
  │   ├── auth/
  │   │   └── token_generator.ex              # JWT token generation adapter
  │   └── messaging/
  │       └── email_sender.ex                 # Email sending adapter (Swoosh)
  └── web/
      ├── endpoint.ex                         # Phoenix endpoint
      ├── router.ex                           # Route definitions
      ├── telemetry.ex                        # Metrics and monitoring
      ├── error_handler.ex                    # Error response handler
      ├── problem_details.ex                  # RFC 7807 Problem Details
      └── controllers/
          ├── device_binding.ex               # Device binding controller
          ├── error_json.ex                   # Error JSON responses
          └── fallback.ex                     # Fallback controller

test/
  ├── support/
  │   ├── conn_case.ex                        # Controller test helpers
  │   └── problem_details_helpers.ex          # Problem Details assertions
  └── pergamino/                              # Tests mirror lib structure
      ├── domain/
      ├── application/
      ├── infrastructure/
      └── web/
```

### Supervision Tree

```
Pergamino.Supervisor (one_for_one)
├── Pergamino.Web.Telemetry
├── DNSCluster (for distributed Erlang)
├── Phoenix.PubSub (Pergamino.PubSub)
├── Finch (HTTP client for Swoosh)
├── Pergamino.Infrastructure.Auth.TokenGenerator.SignerLoader (JWT signer initialization)
└── Pergamino.Web.Endpoint
```

### Configuration Structure

- `config/config.exs` - Base configuration for all environments
- `config/dev.exs` - Development-specific (LiveDashboard enabled via `dev_routes: true`)
- `config/test.exs` - Test environment (`server: false`)
- `config/prod.exs` - Production base config
- `config/runtime.exs` - Runtime configuration (reads ENV vars)

**Note**: `phoenix_live_dashboard` is available in all environments but routes are only enabled when `dev_routes: true` (development only). Development routes also include `/dev/mailbox` for Swoosh email preview.

### Device Binding Architecture (Implemented)

The device binding flow enables secure device registration:

1. **Initiate Binding** (POST `/api/device-binding-link`):
   - User submits email address
   - System validates email using `Pergamino.Domain.EmailAddress` value object
   - Generates JWT binding token via `Pergamino.Infrastructure.Auth.TokenGenerator`
   - Creates deeplink (`pergamino://bind?token=<JWT>`)
   - Sends email with deeplink via `Pergamino.Infrastructure.Messaging.EmailSender`
   - Returns 202 Accepted on success

2. **Flow Architecture**:
   - Controller validates request and generates JWT token
   - Controller delegates to `Pergamino.Application.DeviceBinding.send_binding_link/2`
   - Application service creates EmailAddress value object and orchestrates email sending
   - Infrastructure adapters handle external concerns (JWT, email delivery)
   - Error responses follow RFC 7807 Problem Details format

3. **Future: Device Verification** (Planned):
   - Mobile app extracts JWT from deeplink
   - Generates Ed25519 keypair
   - POST `/api/verify-binding` with JWT + public key
   - Server validates JWT and stores public key for signature-based auth

## Important Patterns

### Clean Architecture Patterns

**Value Objects**: Immutable objects with built-in validation
- Located in `lib/pergamino/domain/`
- Factory methods return `{:ok, value}` or `{:error, reason}`
- Example: `Pergamino.Domain.EmailAddress`

**Application Services**: Orchestrate use cases and coordinate dependencies
- Located in `lib/pergamino/application/<context>/`
- Receive primitive types (strings, etc.) and infrastructure-generated tokens
- Coordinate domain objects and infrastructure adapters
- Example: `Pergamino.Application.DeviceBinding.send_binding_link/2`

**Infrastructure Adapters**: Implement external integrations
- Located in `lib/pergamino/infrastructure/`
- Handle external concerns (JWT, email, databases, etc.)
- Examples: `TokenGenerator`, `EmailSender`

**Controllers**: Thin HTTP interface layer
- Validate HTTP requests and extract parameters
- Call infrastructure adapters (e.g., token generation)
- Delegate business logic to application services
- Handle errors via `action_fallback(Pergamino.Web.Controllers.Fallback)`

### Adding New Features

When adding a new bounded context:

1. **Create domain structure** in `lib/pergamino/domain/`
   - Value objects with validation

2. **Create application services** in `lib/pergamino/application/<context>/`
   - Services that orchestrate use cases

3. **Create infrastructure adapters** in `lib/pergamino/infrastructure/`
   - Implement external service integrations

4. **Create controller** in `lib/pergamino/web/controllers/`
   - Use `use Pergamino, :controller`
   - Set `action_fallback(Pergamino.Web.Controllers.Fallback)`
   - Delegate to application services

5. **Add routes** in `lib/pergamino/web/router.ex`
   - Under `scope "/api", Pergamino.Web do`
   - Reference as `Controllers.ControllerName`

6. **Create tests** mirroring `lib/` structure
   - Use `Pergamino.ConnCase` for controller tests
   - Test domain logic, application services, and infrastructure adapters separately

Example (minimal controller):
```elixir
# lib/pergamino/web/controllers/example.ex
defmodule Pergamino.Web.Controllers.Example do
  use Pergamino, :controller
  alias Pergamino.Application.ExampleContext
  action_fallback(Pergamino.Web.Controllers.Fallback)

  def create(conn, params) do
    with {:ok, data} <- fetch_required_param(params),
         :ok <- ExampleContext.do_something(data) do
      send_resp(conn, 202, "")
    end
  end

  defp fetch_required_param(%{"data" => data}), do: {:ok, data}
  defp fetch_required_param(_), do: {:error, :missing_data}
end
```

### Using the elixir-architect Agent

For complex Elixir tasks requiring thoughtful design and comprehensive testing, use the `elixir-architect` agent:

```
User: "I need to implement X feature"
Assistant: [Uses Task tool with subagent_type: "elixir-architect"]
```

This agent follows TDD, SOLID principles, and provides pedagogical explanations. See `.claude/agents/elixir-architect.md` for details.

## Code Style

**No Comments or Documentation**: This project emphasizes self-explanatory code over documentation:
- No `@moduledoc` - Module names and structure should be self-evident
- No `@doc` - Function names and type specs should convey intent
- No inline comments - Code should be clear enough to read directly
- Keep `@spec` type specifications - They serve as contracts, not documentation

Focus on:
- Clear, descriptive function and variable names
- Small, focused functions that do one thing
- Proper type specifications with `@spec`
- Well-structured code that reads like prose

## What's Included and NOT Included

**Included**:
- Swoosh (email sending with Finch adapter)
- Joken (JWT token generation/verification)
- Mox (testing mocks)
- LiveDashboard (development monitoring)

**NOT Included**:
- **No Ecto/Database**: In-memory state only (future: ETS/persistent_term for device keys)
- **No HTML/LiveView**: JSON API only
- **No static assets**: No CSS, JS, or image serving
- **No i18n (gettext)**: Single language only
- **No sessions/cookies**: Authentication is signature-based (planned)

## CI/CD

**Precommit Alias**: Run `mix precommit` locally before pushing:
- Compile with warnings as errors
- Check for unused dependencies
- Format code
- Run all tests

GitHub Actions workflow not yet configured.

## Key Dependencies

- **Phoenix 1.8.3**: Web framework
- **Bandit 1.5+**: HTTP server (replaces Cowboy)
- **Joken ~> 2.6**: JWT token generation and verification
- **Swoosh ~> 1.16**: Email sending
- **Finch ~> 0.16**: HTTP client (used by Swoosh)
- **Jason**: JSON encoding
- **phoenix_live_dashboard**: Development monitoring
- **Mox**: Test mocking (test only)
