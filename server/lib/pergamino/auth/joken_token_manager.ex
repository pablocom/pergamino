defmodule Pergamino.Auth.JokenTokenManager do
  alias Pergamino.Auth.JokenTokenManager.Token

  @behaviour Pergamino.Auth.TokenManager

  @impl Pergamino.Auth.TokenManager
  def generate(email) do
    case Token.generate_and_sign(%{"email" => email}, Token.signer()) do
      {:ok, token, _claims} -> {:ok, token}
      {:error, _} = err -> err
    end
  end

  @impl Pergamino.Auth.TokenManager
  def verify(token) do
    Token.verify_and_validate(token, Token.signer())
  end

  defmodule Token do
    use Joken.Config

    def signer do
      secret = Application.fetch_env!(:pergamino, :jwt_secret_key)
      Joken.Signer.create("HS256", secret)
    end

    @impl true
    def token_config do
      default_claims(iss: "pergamino", default_exp: 600)
      |> add_claim("email", nil, &(&1 != nil))
    end
  end
end
