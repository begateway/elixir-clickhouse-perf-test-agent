defmodule PTA.LoadAgentSup do
  use DynamicSupervisor
  require Logger

  def start_link(:no_args) do
    DynamicSupervisor.start_link(__MODULE__, :no_args, name: __MODULE__)
  end

  def run_agent(agent_id, agent_params) do
    spec = %{
      id: {:load_agent, agent_id},
      start: {PTA.LoadAgent, :start_link, [agent_params]},
      restart: :temporary
    }

    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def init(:no_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
