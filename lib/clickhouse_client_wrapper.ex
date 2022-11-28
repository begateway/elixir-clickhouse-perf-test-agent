defmodule PTA.ClickhouseClientWrapper do
  alias Pillar.Connection
  alias Pillar.QueryBuilder

  def check_connection() do
    connection()
    |> Pillar.query("SELECT 1")
    |> case do
      {:ok, 1} -> :ok
      other -> other
    end
  end

  def insert_to_table(table, rows) do
    connection()
    |> Pillar.insert_to_table(table, rows)
  end

  defp connection() do
    Application.fetch_env!(:perf_test_agent, :clickhouse_url)
    |> Connection.new()
  end

  def query(client, query, params \\ %{})

  def query(:pillar_0, query, params) do
    connection()
    |> Pillar.query(query, params)
  end

  def query(:pillar_1, query, params) do
    connection()
    |> Pillar.query(query, params, %{db_side_batch_insertions: true})
  end

  def query(:hackney_0, query, params) do
    url = connection() |> Connection.url_from_connection()
    headers = []
    payload = QueryBuilder.query(query, params)
    options = [{:pool, :clickhouse}]

    case :hackney.post(url, headers, payload, options) do
      {:ok, 200, _, _} -> {:ok, ""}
      {:ok, status_code, _, _} -> {:error, status_code}
      {:error, error} -> {:error, error}
    end
  end
end
