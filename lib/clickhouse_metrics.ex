defmodule PTA.ClickhouseMetrics do
  use GenServer
  require Logger

  alias PTA.ClickhouseClientWrapper, as: Client

  def start_link(metrics) do
    GenServer.start_link(__MODULE__, metrics, name: __MODULE__)
  end

  def get_metrics do
    GenServer.call(__MODULE__, :get_metrics)
  end

  @impl true
  def init(metrics) do
    Logger.info("Start ClickhouseMetrics")

    state = %{
      metrics: metrics,
      events: %{}
    }

    {:ok, state, {:continue, :init_event_counters}}
  end

  @impl true
  def handle_continue(:init_event_counters, state) do
    events = load_events(state.metrics["system.events"])
    state = %{state | events: events}
    {:noreply, state}
  end

  @impl true
  def handle_call(:get_metrics, _from, state) do
    metrics1 = load_metrics("system.metrics", state.metrics["system.metrics"])

    metrics2 =
      load_metrics("system.asynchronous_metrics", state.metrics["system.asynchronous_metrics"])

    events =
      load_events(state.metrics["system.events"])
      |> Map.merge(
        state.events,
        fn _event, curr_val, initial_val -> curr_val - initial_val end
      )

    reply = Map.merge(metrics1, metrics2) |> Map.merge(events)
    {:reply, reply, state}
  end

  defp load_events(event_names) do
    query = """
    SELECT event, value FROM system.events
    WHERE event IN {event_names}
    FORMAT JSON
    """

    {:ok, events} = Client.query(:pillar_0, query, %{event_names: event_names})

    Enum.reduce(events, %{}, fn %{"event" => name, "value" => value}, acc ->
      Map.put(acc, "e." <> name, value)
    end)
  end

  defp load_metrics(table, metric_names) do
    query = """
    SELECT metric, value FROM #{table}
    WHERE metric IN {metric_names}
    FORMAT JSON
    """

    {:ok, metrics} = Client.query(:pillar_0, query, %{metric_names: metric_names})

    Enum.reduce(metrics, %{}, fn %{"metric" => name, "value" => value}, acc ->
      Map.put(acc, "m." <> name, value)
    end)
  end
end
