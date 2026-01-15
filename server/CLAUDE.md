# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Pergamino is a minimal Phoenix JSON API server with Ed25519-based authentication. The project has been intentionally simplified, removing Ecto, PostgreSQL, HTML views, static assets, i18n, and mailer functionality to keep it focused on JSON API endpoints.

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
mix test test/pergamino/web/controllers/auth_controller_test.exs

# Run a specific test (by line number)
mix test test/pergamino/web/controllers/auth_controller_test.exs:5

# Run tests with coverage
mix test --cover
```

## Architecture

### Namespace Structure (IMPORTANT)

This project uses `Pergamino.Web.*` namespace structure, NOT the Phoenix standard `PergaminoWeb.*`. This is an intentional architectural decision. All web-related modules live under the `Pergamino.Web` namespace:

- **Web Layer**: `Pergamino.Web.*` (`lib/pergamino/web/`)
  - Endpoint: `Pergamino.Web.Endpoint`
  - Router: `Pergamino.Web.Router`
  - Controllers: `Pergamino.Web.Controllers.*` (e.g., `Pergamino.Web.Controllers.Auth`, `Pergamino.Web.Controllers.ErrorJSON`)
  - Telemetry: `Pergamino.Web.Telemetry`

- **Application Core**: `Pergamino.*` (`lib/pergamino.ex`)
  - Application supervisor: `Pergamino.Application`
  - Using macros: `Pergamino` (provides `:router`, `:controller`, `:channel` macros)

**Critical**:
- When adding new controllers, use `scope "/api", Pergamino.Web do` in the router
- Controller references in routes should be `Controllers.ControllerName` (e.g., `Controllers.Auth`)

### Module Organization

```
lib/pergamino.ex                              # Application + using macros
lib/pergamino/web/
  ├── endpoint.ex                             # Phoenix endpoint (HTTP server entry)
  ├── router.ex                               # Route definitions
  ├── telemetry.ex                            # Metrics and monitoring
  └── controllers/
      ├── auth_controller.ex                  # Pergamino.Web.Controllers.Auth
      └── error_json.ex                       # Pergamino.Web.Controllers.ErrorJSON

test/
  ├── support/conn_case.ex                    # Test helpers for controllers
  └── pergamino/web/controllers/              # Controller tests mirror lib structure
```

### Supervision Tree

```
Pergamino.Supervisor (one_for_one)
├── Pergamino.Web.Telemetry
├── DNSCluster (for distributed Erlang)
├── Phoenix.PubSub (Pergamino.PubSub)
└── Pergamino.Web.Endpoint
```

### Configuration Structure

- `config/config.exs` - Base configuration for all environments
- `config/dev.exs` - Development-specific (LiveDashboard enabled via `dev_routes: true`)
- `config/test.exs` - Test environment (`server: false`)
- `config/prod.exs` - Production base config
- `config/runtime.exs` - Runtime configuration (reads ENV vars)

**Note**: `phoenix_live_dashboard` is available in all environments but routes are only enabled when `dev_routes: true` (development only).

### Authentication Architecture (Planned)

The project will implement Ed25519 signature-based authentication:

1. **Initial Registration Flow** (JWT-based):
   - POST `/auth/login` → Returns deeplink with JWT token
   - Mobile app extracts JWT from deeplink
   - Mobile generates Ed25519 keypair
   - POST `/auth/verify` with JWT + public key
   - Server validates JWT and stores public key

2. **Ongoing Authentication** (Signature-based):
   - All requests signed with Ed25519 private key
   - Custom headers: `X-Device-ID`, `X-Timestamp`, `X-Signature`
   - Server verifies signatures using stored public keys

Currently, only the first endpoint exists with hardcoded response.

## Important Patterns

### Adding New Controllers

1. Create controller in `lib/pergamino/web/controllers/`
2. Use `use Pergamino, :controller` (NOT `use Pergamino.Web, :controller`)
3. Add route in router under `scope "/api", Pergamino.Web do`
4. Create test in `test/pergamino/web/controllers/`
5. Use `Pergamino.ConnCase` for controller tests

Example:
```elixir
# lib/pergamino/web/controllers/user_controller.ex
defmodule Pergamino.Web.Controllers.User do
  use Pergamino, :controller

  def show(conn, _params) do
    json(conn, %{status: "ok"})
  end
end

# lib/pergamino/web/router.ex
scope "/api", Pergamino.Web do
  pipe_through :api
  get "/users/:id", Controllers.User, :show
end

# test/pergamino/web/controllers/user_controller_test.exs
defmodule Pergamino.Web.Controllers.UserTest do
  use Pergamino.ConnCase

  test "GET /api/users/:id returns ok", %{conn: conn} do
    conn = get(conn, ~p"/api/users/1")
    assert json_response(conn, 200)["status"] == "ok"
  end
end
```

### Using the elixir-architect Agent

For complex Elixir tasks requiring thoughtful design and comprehensive testing, use the `elixir-architect` agent:

```
User: "I need to implement X feature"
Assistant: [Uses Task tool with subagent_type: "elixir-architect"]
```

This agent follows TDD, SOLID principles, and provides pedagogical explanations. See `.claude/agents/elixir-architect.md` for details.

## What's NOT in This Project

- **No Ecto/Database**: All removed to keep the API minimal
- **No HTML/LiveView**: JSON API only
- **No static assets**: No CSS, JS, or image serving
- **No i18n (gettext)**: Single language only
- **No mailer (Swoosh)**: No email functionality
- **No sessions/cookies**: Authentication will be signature-based

## CI/CD

GitHub Actions workflow (`.github/workflows/ci.yml`) runs on every push:
- Elixir 1.19 / OTP 27
- Steps: deps, compile (warnings as errors), format check, tests

## Key Dependencies

- Phoenix 1.8.3 (web framework)
- Bandit 1.5+ (HTTP server, replaces Cowboy)
- Phoenix.PubSub (for future SSE broadcasting)
- Jason (JSON encoding)
- phoenix_live_dashboard (dev monitoring)
- Mox (test mocking)
