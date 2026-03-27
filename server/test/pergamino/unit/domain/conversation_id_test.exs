defmodule Pergamino.Unit.Domain.ConversationIdTest do
  use ExUnit.Case, async: true

  alias Pergamino.Domain.ConversationId

  describe "create/1" do
    test "valid UUID v4 lowercase succeeds" do
      assert {:ok, %ConversationId{value: "550e8400-e29b-41d4-a716-446655440000"}} =
               ConversationId.create("550e8400-e29b-41d4-a716-446655440000")
    end

    test "valid UUID v4 uppercase succeeds" do
      assert {:ok, %ConversationId{}} =
               ConversationId.create("550E8400-E29B-41D4-A716-446655440000")
    end

    test "UUID v1 format fails" do
      assert {:error, :invalid_conversation_id} =
               ConversationId.create("6ba7b810-9dad-11d1-80b4-00c04fd430c8")
    end

    test "random string fails" do
      assert {:error, :invalid_conversation_id} = ConversationId.create("not-a-uuid")
    end

    test "empty string fails" do
      assert {:error, :invalid_conversation_id} = ConversationId.create("")
    end

    test "nil fails" do
      assert {:error, :invalid_conversation_id} = ConversationId.create(nil)
    end
  end
end
