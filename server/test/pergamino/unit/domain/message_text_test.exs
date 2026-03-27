defmodule Pergamino.Unit.Domain.MessageTextTest do
  use ExUnit.Case, async: true

  alias Pergamino.Domain.MessageText

  describe "create/1" do
    test "valid text succeeds" do
      assert {:ok, %MessageText{content: "Hello, world!"}} =
               MessageText.create("Hello, world!")
    end

    test "empty string fails" do
      assert {:error, :invalid_message_text} = MessageText.create("")
    end

    test "exactly 1500 chars succeeds" do
      text = String.duplicate("a", 1500)
      assert {:ok, %MessageText{content: ^text}} = MessageText.create(text)
    end

    test "1501 chars fails" do
      text = String.duplicate("a", 1501)
      assert {:error, :invalid_message_text} = MessageText.create(text)
    end

    test "nil fails" do
      assert {:error, :invalid_message_text} = MessageText.create(nil)
    end
  end
end
