# PhoenixPubsubConduitAMQP

A phoenix pubsub adapter that uses Conduit and ConduitAMQP.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `phoenix_pubsub_conduit_amqp` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:phoenix_pubsub_conduit_amqp, "~> 0.1.0"}
  ]
end
```

## Configuration

The adapter expects to be passed a conduit broker. The adapter needs to be started before the broker. Each node should create a unique queue subscribed to a fanout exchange.

See the broker in [test_helper.exs](https://github.com/conduitframework/phoenix_pubsub_conduit_amqp/blob/master/test/test_helper.exs) for an example.

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/phoenix_pubsub_conduit_amqp](https://hexdocs.pm/phoenix_pubsub_conduit_amqp).
