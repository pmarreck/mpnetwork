defmodule Mix.Tasks.Deps.Rebuild do
  use Mix.Task

  @impl true
  def run(args) do

    case args do
      [dep] ->
        _run(dep)

      _ ->
        Mix.raise("Usage: mix deps.rebuild DEP")
    end
  end

  defp _run(dep) do
    Mix.Task.run("deps.clean", [dep])
    Mix.Task.run("deps.update", [dep])
    Mix.Task.run("deps.compile", [dep])
  end
end