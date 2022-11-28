defmodule LoadManager do
  use GenServer
  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def run_agents() do
    GenServer.cast(__MODULE__, :run_agents)
  end

  @impl true
  def init(args) do
    state = %{
      agent_args: [],
      perf_test_duration: args.perf_test_duration,
      start_agent_pause: args.start_agent_pause,
      read_queries_file: args.read_queries_file,
      write_queries_file: args.write_queries_file
    }

    Logger.info("Start LoadManager")
    {:ok, state}
  end

  @impl true
  def handle_cast(:run_agents, state) do
    Logger.info("Run load agents")

    read_queries =
      get_queries_from_file(state.read_queries_file)
      |> Enum.map(fn {rps, query} -> {:read, rps, query} end)

    write_queries =
      get_queries_from_file(state.write_queries_file)
      |> Enum.map(fn {rps, query} -> {:write, rps, query} end)

    agent_args =
      (read_queries ++ write_queries)
      |> Enum.with_index(fn {type, rps, query}, id ->
        %{
          id: id + 1,
          type: type,
          rate: rps,
          query: query,
          perf_test_duration: state.perf_test_duration
        }
      end)

    state = %{state | agent_args: agent_args}

    send(self(), :run_next_agent)
    {:noreply, state}
  end

  def handle_cast(msg, state) do
    Logger.error("LoadManager.handle_cast unknown msg #{inspect(msg)}")
    {:noreply, state}
  end

  @impl true
  def handle_info(:run_next_agent, %{agent_args: []} = state) do
    {:noreply, state}
  end

  def handle_info(:run_next_agent, %{agent_args: agent_args} = state) do
    [args | rest] = agent_args
    LoadAgentSup.run_agent(args.id, args)

    state = %{state | agent_args: rest}

    Process.send_after(self(), :run_next_agent, state.start_agent_pause)
    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.error("LoadManager.handle_info unknown msg #{inspect(msg)}")
    {:noreply, state}
  end

  defp get_queries_from_file(file) do
    # No validation is here, just count upon proper data in file
    File.read!(file)
    |> String.split(";")
    |> Enum.map(&String.trim/1)
    |> Enum.filter(fn q -> q != "" end)
    |> Enum.map(&parse_query/1)
  end

  defp parse_query(query) do
    ["-- RPS:" <> rps, query] = String.split(query, "\n", parts: 2)
    {rps, _} = String.trim(rps) |> Integer.parse()
    {rps, query}
  end
end
