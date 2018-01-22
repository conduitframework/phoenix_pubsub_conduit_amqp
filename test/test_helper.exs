defmodule TestBroker do
  use Conduit.Broker, otp_app: :phoenix_pubsub_conduit_amqp

  configure do
    exchange("phoenix.pubsub", type: :fanout)

    queue(
      &Phoenix.PubSub.ConduitAMQP.queue_name/0,
      exchange: "phoenix.pubsub",
      auto_delete: false,
      from: ["#"]
    )
  end

  pipeline :phoenix_pubsub_incoming do
    plug(Conduit.Plug.LogIncoming)
    plug(Conduit.Plug.AckException)
    plug(Conduit.Plug.Parse)
  end

  incoming Phoenix.PubSub.ConduitAMQP do
    pipe_through([:phoenix_pubsub_incoming])

    subscribe(:phoenix_pubsub_receive, Subscriber, from: &Phoenix.PubSub.ConduitAMQP.queue_name/1)
  end

  pipeline :phoenix_pubsub_outgoing do
    plug Conduit.Plug.LogOutgoing
    plug(
      Conduit.Plug.Format,
      content_type: "application/x-erlang-binary",
      compressed: 6
    )
  end

  outgoing do
    pipe_through([:phoenix_pubsub_outgoing])

    publish(
      :phoenix_pubsub_broadcast,
      exchange: "phoenix.pubsub",
      to: "phoenix.pubsub"
    )
  end
end

ExUnit.start()

# Turn node into a distributed node with the given long name
case :net_kernel.start([:"conduit_amqp@127.0.0.1"]) do
  {:ok, _pid} ->
    :ok

  other ->
    raise """
    unable to start conduit_amqp tests. Is epmd running and daemonized?
    You may need to run `$ epmd -daemon`.
        #{inspect(other)}
    """
end
