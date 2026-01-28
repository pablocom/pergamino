defmodule Pergamino.Unit.Web.Errors.InfrastructureErrorTest do
  use ExUnit.Case, async: true

  alias Pergamino.Web.Errors.InfrastructureError

  describe "service_unavailable/1" do
    test "creates error for redis service" do
      error = InfrastructureError.service_unavailable(:redis)

      assert %InfrastructureError{
               service: :redis,
               code: :service_unavailable,
               message: "Service temporarily unavailable",
               details: %{}
             } = error
    end

    test "creates error for dynamodb service" do
      error = InfrastructureError.service_unavailable(:dynamodb)

      assert %InfrastructureError{
               service: :dynamodb,
               code: :service_unavailable,
               message: "Service temporarily unavailable"
             } = error
    end

    test "creates error for email service" do
      error = InfrastructureError.service_unavailable(:email)

      assert %InfrastructureError{
               service: :email,
               code: :service_unavailable,
               message: "Service temporarily unavailable"
             } = error
    end
  end
end
