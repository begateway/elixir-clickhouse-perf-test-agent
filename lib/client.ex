defmodule Client do
  use GenServer
  require Logger

  defmodule State do
    @type t() :: %__MODULE__{
      clickhouse_url: String.t(),
      queries_dir: String.t()
    }
    defstruct [:clickhouse_url, :queries_dir]
  end

  def start_link(options) do
    GenServer.start_link(__MODULE__, options)
  end

  def init(options) do
    state = %State{
      clickhouse_url: Map.fetch!(options, :clickhouse_url),
      queries_dir: Map.fetch!(options, :queries_dir)
    }
    Logger.info("Client has started")
    {:ok, state, {:continue, :delayed_init}}
  end

  def handle_continue(:delayed_init, state) do
    check_connection(state.clickhouse_url)
    create_initial_db_state(state)
    {:noreply, state}
  end

  defp check_connection(clickhouse_url) do
    {:ok, 1} = Pillar.Connection.new(clickhouse_url) |> Pillar.query("SELECT 1")
    Logger.info("Connection to #{clickhouse_url} is ok")
  end

  defp create_initial_db_state(state) do
    Logger.info("Create initial DB state")
    create_table(state)
    fill_table(state)
  end

  defp create_table(state) do
    Logger.info("Create table")
    query = get_queries("create_table", state.queries_dir)
    send_query(state.clickhouse_url, query)
  end

  defp fill_table(_state) do
    Logger.info("Fill table")
    # TODO truncate and fill table
  end

  defp get_queries(file_name, queries_dir) do
    Path.join(queries_dir, file_name <> ".sql")
    |> File.read!()
  end

  defp send_query(clickhouse_url, query, params \\ %{}) do
    Pillar.Connection.new(clickhouse_url)
    |> Pillar.query(query, params)
  end

end
