defmodule Phoenix.PubSub.ConduitAMQP do
  use Supervisor
  require Logger

  @moduledoc """
  Phoenix PubSub adapter based on PG2.

  To use it as your PubSub adapter, simply add it to your Endpoint's config:

      config :my_app, MyApp.Endpoint,
        pubsub: [name: MyApp.PubSub,
                  adapter: Phoenix.PubSub.ConduitAQMP]

  ## Options

    * `:name` - The registered name and optional node name for the PubSub
      processes, for example: `MyApp.PubSub`, `{MyApp.PubSub, :node@host}`.
      When only a server name is provided, the node name defaults to `node()`.

    * `:pool_size` - Both the size of the local pubsub server pool and subscriber
      shard size. Defaults to the number of schedulers (cores). A single pool is
      often enough for most use-cases, but for high subscriber counts on a single
      topic or greater than 1M clients, a pool size equal to the number of
      schedulers (cores) is a well rounded size.

  """

  def start_link(name, opts) do
    supervisor_name = Module.concat(name, Supervisor)
    Supervisor.start_link(__MODULE__, [name, opts], name: supervisor_name)
  end

  @doc false
  def init([server_name, opts]) do
    scheduler_count = :erlang.system_info(:schedulers)
    pool_size = Keyword.get(opts, :pool_size, scheduler_count)
    node_name = opts[:node_name]
    broker = Keyword.fetch!(opts, :broker)

    dispatch_rules = [
      {:broadcast, __MODULE__, [opts[:fastlane], server_name, pool_size]},
      {:direct_broadcast, __MODULE__, [opts[:fastlane], server_name, pool_size]},
      {:node_name, __MODULE__, [node_name]}
    ]

    table = :phoenix_pubsub_conduit_amqp

    if :ets.info(table) == :undefined do
      :ets.new(table, [:set, :public, :named_table, read_concurrency: true])

      :ets.insert(
        table,
        {:local_state,
         %{
           server_name: server_name,
           namespace: "phx",
           node_ref: :crypto.strong_rand_bytes(24)
         }}
      )

      :ets.insert(table, {:broker, broker})
    end

    children = [
      supervisor(Phoenix.PubSub.LocalSupervisor, [server_name, pool_size, dispatch_rules])
    ]

    supervise(children, strategy: :rest_for_one)
  end

  @doc false
  def node_name(nil), do: node()
  def node_name(configured_name), do: configured_name

  @doc false
  def direct_broadcast(fastlane, server_name, pool_size, node_name, from_pid, topic, msg) do
    do_broadcast(fastlane, server_name, pool_size, node_name, from_pid, topic, msg)
  end

  @doc false
  def broadcast(fastlane, server_name, pool_size, from_pid, topic, msg) do
    do_broadcast(fastlane, server_name, pool_size, nil, from_pid, topic, msg)
  end

  @conduit_amqp_msg_vsn "v1.0"
  defp do_broadcast(fastlane, _server_name, pool_size, node_name, from_pid, topic, msg) do
    import Conduit.Message
    [broker: broker] = :ets.lookup(:phoenix_pubsub_conduit_amqp, :broker)

    conduit_amqp_msg =
      {@conduit_amqp_msg_vsn, node_name, fastlane, pool_size, from_pid, topic, msg}

    message =
      %Conduit.Message{}
      |> put_content_type("application/x-erlang-binary")
      |> put_body(conduit_amqp_msg)

    broker.publish(:phoenix_pubsub_broadcast, message)
  end

  def queue_name(_ \\ nil) do
    :inet.gethostname()
    |> elem(1)
    |> to_string()
    |> String.replace("-", "_")
  end
end
