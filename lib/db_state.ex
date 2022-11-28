defmodule PTA.DbState do
  use Task
  require Logger

  alias PTA.ClickhouseClientWrapper, as: Client

  def start_link(state) do
    Task.start_link(__MODULE__, :create_initial_db_state, [state])
  end

  def create_initial_db_state(state) do
    Logger.info("Create initial DB state")
    :ok = Client.check_connection()
    Logger.info("Connection to #{state.clickhouse_url} is ok")
    create_table(state)
    fill_table(state)
    PTA.LoadManager.run_agents()
  end

  defp create_table(%{create_table?: true} = state) do
    Logger.info("Create table '#{state.table_name}'")
    query = File.read!(state.create_table_file)
    Client.query(query)
  end

  defp create_table(%{create_table?: false}) do
    Logger.info("Skip creating table")
  end

  defp fill_table(%{fill_table?: true} = state) do
    Logger.info("Fill table '#{state.table_name}' with data")
    {:ok, ""} = Client.query("truncate table #{state.table_name}")

    Enum.each(1..100, fn _ ->
      rows = [rand_row(), rand_row(), rand_row()]
      {:ok, ""} = Client.insert_to_table(state.table_name, rows)
    end)

    Logger.info("300 rows inserted")
  end

  defp fill_table(%{fill_table?: false}) do
    Logger.info("Skip filling table")
  end

  def rand_row() do
    row = %{
      uid: Ecto.UUID.generate(),
      name: rand_str(10),
      created_at: rand_date(),
      updated_at: rand_date(),
      feeded_at: rand_date(),
      number_of_paws: Enum.random(4..40),
      number_of_tails: Enum.random(1..40),
      age: Enum.random(1..100),
      length: Enum.random(50..1000),
      weight: Enum.random(100..1000)
    }

    Enum.reduce(0..59, row, &rand_column/2)
  end

  def rand_char() do
    # 0-9 A-Z a-z
    Enum.concat([48..57, 65..90, 97..122])
    |> Enum.random()
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
