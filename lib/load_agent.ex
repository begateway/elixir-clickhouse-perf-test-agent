defmodule PTA.LoadAgent do
  use GenServer
  require Logger

  @type query_type() :: :read | :write

  defmodule State do
    @type t() :: %__MODULE__{
            id: pos_integer(),
            type: PTA.LoadAgent.query_type(),
            rate: pos_integer(),
            client: atom(),
            query: String.t(),
            insert_data: map(),
            perf_test_duration: pos_integer(),
            start_time: DateTime.t() | nil,
            report_time: DateTime.t() | nil,
            query_counter: pos_integer()
          }

    defstruct [
      :id,
      :type,
      :rate,
      :client,
      :query,
      :insert_data,
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
      client: args.client,
      query: args.query,
      insert_data: args.insert_data,
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
    case PTA.QueryTask.sync_query(state.client, state.type, state.query, state.insert_data) do
      :ok ->
        :ok

      {:error, error} ->
        Logger.error(
          "LoadAgent id:#{state.id} Invalid query\n#{inspect(state.query)}\n#{inspect(error)}"
        )

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
    PTA.QueryTask.async_query(state.client, state.type, state.query, state.insert_data)

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
      PTA.LoadManager.on_agent_finished(state.id)
      {:stop, :normal, state}
    end
  end

  def handle_info({_ref, :ok}, state) do
    {:noreply, state}
  end

  def handle_info({:DOWN, _task_ref, :process, _task_pid, :normal}, state) do
    {:noreply, state}
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
end
