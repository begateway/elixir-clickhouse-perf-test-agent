defmodule LoadAgent do
  use GenServer
  require Logger

  # alias ClickhouseClientWrapper, as: Client

  def start_link(options) do
    GenServer.start_link(__MODULE__, options)
  end

  @impl true
  def init({id, rps, query}) do
    state = %{
      id: id,
      rate: rps,
      query: query
    }

    qinfo = query_info(query)
    Logger.info("LoadAgent id: #{id}, query: '#{qinfo}...'")
    {:ok, state, {:continue, :check_query}}
  end

  @impl true
  def handle_continue(:check_query, state) do
    Logger.info("#{state.id} check query")
    {:noreply, state}
  end

  defp query_info(query) do
    String.slice(query, 0, 30)
    |> String.replace("\n", " ")
  end
end
