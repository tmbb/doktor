defmodule Doktor.SectionsCache do
  @moduledoc false
  use Agent

  defp agent_for(module_name) do
    {:global, {Doktor.SectionsCache, module_name}}
  end

  @doc """
  Starts a process containing the cache.
  """
  def start_link(module_name) do
    Agent.start_link(fn -> Map.new() end, name: agent_for(module_name))
  end

  @doc """
  Get the contents for a section.
  """
  def get_contents(module_name, fun) do
    Agent.get(agent_for(module_name), &Map.get(&1, fun))
  end

  @doc """
  Puts a list of sections in the cache.
  """
  def put_sections(module_name, sections_list) do
    sections_map = Enum.into(sections_list, %{})
    Agent.update(agent_for(module_name), fn _ -> sections_map end)
  end
end