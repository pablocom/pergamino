defmodule Pergamino.Unit.Auth.OAuth2FlowTest do
  use ExUnit.Case, async: true

  import Mox

  alias Pergamino.Domain.EmailAddress
  alias Pergamino.Infrastructure.Auth.OAuth2Flow
  alias Pergamino.Infrastructure.Auth.AuthorizationCodeStoreMock
  alias Pergamino.Infrastructure.Auth.RefreshTokenStoreMock
  alias Pergamino.Infrastructure.Messaging.EmailSenderMock

  setup :verify_on_exit!

  setup do
    stub(AuthorizationCodeStoreMock, :store, fn _, _, _, _ -> :ok end)
    stub(AuthorizationCodeStoreMock, :retrieve_and_delete, fn _ -> {:error, :code_not_found} end)
    stub(RefreshTokenStoreMock, :store, fn _, _, _ -> :ok end)
    stub(RefreshTokenStoreMock, :retrieve_and_delete, fn _ -> {:error, :token_not_found} end)
    stub(EmailSenderMock, :send_verification_email, fn _, _ -> {:ok, %{}} end)

    Application.put_env(:pergamino, :authorization_code_store, AuthorizationCodeStoreMock)
    Application.put_env(:pergamino, :refresh_token_store, RefreshTokenStoreMock)
    Application.put_env(:pergamino, :email_sender, EmailSenderMock)

    on_exit(fn ->
      Application.delete_env(:pergamino, :authorization_code_store)
      Application.delete_env(:pergamino, :refresh_token_store)
      Application.delete_env(:pergamino, :email_sender)
    end)

    :ok
  end

  describe "initiate/1" do
    test "successfully initiates OAuth2 flow with valid params" do
      email = "test@example.com"
      challenge = "test_challenge"

      expect(AuthorizationCodeStoreMock, :store, fn code, expires_at, email_obj, ^challenge ->
        assert is_binary(code)
        assert %DateTime{} = expires_at
        assert %EmailAddress{address: ^email} = email_obj
        :ok
      end)

      expect(EmailSenderMock, :send_verification_email, fn email_obj, deeplink ->
        assert %EmailAddress{address: ^email} = email_obj
        assert String.starts_with?(deeplink, "pergamino://bind?code=")
        {:ok, %{}}
      end)

      assert :ok = OAuth2Flow.initiate(%{email: email, code_challenge: challenge})
    end

    test "returns error for invalid email format" do
      assert {:error, :invalid_email} =
               OAuth2Flow.initiate(%{email: "not-an-email", code_challenge: "challenge"})
    end

    test "returns error when code store fails" do
      expect(AuthorizationCodeStoreMock, :store, fn _, _, _, _ ->
        {:error, :redis_unavailable}
      end)

      assert {:error, :redis_unavailable} =
               OAuth2Flow.initiate(%{email: "test@example.com", code_challenge: "challenge"})
    end

    test "returns error when email sending fails" do
      expect(EmailSenderMock, :send_verification_email, fn _, _ ->
        {:error, :email_delivery_failed}
      end)

      assert {:error, :email_delivery_failed} =
               OAuth2Flow.initiate(%{email: "test@example.com", code_challenge: "challenge"})
    end

    test "normalizes email to lowercase" do
      expect(AuthorizationCodeStoreMock, :store, fn _, _, email_obj, _ ->
        assert %EmailAddress{address: "test@example.com"} = email_obj
        :ok
      end)

      expect(EmailSenderMock, :send_verification_email, fn email_obj, _ ->
        assert %EmailAddress{address: "test@example.com"} = email_obj
        {:ok, %{}}
      end)

      OAuth2Flow.initiate(%{email: "Test@Example.COM", code_challenge: "test_challenge"})
    end
  end

  describe "exchange_authorization_code/1" do
    test "successfully exchanges code for tokens with valid params" do
      code = "test_code"
      verifier = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
      challenge = :crypto.hash(:sha256, verifier) |> Base.url_encode64(padding: false)
      email = "test@example.com"

      expect(AuthorizationCodeStoreMock, :retrieve_and_delete, fn ^code ->
        {:ok, email, challenge}
      end)

      expect(RefreshTokenStoreMock, :store, fn token, expires_at, email_obj ->
        assert is_binary(token)
        assert %DateTime{} = expires_at
        assert %EmailAddress{address: ^email} = email_obj
        :ok
      end)

      assert {:ok, response} =
               OAuth2Flow.exchange_authorization_code(%{code: code, code_verifier: verifier})

      assert %{
               access_token: access_token,
               refresh_token: refresh_token,
               token_type: "Bearer",
               expires_in: 900
             } = response

      assert is_binary(access_token)
      assert is_binary(refresh_token)
    end

    test "returns error for invalid authorization code" do
      assert {:error, :invalid_authorization_code} =
               OAuth2Flow.exchange_authorization_code(%{
                 code: "invalid_code",
                 code_verifier: "verifier"
               })
    end

    test "returns error for invalid code_verifier" do
      code = "test_code"
      verifier = "correct_verifier"
      challenge = :crypto.hash(:sha256, verifier) |> Base.url_encode64(padding: false)

      expect(AuthorizationCodeStoreMock, :retrieve_and_delete, fn ^code ->
        {:ok, "test@example.com", challenge}
      end)

      assert {:error, :invalid_authorization_code} =
               OAuth2Flow.exchange_authorization_code(%{
                 code: code,
                 code_verifier: "wrong_verifier"
               })
    end

    test "returns error when email from store is invalid" do
      code = "test_code"
      verifier = "test_verifier"
      challenge = :crypto.hash(:sha256, verifier) |> Base.url_encode64(padding: false)

      expect(AuthorizationCodeStoreMock, :retrieve_and_delete, fn ^code ->
        {:ok, "not-an-email", challenge}
      end)

      assert {:error, :invalid_authorization_code} =
               OAuth2Flow.exchange_authorization_code(%{
                 code: code,
                 code_verifier: verifier
               })
    end

    test "returns error when code store is unavailable" do
      expect(AuthorizationCodeStoreMock, :retrieve_and_delete, fn _ ->
        {:error, :redis_unavailable}
      end)

      assert {:error, :redis_unavailable} =
               OAuth2Flow.exchange_authorization_code(%{
                 code: "test_code",
                 code_verifier: "verifier"
               })
    end

    test "returns error when refresh token store is unavailable" do
      code = "test_code"
      verifier = "test_verifier"
      challenge = :crypto.hash(:sha256, verifier) |> Base.url_encode64(padding: false)

      expect(AuthorizationCodeStoreMock, :retrieve_and_delete, fn ^code ->
        {:ok, "test@example.com", challenge}
      end)

      expect(RefreshTokenStoreMock, :store, fn _, _, _ ->
        {:error, :dynamodb_unavailable}
      end)

      assert {:error, :dynamodb_unavailable} =
               OAuth2Flow.exchange_authorization_code(%{
                 code: code,
                 code_verifier: verifier
               })
    end
  end

  describe "refresh_access_token/1" do
    test "successfully refreshes access token with valid refresh token" do
      old_token = "old_refresh_token"
      email = "test@example.com"

      expect(RefreshTokenStoreMock, :retrieve_and_delete, fn ^old_token ->
        {:ok, email}
      end)

      expect(RefreshTokenStoreMock, :store, fn new_token, expires_at, email_obj ->
        assert is_binary(new_token)
        assert new_token != old_token
        assert %DateTime{} = expires_at
        assert %EmailAddress{address: ^email} = email_obj
        :ok
      end)

      assert {:ok, response} = OAuth2Flow.refresh_access_token(old_token)

      assert %{
               access_token: new_access_token,
               refresh_token: new_refresh_token,
               token_type: "Bearer",
               expires_in: 900
             } = response

      assert is_binary(new_access_token)
      assert is_binary(new_refresh_token)
      assert new_refresh_token != old_token
    end

    test "returns error for invalid refresh token" do
      assert {:error, :invalid_refresh_token} =
               OAuth2Flow.refresh_access_token("invalid_token")
    end

    test "returns error when token store is unavailable on retrieve" do
      expect(RefreshTokenStoreMock, :retrieve_and_delete, fn _ ->
        {:error, :dynamodb_unavailable}
      end)

      assert {:error, :dynamodb_unavailable} =
               OAuth2Flow.refresh_access_token("some_token")
    end

    test "returns error when email from store is invalid" do
      expect(RefreshTokenStoreMock, :retrieve_and_delete, fn _ ->
        {:ok, "not-an-email"}
      end)

      assert {:error, :invalid_refresh_token} =
               OAuth2Flow.refresh_access_token("some_token")
    end

    test "returns error when storing new refresh token fails" do
      old_token = "old_token"
      email = "test@example.com"

      expect(RefreshTokenStoreMock, :retrieve_and_delete, fn ^old_token ->
        {:ok, email}
      end)

      expect(RefreshTokenStoreMock, :store, fn _, _, _ ->
        {:error, :dynamodb_unavailable}
      end)

      assert {:error, :dynamodb_unavailable} =
               OAuth2Flow.refresh_access_token(old_token)
    end
  end
end
