defmodule Pergamino.Infrastructure.Auth.OAuth2Flow do
  require Logger

  alias Pergamino.Domain.EmailAddress

  alias Pergamino.Infrastructure.Auth.{
    AuthorizationCode,
    AuthorizationCodeStore,
    RefreshToken,
    RefreshTokenStore,
    TokenGenerator
  }

  alias Pergamino.Infrastructure.Messaging.EmailSender

  @type initiate_params :: %{
          email: String.t(),
          code_challenge: String.t()
        }

  @type exchange_params :: %{
          code: String.t(),
          code_verifier: String.t()
        }

  @type token_response :: %{
          access_token: String.t(),
          refresh_token: String.t(),
          token_type: String.t(),
          expires_in: integer()
        }

  @spec initiate(initiate_params()) ::
          :ok
          | {:error, :invalid_email}
          | {:error, term()}
  def initiate(%{email: email_string, code_challenge: challenge_string}) do
    code_store = code_store()
    email_sender = email_sender()

    with {:ok, email} <- EmailAddress.create(email_string),
         {code, expires_at} <- AuthorizationCode.generate(),
         :ok <- code_store.store(code, expires_at, email, challenge_string),
         {:ok, _} <- email_sender.send_verification_email(email, build_deeplink(code)) do
      :ok
    end
  end

  @spec exchange_authorization_code(exchange_params()) ::
          {:ok, token_response()}
          | {:error, :invalid_authorization_code}
          | {:error, term()}
  def exchange_authorization_code(%{code: code, code_verifier: verifier}) do
    code_store = code_store()
    token_store = refresh_token_store()

    with {:ok, email_string, pkce_challenge} <- code_store.retrieve_and_delete(code),
         :ok <- verify_pkce(pkce_challenge, verifier),
         {:ok, email} <- EmailAddress.create(email_string),
         {:ok, access_token} <- TokenGenerator.generate(email),
         {refresh_token, refresh_expires_at} <- RefreshToken.generate(),
         :ok <- token_store.store(refresh_token, refresh_expires_at, email) do
      {:ok, build_token_response(access_token, refresh_token)}
    else
      {:error, error} when error in [:code_not_found, :invalid_code_verifier] ->
        {:error, :invalid_authorization_code}

      {:error, :invalid_email} ->
        Logger.error("Invalid email stored in Redis during token exchange: #{code}")
        {:error, :invalid_authorization_code}

      {:error, other_error} ->
        {:error, other_error}
    end
  end

  @spec refresh_access_token(String.t()) ::
          {:ok, token_response()}
          | {:error, :invalid_refresh_token}
          | {:error, term()}
  def refresh_access_token(refresh_token_string) do
    token_store = refresh_token_store()

    with {:ok, email_string} <- token_store.retrieve_and_delete(refresh_token_string),
         {:ok, email} <- EmailAddress.create(email_string),
         {:ok, access_token} <- TokenGenerator.generate(email),
         {new_refresh_token, refresh_expires_at} <- RefreshToken.generate(),
         :ok <- token_store.store(new_refresh_token, refresh_expires_at, email) do
      {:ok, build_token_response(access_token, new_refresh_token)}
    else
      {:error, error} when error in [:token_not_found, :invalid_email] ->
        if error == :invalid_email do
          Logger.error("Invalid email stored in DynamoDB during token refresh")
        end

        {:error, :invalid_refresh_token}

      {:error, other_error} ->
        {:error, other_error}
    end
  end

  defp code_store do
    Application.get_env(:pergamino, :authorization_code_store, AuthorizationCodeStore)
  end

  defp refresh_token_store do
    Application.get_env(:pergamino, :refresh_token_store, RefreshTokenStore)
  end

  defp email_sender do
    Application.get_env(:pergamino, :email_sender, EmailSender)
  end

  defp build_deeplink(code) when is_binary(code), do: "pergamino://bind?code=#{code}"

  defp build_token_response(access_token, refresh_token) do
    %{
      access_token: access_token,
      refresh_token: refresh_token,
      token_type: "Bearer",
      expires_in: TokenGenerator.access_token_expiration_seconds()
    }
  end

  defp verify_pkce(challenge, verifier) do
    computed_challenge = :crypto.hash(:sha256, verifier) |> Base.url_encode64(padding: false)

    if byte_size(computed_challenge) == byte_size(challenge) &&
         :crypto.hash_equals(computed_challenge, challenge) do
      :ok
    else
      {:error, :invalid_code_verifier}
    end
  end
end
