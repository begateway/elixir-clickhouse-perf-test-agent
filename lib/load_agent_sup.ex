defmodule LoadAgentSup do
  use DynamicSupervisor
  require Logger

  def start_link(:no_args) do
    DynamicSupervisor.start_link(__MODULE__, :no_args, name: __MODULE__)
  end

  def run_agents(queries_dir) do
    get_queries(queries_dir)
    |> Enum.with_index(fn {type, rps, query}, id ->
      %{
        id: {:load_agent, id + 1},
        start: {LoadAgent, :start_link, [{id + 1, type, rps, query}]},
        restart: :temporary
      }
    end)
    |> Enum.each(fn spec -> DynamicSupervisor.start_child(__MODULE__, spec) end)
  end

  def init(:no_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def get_queries(queries_dir) do
    read_queries =
      Path.join(queries_dir, "read.sql")
      |> get_queries_from_file()
      |> Enum.map(fn {rps, query} -> {:read, rps, query} end)

    write_queries =
      Path.join(queries_dir, "write.sql")
      |> get_queries_from_file()
      |> Enum.map(fn {rps, query} -> {:write, rps, query} end)

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
