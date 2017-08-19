defmodule Perhap.Event.Metadata do

  @type t :: %__MODULE__{ entity_id: String.t,
                          user_id: String.t,
                          context: String.t,
                          domain: String.t,
                          ip_addr: String.t,
                          timestamp: Integer
                        }
  defstruct entity_id: "",
            user_id: "",
            context: "",
            domain: "",
            ip_addr: "",
            timestamp: nil
end
