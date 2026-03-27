# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Pergamino is a minimal Phoenix JSON API server. The project follows clean architecture principles with clear separation between domain logic, application services and infrastructure concerns.

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

This project uses a three-tier testing strategy. See `test/README.md` for details.

```bash
# Run all tests
mix test

# Run only unit tests (fast, no external dependencies)
mix test.unit

# Run only integration tests (with Redis, email adapters)
mix test.integration

# Run only component tests (full HTTP stack)
mix test.component

# Run a specific test file
mix test test/pergamino/unit/auth/oauth2_flow_test.exs

# Run a specific test (by line number)
mix test test/pergamino/component/web/controllers/verification_email_controller_test.exs:17
```

## Architecture

### Clean Architecture Layers

The codebase follows clean architecture principles with clear layer separation:

- **Domain Layer** (`lib/pergamino/domain/`): Core business logic and rules
  - Value Objects: `Pergamino.Domain.EmailAddress`
  - No dependencies on infrastructure or frameworks

- **Application Layer** (`lib/pergamino/application/`): Application services orchestrating use cases
  - Services: `Pergamino.Application.VerificationEmail`
  - Coordinates domain objects and infrastructure adapters
  - Contains business workflows

- **Core Layer** (`lib/pergamino/core/`): Shared utilities used across all layers
  - Time abstraction: `Pergamino.Core.Clock`
  - Cross-cutting concerns and utilities

- **Infrastructure Layer** (`lib/pergamino/infrastructure/`): External service adapters
  - Auth adapters: `Pergamino.Infrastructure.Auth.TokenGenerator`, `AuthorizationCode`
  - Messaging adapters: `Pergamino.Infrastructure.Messaging.EmailSender`
  - Implements external integrations (JWT, email, Redis, etc.)

- **Web Layer** (`lib/pergamino/web/`): HTTP interface and controllers
  - Endpoint: `Pergamino.Web.Endpoint`
  - Router: `Pergamino.Web.Router`
  - Controllers: `Pergamino.Web.Controllers.*`
  - Error handling: `Pergamino.Web.ErrorHandler`, `Pergamino.Web.ProblemDetails`
  - Telemetry: `Pergamino.Web.Telemetry`

### Configuration Structure

- `config/config.exs` - Base configuration for all environments
- `config/dev.exs` - Development-specific (LiveDashboard enabled via `dev_routes: true`)
- `config/test.exs` - Test environment (`server: false`)
- `config/prod.exs` - Production base config
- `config/runtime.exs` - Runtime configuration (reads ENV vars)

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
- Example: `Pergamino.Application.VerificationEmail.send/1`

**Infrastructure Adapters**: Implement external integrations
- Located in `lib/pergamino/infrastructure/`
- Handle external concerns (JWT, email, databases, etc.)
- Examples: `TokenGenerator`, `EmailSender`

**Controllers**: Thin HTTP interface layer
- Validate HTTP requests and extract parameters
- Call infrastructure adapters (e.g., token generation)
- Delegate business logic to application services
- Handle errors via `action_fallback(Pergamino.Web.Controllers.Fallback)`

### Using the elixir-architect Agent

For tasks requiring thoughtful design and comprehensive testing, use the `elixir-architect` agent.
This agent follows TDD, SOLID principles, and provides pedagogical explanations.

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

## Windows Development

brod (Kafka client) depends on `snappyer` and `crc32cer` which are C/C++ NIFs. These require a C++ compiler on Windows.

### Prerequisites
- MinGW-w64: `choco install mingw` or `scoop install gcc`
- Ensure `g++` / `c++` is available in PATH after installation

### Setup
`mix setup` automatically patches `crc32cer` for MinGW and recompiles the NIFs on Windows (no-op on other platforms). If you run `mix deps.get` separately, run `mix setup.windows` afterwards.

## Key Dependencies

- **Phoenix 1.8.3**: Web framework
- **Bandit 1.5+**: HTTP server (replaces Cowboy)
- **Joken ~> 2.6**: JWT token generation and verification
- **Swoosh ~> 1.16**: Email sending
- **Finch ~> 0.16**: HTTP client (used by Swoosh)
- **Jason**: JSON encoding
- **phoenix_live_dashboard**: Development monitoring
- **Mox**: Test mocking (test only)
