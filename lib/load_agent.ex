defmodule PTA.LoadAgent do
  use GenServer
  require Logger

  alias PTA.ClickhouseClientWrapper, as: Client

  @type query_type() :: :read | :write

  defmodule State do
    @type t() :: %__MODULE__{
            id: pos_integer(),
            type: PTA.LoadAgent.query_type(),
            rate: pos_integer(),
            query: String.t(),
            perf_test_duration: pos_integer(),
            start_time: DateTime.t() | nil,
            report_time: DateTime.t() | nil,
            query_counter: pos_integer()
          }

    defstruct [
      :id,
      :type,
      :rate,
      :query,
      :perf_test_duration,
      :start_time,
      :report_time,
      :query_counter
    ]
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl true
  def init(args) do
    state = %State{
      id: args.id,
      type: args.type,
      rate: args.rate,
      query: args.query,
      perf_test_duration: args.perf_test_duration,
      start_time: nil,
      report_time: nil,
      query_counter: 0
    }

    qinfo = query_info(state.query)
    Logger.info("LoadAgent id:#{state.id}, type:#{state.type}, query:'#{qinfo}...'")
    {:ok, state, {:continue, :check_query}}
  end

  @impl true
  def handle_continue(:check_query, state) do
    case make_query(state.type, state.query) do
      {{:ok, _}, _duration} ->
        :ok

      {{:error, error}, _duration} ->
        Logger.error("Invalid query\n#{inspect(state.query)}\n#{inspect(error)}")
        System.stop(1)
    end

    now = DateTime.utc_now()
    state = %{state | start_time: now, report_time: now}

    timeout = query_timeout(state.rate)
    Process.send_after(self(), :next_query, timeout)
    {:noreply, state}
  end

  @impl true
  def handle_info(:next_query, state) do
    case make_query(state.type, state.query) do
      {{:ok, _}, duration} ->
        PTA.Metrics.query_result(state.type, true)
        PTA.Metrics.query_time(state.type, duration)
        :ok

      {{:error, error}, duration} ->
        PTA.Metrics.query_result(state.type, false)
        PTA.Metrics.query_time(state.type, duration)

        Logger.error(
          "LoadAgent id:#{state.id} " <>
            "got invalid response from clickhouse\n#{inspect(error)}"
        )
    end

    state = %{state | query_counter: state.query_counter + 1}

    now = DateTime.utc_now()

    state =
      if DateTime.diff(now, state.report_time, :second) > 5 do
        Logger.info("LoadAgent id:#{state.id} has made #{state.query_counter} queries")
        %{state | report_time: now}
      else
        state
      end

    if DateTime.diff(now, state.start_time, :millisecond) < state.perf_test_duration do
      timeout = query_timeout(state.rate)
      Process.send_after(self(), :next_query, timeout)
      {:noreply, state}
    else
      Logger.info("LoadAgent id:#{state.id} has finished")
      {:stop, :normal, state}
    end
  end

  def handle_info(msg, state) do
    Logger.error("LoadAgent.handle_info unknown msg #{inspect(msg)}")
    {:noreply, state}
  end

  defp query_info(query) do
    String.slice(query, 0, 30)
    |> String.replace("\n", " ")
  end

  defp query_timeout(requests_per_second) do
    one_sec = 1_000
    div(one_sec, requests_per_second)
  end

  defp make_query(:read, query) do
    t1 = :erlang.monotonic_time()
    res = Client.query(query)
    t2 = :erlang.monotonic_time()
    {res, t2 - t1}
  end

  defp make_query(:write, query) do
    data = PTA.DbState.rand_row()
    t1 = :erlang.monotonic_time()
    res = Client.query(query, data)
    t2 = :erlang.monotonic_time()
    {res, t2 - t1}
  end
end
