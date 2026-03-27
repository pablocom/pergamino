defmodule Pergamino.Infrastructure.Messaging.MessageBrokerBehaviour do
  @callback publish(topic :: String.t(), key :: String.t(), payload :: map()) ::
              :ok | {:error, term()}
end
