defmodule Mix.Tasks.TestJs do
  use Mix.Task

  @shortdoc "Runs the Javascript portion of the test suite."

  def run(_) do
    0 = Mix.shell().cmd("npm test")
  end
end
