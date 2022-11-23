defmodule PerfTestAgent do
  use Application

  require Logger

  def start(_start_type, _args) do
    Logger.info("Start PerfTestAgent")
    PerfTestAgent.RootSup.start_link(:no_args)
  end

  defmodule RootSup do
    use Supervisor

    def start_link(:no_args) do
      Supervisor.start_link(__MODULE__, :no_args)
    end

    @impl true
    def init(:no_args) do
      spec = [
      ]
      Supervisor.init(spec, strategy: :rest_for_one)
    end
  end
  
end
