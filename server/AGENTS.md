# Server Agent Documentation

This is a **simplified Phoenix API application**.
It differs from a standard Phoenix generator structure in several ways (no `_web` namespace separation, no Ecto, API-only focus).

## Project Structure & Architecture

- **Namespace**: `Pergamino` is the root namespace. There is **no** `PergaminoWeb`.
- **API-Only**: The application is configured for JSON APIs (`formats: [:json]`).
- **No Database**: Ecto is **not** included. State is managed in-memory (e.g., ETS in `Pergamino.Auth.TokenRegistry`) or stateless.
- **Entry Point**: `Pergamino.Application` is defined in `lib/pergamino.ex`.
- **Web Definitions**: `Pergamino` module (in `lib/pergamino.ex`) defines macros for `router`, `controller`, etc.
- **Router**: `Pergamino.Router` (`lib/pergamino/router.ex`).
- **Controllers**: Located in `lib/pergamino/controllers/`.

## Dependencies

- **Phoenix**: ~> 1.8
- **Server**: Bandit
- **JSON**: Jason
- **Telemetry**: Standard telemetry setup.
- **Testing**: Mox for mocks.

*Note: There is no HTTP client (like Req) or Database client (like Postgrex) installed by default.*

## Guidelines

### General

- Use `mix precommit` alias before pushing changes (runs format, lint, test).
- **Naming**: Follow standard Elixir naming conventions (`snake_case` for files/functions, `CamelCase` for modules).

### Elixir

- **Lists**: Do not use index-based access (`list[i]`). Use `Enum.at/2` or pattern matching.
- **Immutability**: Rebind variables if you need the result of a block (e.g., `socket = if ...`).
- **Safety**: Do not use `String.to_atom/1` on dynamic user input.
- **Modules**: Avoid nesting multiple modules in one file.

### Phoenix / Controllers

- **Context**: The `Pergamino` module serves as the "Web" context.
  - Use `use Pergamino, :controller` for controllers.
  - Use `use Pergamino, :router` for routers.
- **Routes**: Defined in `lib/pergamino/router.ex` under the `/api` scope.
- **JSON**: Responses are JSON. Use `json(conn, data)`.

### Testing

- **ConnCase**: Use `Pergamino.ConnCase` for controller tests. It provides `build_conn()` but **does not** provide an Ecto sandbox (as there is no DB).
- **Process Safety**:
  - Use `start_supervised!/1` for starting processes in tests.
  - Use `Process.monitor/1` and `assert_receive {:DOWN, ...}` instead of `Process.sleep/1`.
  - Use `:sys.get_state/1` for synchronization if needed.

## Key Modules

- `Pergamino.Auth.TokenRegistry`: Example of an in-memory GenServer + ETS solution for state.
- `Pergamino.AuthController`: Example of a simple JSON controller.
