defmodule LoadAgentSup do
  use Supervisor
  require Logger

  def start_link(options) do
    Supervisor.start_link(__MODULE__, options)
  end

  def init(options) do
    queries = Map.fetch!(options, :queries_dir) |> get_queries()
    Logger.info("queries #{inspect(queries)}")

    # TODO run LoadAgent for each query
    spec = []
    Supervisor.init(spec, strategy: :one_for_one)
  end

  def get_queries(queries_dir) do
    read_queries = Path.join(queries_dir, "read.sql") |> get_queries_from_file()
    write_queries = Path.join(queries_dir, "write.sql") |> get_queries_from_file()
    read_queries ++ write_queries
  end

  def get_queries_from_file(file) do
    # No validation is here, just count upon proper data in file
    File.read!(file)
    |> String.split(";")
    |> Enum.map(&String.trim/1)
    |> Enum.filter(fn q -> q != "" end)
    |> Enum.map(&parse_query/1)
  end

  def parse_query(query) do
    ["-- RPS:" <> rps, query] = String.split(query, "\n", parts: 2)
    {rps, _} = String.trim(rps) |> Integer.parse()
    {rps, query}
  end
end
