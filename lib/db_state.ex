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
    Client.query(:pillar_0, query)
  end

  defp create_table(%{create_table?: false}) do
    Logger.info("Skip creating table")
  end

  defp fill_table(%{fill_table?: true} = state) do
    Logger.info("Fill table '#{state.table_name}' with data")
    {:ok, ""} = Client.query(:pillar_0, "truncate table #{state.table_name}")
    data = File.read!(state.insert_data_file) |> Jason.decode!()

    Enum.each(1..100, fn _ ->
      rows = [
        rand_row(data),
        rand_row(data),
        rand_row(data),
        rand_row(data),
        rand_row(data)
      ]

      {:ok, ""} = Client.insert_to_table(state.table_name, rows)
    end)

    Logger.info("500 rows are inserted")
  end

  defp fill_table(%{fill_table?: false}) do
    Logger.info("Skip filling table")
  end

  def rand_row(data) do
    Enum.map(data, fn {k, v} -> {k, rand_value(v)} end) |> Map.new()
  end

  def rand_value("$uid"), do: Ecto.UUID.generate()

  def rand_value("$rand_date"), do: rand_date()

  def rand_value("$rand_num:" <> rest) do
    [from, to | _] = String.split(rest, ":")
    {from, _} = Integer.parse(from)
    {to, _} = Integer.parse(to)
    Enum.random(from..to)
  end

  def rand_value("$rand_str:" <> rest) do
    {length, _} = Integer.parse(rest)
    rand_str(length)
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
end
