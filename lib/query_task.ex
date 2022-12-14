defmodule PTA.QueryTask do
  use Task
  require Logger

  alias PTA.ClickhouseClientWrapper, as: Client

  def async_query(client, query_type, query, insert_data) do
    Task.async(__MODULE__, :sync_query, [client, query_type, query, insert_data])
  end

  def sync_query(client, query_type, query, insert_data) do
    case make_query(client, query_type, query, insert_data) do
      {{:ok, _}, duration} ->
        PTA.Metrics.query_result(query_type, true)
        PTA.Metrics.query_time(query_type, duration)
        :ok

      {{:error, error}, duration} ->
        PTA.Metrics.query_result(query_type, false)
        PTA.Metrics.query_time(query_type, duration)

        Logger.error("Invalid response from clickhouse\n#{inspect(error)}")
        {:error, error}
    end
  end

  defp make_query(client, :read, query, _) do
    t1 = :erlang.monotonic_time()
    res = Client.query(client, query)
    t2 = :erlang.monotonic_time()
    {res, t2 - t1}
  end

  defp make_query(client, :write, query, insert_data) do
    data = PTA.DbState.rand_row(insert_data)
    t1 = :erlang.monotonic_time()
    res = Client.query(client, query, data)
    t2 = :erlang.monotonic_time()
    {res, t2 - t1}
  end
end
