defmodule Pergamino.Unit.Auth.RefreshTokenTest do
  use ExUnit.Case, async: true

  import Mox

  alias Pergamino.Infrastructure.Auth.RefreshToken
  alias Pergamino.Core.ClockMock

  setup :verify_on_exit!

  describe "generate/0" do
    test "generates a random token and expiration time" do
      now = ~U[2024-01-01 00:00:00Z]
      expected_expiration = DateTime.add(now, 15_552_000, :second)

      expect(ClockMock, :utc_now, fn -> now end)

      Application.put_env(:pergamino, :clock_adapter, ClockMock)

      {token, expires_at} = RefreshToken.generate()

      assert is_binary(token)
      assert byte_size(token) > 0
      assert expires_at == expected_expiration

      Application.delete_env(:pergamino, :clock_adapter)
    end

    test "generates URL-safe base64 encoded token" do
      {token, _expires_at} = RefreshToken.generate()

      refute String.contains?(token, "+")
      refute String.contains?(token, "/")
      refute String.contains?(token, "=")
    end

    test "generates unique tokens on each call" do
      {token1, _} = RefreshToken.generate()
      {token2, _} = RefreshToken.generate()
      {token3, _} = RefreshToken.generate()

      assert token1 != token2
      assert token2 != token3
      assert token1 != token3
    end

    test "sets expiration to 6 months in the future" do
      {_token, expires_at} = RefreshToken.generate()

      now = DateTime.utc_now()
      diff_seconds = DateTime.diff(expires_at, now, :second)

      assert diff_seconds >= 15_552_000 - 2
      assert diff_seconds <= 15_552_000 + 2
    end
  end
end
