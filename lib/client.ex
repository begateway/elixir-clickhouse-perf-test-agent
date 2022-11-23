defmodule Client do

  require Logger

  def check_connection do
    url = Application.fetch_env!(:perf_test_agent, :clickhouse_url)
    {:ok, 1} = Pillar.Connection.new(url) |> Pillar.query("SELECT 1")
    Logger.info("Connection to #{url} is ok")
  end

end
