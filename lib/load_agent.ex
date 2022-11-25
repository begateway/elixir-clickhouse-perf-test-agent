defmodule LoadAgent do
  use GenServer
  require Logger

  alias ClickhouseClientWrapper, as: Client

  defmodule State do
    @type t() :: %__MODULE__{
            id: pos_integer(),
            type: :read | :write,
            rate: pos_integer(),
            query: String.t(),
            start_time: DateTime.t() | nil
          }

    defstruct [:id, :type, :rate, :query, :start_time]
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
      start_time: nil
    }

    qinfo = query_info(state.query)
    Logger.info("LoadAgent id: #{state.id}, type: #{state.type}, query: '#{qinfo}...'")
    {:ok, state, {:continue, :check_query}}
  end

  @impl true
  def handle_continue(:check_query, state) do
    case make_query(state.type, state.query) do
      {:ok, _} ->
        :ok

      error ->
        Logger.error("Invalid query\n#{inspect(state.query)}\n#{inspect(error)}")
        System.stop(1)
    end

    state = %{state | start_time: DateTime.utc_now()}

    timeout = query_timeout(state.rate)
    Process.send_after(self(), :next_query, timeout)
    {:noreply, state}
  end

  @impl true
  def handle_info(:next_query, state) do
    # Logger.info("LoadAgent id: #{state.id} next query")

    case make_query(state.type, state.query) do
      {:ok, _} ->
        # TODO update ok-counter
        :ok

      other ->
        Logger.error(
          "LoadAgent id: #{state.id} " <>
            "got invalid response from clickhouse\n#{inspect(other)}"
        )

        # TODO update error-counter
    end

    now = DateTime.utc_now()

    if DateTime.diff(now, state.start_time) < 60 do
      timeout = query_timeout(state.rate)
      Process.send_after(self(), :next_query, timeout)
      {:noreply, state}
    else
      Logger.info("LoadAgent id: #{state.id} has finished")
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
    Client.query(query)
  end

  defp make_query(:write, query) do
    data = DbState.rand_row()
    Client.query(query, data)
  end
end
