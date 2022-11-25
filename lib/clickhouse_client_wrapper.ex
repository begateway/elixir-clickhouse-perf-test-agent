defmodule ClickhouseClientWrapper do
  def check_connection() do
    connection()
    |> Pillar.query("SELECT 1")
    |> case do
      {:ok, 1} -> :ok
      other -> other
    end
  end

  def send_query(query, params \\ %{}) do
    connection()
    |> Pillar.query(query, params)
  end

  def insert_to_table(table, rows) do
    connection()
    |> Pillar.insert_to_table(table, rows)
  end

  defp connection() do
    Application.fetch_env!(:perf_test_agent, :clickhouse_url)
    |> Pillar.Connection.new()
  end
end
