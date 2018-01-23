# PhoenixPubsubConduitAMQP

A phoenix pubsub adapter that uses Conduit and ConduitAMQP.

Phoenix PubSub handles distributing messages between nodes to regarding websockets. It is useful in
the scenario where a websocket connection is made to server A and later a web request or message is
received on server B that needs to broadcast to the websocket on server A. The pubsub adapter is
then able to distribute that information to any server, which may have a relevant websocket
connection.

This adapter uses a [Conduit](https://github.com/conduitframework/conduit) broker and
[ConduitAMQP](https://github.com/conduitframework/conduit) as the mechanism to distribute messages
between servers.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `phoenix_pubsub_conduit_amqp` to your list of dependencies in `mix.exs`:

``` elixir
# mix.exs
def deps do
  [
    {:phoenix_pubsub_conduit_amqp, "~> 0.1.0"}
  ]
end
```

## Configuration

``` elixir
# config.exs
config :my_app, MyApp.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "i5mdMSK9FcLUMAyIqtyptYPQrWTdIZJJ8N8eSseqn/LrW3ynJcTexai990u9Ea/K",
  render_errors: [view: MyApp.ErrorView, accepts: ~w(json)],
  pubsub: [
    name: MyApp.PubSub,
    adapter: Phoenix.PubSub.ConduitAMQP,
    broker: MyApp.Broker]
```

The adapter expects to be passed a conduit broker as an option.

## Application Startup

Your broker should be configured to start after your endpoint.

``` elixir
# my_app.ex or application.ex
def start(_type, _args) do
  import Supervisor.Spec

  children = [
    supervisor(MyApp.Endpoint, []),
    supervisor(MyApp.Broker, [])
  ]

  opts = [strategy: :one_for_one, name: MyApp.Supervisor]
  Supervisor.start_link(children, opts)
end
```

## Broker

The broker must have an outgoing publish called `phoenix_pubsub_broadcast` and must have a
subscription that uses `Phoenix.PubSub.ConduitAMQP.Subscriber`.

Additionally, the subscriber should be uniquely bound per server to the exchange that
`phoenix_pubsub_broadcast` publishes to.

A minimal example of a broker that will work is:

``` elixir
defmodule MyApp.Broker do
  use Conduit.Broker, otp_app: :my_app

  configure do
    # All messages published to this exchange will be published to every bound queue
    exchange "phoenix.pubsub", type: :fanout

    # Will create queue name based on hostname and bind it to the fanout exchange. If the
    # server restarts, the queue will be removed and recreated, since the messages in the
    # queue are for websocket connections that no longer exist.
    queue &Phoenix.PubSub.ConduitAMQP.queue_name/0,
      exchange: "phoenix.pubsub",
      auto_delete: false,
      from: ["#"]
  end

  pipeline :phoenix_pubsub_incoming do
    # plug Conduit.Plug.LogIncoming
    # plug Conduit.Plug.AckException

    # Turns erlang binary into data
    plug Conduit.Plug.Parse
  end

  incoming Phoenix.PubSub.ConduitAMQP do
    pipe_through [:phoenix_pubsub_incoming]

    # Subscribe to messages published to the phoenix.pubsub exchange that are deposited in this
    # server specific queue.
    subscribe :phoenix_pubsub_receive, Subscriber,
      from: &Phoenix.PubSub.ConduitAMQP.queue_name/1
  end

  pipeline :phoenix_pubsub_outgoing do
    # plug Conduit.Plug.LogOutgoing

    # Turns data into erlang binary, other formats are lossy
    plug Conduit.Plug.Format,
      content_type: "application/x-erlang-binary",
      compressed: 6
  end

  outgoing do
    pipe_through [:phoenix_pubsub_outgoing]

    # Publish to phoenix.pubsub exchange with phoenix.pubsub routing key
    publish :phoenix_pubsub_broadcast,
      exchange: "phoenix.pubsub",
      to: "phoenix.pubsub"
  end
end
```

See [ConduitAMQP](https://github.com/conduitframework/conduit_amqp) and
[Conduit](https://github.com/conduitframework/conduit) for more about configuring a broker.

## Documentation

Documentation can found at
[https://hexdocs.pm/phoenix_pubsub_conduit_amqp](https://hexdocs.pm/phoenix_pubsub_conduit_amqp).
