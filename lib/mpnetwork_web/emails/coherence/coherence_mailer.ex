defmodule MpnetworkWeb.Coherence.Mailer do
  @moduledoc false
  if Coherence.Config.mailer?() do
    use Swoosh.Mailer, otp_app: :coherence
  else
    raise "Mailer for Coherence not configured!"
  end
end
