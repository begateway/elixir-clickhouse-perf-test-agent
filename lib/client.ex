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

  defp fill_table(state) do
    Logger.info("Fill table")
    {:ok, ""} = send_query(state.clickhouse_url, "truncate table cats")

    conn = Pillar.Connection.new(state.clickhouse_url)
    Enum.each(1..100, fn _ ->
      rows = [rand_row(), rand_row(), rand_row()]
      {:ok, ""} = Pillar.insert_to_table(conn, "cats", rows)
    end)
    Logger.info("insert 300 rows")
  end

  defp get_queries(file_name, queries_dir) do
    Path.join(queries_dir, file_name <> ".sql")
    |> File.read!()
  end

  defp send_query(clickhouse_url, query, params \\ %{}) do
    Pillar.Connection.new(clickhouse_url)
    |> Pillar.query(query, params)
  end

  def rand_row() do
    row = %{
      uid: Ecto.UUID.generate,
      name: rand_str(10),
      created_at: rand_date(),
      updated_at: rand_date(),
      feeded_at: rand_date(),
      number_of_paws: Enum.random(4..40),
      number_of_tails: Enum.random(1..40),
      age: Enum.random(1..100),
      length: Enum.random(50..1000),
      weight: Enum.random(100..1000),
    }

    Enum.reduce(0..59, row, &rand_column/2)
  end

  def rand_char() do
    Enum.concat([48..57, 65..90, 97..122]) # 0-9 A-Z a-z
    |> Enum.random
  end

  def rand_str(length) do
    1..length
    |> Enum.map(fn _ -> rand_char() end)
    |> to_string()
  end

  def rand_date() do
    days = Enum.random(1..1000)
    hours = Enum.random(1..24)
    minutes = Enum.random(1..60)
    seconds = Enum.random(1..60)
    DateTime.utc_now() |> DateTime.add(days * -hours * minutes * seconds)
  end

  def rand_column(column_num, row) do
    val = rem(column_num, 10) |> rand_column_val()
    Map.put(row, "column#{column_num}", val)
  end
  
  def rand_column_val(4), do: rand_str(2)
  def rand_column_val(8), do: rand_str(2)
  def rand_column_val(3), do: rand_str(10)
  def rand_column_val(7), do: rand_str(50)
  def rand_column_val(_), do: Enum.random(0..1000)
end
