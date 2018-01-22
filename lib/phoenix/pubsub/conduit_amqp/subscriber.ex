defmodule Phoenix.PubSub.ConduitAMQP.Subscriber do
  use Conduit.Subscriber
  alias Phoenix.PubSub.Local
  require Logger

  def process(message, _opts) do
    Logger.info("Received message")
    [{:local_state, state}] = :ets.lookup(:phoenix_pubsub_conduit_amqp, :local_state)
    {_vsn, remote_node_ref, fastlane, pool_size, from_pid, topic, msg} = message.body

    if remote_node_ref == state.node_ref do
      Local.broadcast(fastlane, state.server_name, pool_size, from_pid, topic, msg)
    else
      Local.broadcast(fastlane, state.server_name, pool_size, :none, topic, msg)
    end

    message
  catch
    kind, reason ->
      kind
      |> Exception.format(reason, System.stacktrace())
      |> Logger.error()

      :erlang.raise(kind, reason, System.stacktrace())
  end
end
