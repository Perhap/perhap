defmodule Perhap.Event.Metadata do

  @type t :: %__MODULE__{ event_id: Perhap.Event.UUIDv1.t,
                          entity_id: String.t,
                          context: String.t,
                          domain: String.t,
                          type: atom(),
                          user_id: String.t,
                          ip_addr: String.t,
                          timestamp: Integer
                        }
  defstruct event_id: "",
            entity_id: "",
            context: "",
            domain: "",
            type: :none,
            user_id: "",
            ip_addr: "",
            timestamp: 0
end
