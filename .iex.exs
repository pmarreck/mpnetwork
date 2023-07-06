IEx.configure(
  colors: [
    enabled: true,
    eval_result: [ :cyan, :bright ],
    eval_error:  [ :light_magenta ],
  ],
  default_prompt: [
    "\r\e[38;5;220m",         # a pale gold
    "%prefix",                # IEx context
    "\e[38;5;112m(%counter)", # forest green expression count
    "\e[38;5;220m>",          # gold ">"
    "\e[0m",                  # and reset to default color
  ] 
  |> IO.chardata_to_string
)
# use the following snippet to always print out the colorful output and not stop and pry:
Application.put_env(:elixir, :dbg_callback, {Macro, :dbg, []})

# Because I hate not being able to exit IEx without killing the process:
# Note that control-\ will do the same thing, but my Rails muscle memory is too strong
defmodule CustomIExFunctions do
  def exit do
    IO.puts("Exiting...")
    System.halt # also :init.stop might work here
  end
end
import CustomIExFunctions
