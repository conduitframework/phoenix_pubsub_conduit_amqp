defmodule PhoenixPubsubConduitAmqpTest do
  use ExUnit.Case
  doctest PhoenixPubsubConduitAmqp

  test "greets the world" do
    assert PhoenixPubsubConduitAmqp.hello() == :world
  end
end
