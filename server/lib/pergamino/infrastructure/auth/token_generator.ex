defmodule Pergamino.Infrastructure.Auth.TokenGenerator do
  alias Pergamino.Domain.EmailAddress

  alias __MODULE__.AccessToken

  @type access_claims :: %{
          required(:email) => String.t(),
          required(:typ) => String.t(),
          required(:exp) => integer(),
          required(:iat) => integer(),
          required(:iss) => String.t(),
          required(:aud) => String.t()
        }
  @type error :: Joken.error_reason()

  @access_token_expiration_seconds 900

  def access_token_expiration_seconds, do: @access_token_expiration_seconds

  @spec generate(email :: EmailAddress.t()) :: {:ok, String.t()} | {:error, error()}
  def generate(%EmailAddress{} = email) do
    case AccessToken.generate_and_sign(%{"email" => email.address, "typ" => "access"}, signer()) do
      {:ok, token, _claims} -> {:ok, token}
      {:error, _reason} = err -> err
    end
  end

  @spec verify(token :: String.t()) :: {:ok, access_claims()} | {:error, error()}
  def verify(token) do
    AccessToken.verify_and_validate(token, signer())
  end

  defp signer, do: :persistent_term.get({:pergamino, :jwt_signer})

  defmodule AccessToken do
    @moduledoc false
    use Joken.Config

    @impl Joken.Config
    def token_config do
      default_claims(
        aud: "pergamino",
        iss: "pergamino",
        default_exp: 900
      )
      |> add_claim("email", nil, &(&1 != nil))
      |> add_claim("typ", nil, &(&1 == "access"))
    end
  end

  defmodule SignerLoader do
    use Task

    def start_link(_arg) do
      Task.start_link(fn ->
        jwt_secret_key = Application.fetch_env!(:pergamino, :jwt_secret_key)
        signer = Joken.Signer.create("HS256", jwt_secret_key)

        :persistent_term.put({:pergamino, :jwt_signer}, signer)
      end)
    end
  end
end
