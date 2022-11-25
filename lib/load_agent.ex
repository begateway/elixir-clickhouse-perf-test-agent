defmodule LoadAgent do
  use GenServer
  require Logger

  alias ClickhouseClientWrapper, as: Client

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl true
  def init({id, type, rate, query}) do
    state = %{
      id: id,
      type: type,
      rate: rate,
      query: query
    }

    qinfo = query_info(query)
    Logger.info("LoadAgent id: #{id}, type: #{type}, query: '#{qinfo}...'")
    {:ok, state, {:continue, :check_query}}
  end

  @impl true
  def handle_continue(:check_query, state) do
    case check_query(state.type, state.query) do
      {:ok, _} ->
        :ok

      error ->
        Logger.error("Invalid query\n#{inspect(state.query)}\n#{inspect(error)}")
        System.stop(1)
    end

    {:noreply, state}
  end

  defp query_info(query) do
    String.slice(query, 0, 30)
    |> String.replace("\n", " ")
  end

  defp check_query(:read, query) do
    Client.query(query)
  end

  defp check_query(:write, query) do
    data = DbState.rand_row()
    Client.query(query, data)
  end
end
