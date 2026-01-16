defmodule Pergamino.Auth.Token do

  alias Pergamino.Domain.Email

  alias __MODULE__.JokenToken

  @type claims :: %{
          required(:email) => String.t(),
          required(:exp) => integer(),
          required(:iat) => integer(),
          required(:iss) => String.t()
        }
  @type error :: Joken.error_reason()

  @spec generate(email :: Email.t()) :: {:ok, String.t()} | {:error, error()}
  def generate(%Email{} = email) do
    case JokenToken.generate_and_sign(%{"email" => email.address}, signer()) do
      {:ok, token, _claims} -> {:ok, token}
      {:error, _reason} = err -> err
    end
  end

  @spec verify(token :: String.t()) :: {:ok, claims()} | {:error, error()}
  def verify(token) do
    JokenToken.verify_and_validate(token, signer())
  end

  defp signer, do: :persistent_term.get({:pergamino, :jwt_signer})

  defmodule JokenToken do
    @moduledoc false
    use Joken.Config

    @expiration_in_seconds 600

    @impl Joken.Config
    def token_config do
      default_claims(iss: "pergamino", default_exp: @expiration_in_seconds)
      |> add_claim("email", nil, &(&1 != nil))
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
