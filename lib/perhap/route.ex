defmodule Route do
  @type option :: :single
  @type t :: %__MODULE__{context: String.t, domain: String.t, events: list(atom), options: list(option)}
  defstruct [:context, :domain, :model, :events, :options]
end
