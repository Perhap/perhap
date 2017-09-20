defmodule Perhap.Event.Metadata do
  @type t :: %__MODULE__{ event_id: Perhap.Event.UUIDv1.t,
                          entity_id: Perhap.Event.UUIDv4.t,
                          scheme: String.t,
                          host: String.t,
                          port: integer(),
                          path: String.t,
                          context: atom(),
                          type: atom(),
                          user_id: String.t,
                          ip_addr: String.t,
                          timestamp: integer() }
  defstruct event_id: nil,
            entity_id: nil,
            scheme: nil,
            host: nil,
            port: nil,
            path: nil,
            context: nil,
            type: nil,
            user_id: "",
            ip_addr: nil,
            timestamp: nil
end

defmodule Perhap.Event.UUIDv1 do
  @type t :: String.t
  @type time_ordered :: String.t
end

defmodule Perhap.Event.UUIDv4 do
  @type t :: String.t
end

defmodule Perhap.Event do

  @type t :: %__MODULE__{ event_id: Perhap.Event.UUIDv1.t,
                          data: map(),
                          metadata: Perhap.Event.Metadata.t }
  defstruct event_id: "",
            time_order: "",
            data: %{},
            metadata: %Perhap.Event.Metadata{}

  # Not used @uuid_v1_regex    "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"
  @time_order_regex "[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{12}"

  @spec validate(t) :: :ok | { :invalid, String.t }
  def validate(event) do
    try do
      %Perhap.Event{
        :event_id => event_id,
        :data => (%{} = _data),
        :metadata => (%Perhap.Event.Metadata{} = metadata)
      } = event
      if !is_uuid_v1?(event_id), do: raise("Invalid event_id")
      if !is_uuid_v4?(metadata.entity_id), do: raise("Invalid entity_id")
      if !is_atom(metadata.context), do: raise("Invalid context")
      :ok
    rescue
      MatchError -> {:invalid, "Invalid event struct"}
      e in RuntimeError -> {:invalid, e.message}
    end
  end

  def save_event!(event) do
    eventstore = Application.get_env(:perhap, :eventstore)
    case apply(eventstore, :put_event, [event]) do
      :ok -> {:ok, event}
      error -> error
    end
  end

  def save_event(event) do
    case validate(event) do
      :ok ->
        eventstore = Application.get_env(:perhap, :eventstore)
        case apply(eventstore, :put_event, [event]) do
          :ok -> {:ok, event}
          error -> error
        end
      error -> error
    end
  end

  def retrieve_event(event_id) do
    eventstore = Application.get_env(:perhap, :eventstore)
    apply(eventstore, :get_event, [event_id])
  end

  def retrieve_events(context, opts \\ []) do
    eventstore = Application.get_env(:perhap, :eventstore)
    apply(eventstore, :get_events, [context, opts])
  end

  # Timestamps and unique integers
  @spec timestamp() :: integer
  def timestamp(), do: System.system_time(:microseconds)
  
  @spec unique_integer() :: integer
  def unique_integer(), do: System.unique_integer([:monotonic])

  # UUID v1
  @spec get_uuid_v1() :: String.t
  def get_uuid_v1() do
    { uuid, _state } = :uuid.get_v1(:uuid.new(self(), :erlang))
    :uuid.uuid_to_string(uuid) |> to_string
  end

  @spec is_uuid_v1?(charlist() | binary()) :: true | false
  def is_uuid_v1?(nil), do: false
  def is_uuid_v1?(input) when is_list(input), do: is_uuid_v1?(to_string(input))
  def is_uuid_v1?(input) when is_binary(input) do
    try do
      :uuid.is_v1(:uuid.string_to_uuid(input))
    catch
      :exit, _ -> false
    end
  end

  @spec uuid_v1_to_time_order(charlist() | binary()) :: String.t
  def uuid_v1_to_time_order(uuid_v1) when is_list(uuid_v1) do
    uuid_v1_to_time_order(to_string(uuid_v1))
  end
  def uuid_v1_to_time_order(uuid_v1) when is_binary(uuid_v1) do
    [time_low, time_mid, time_high, node_hi, node_low] = String.split(uuid_v1, "-")
    time_high <> "-" <> time_mid <> "-" <> time_low <> "-" <> node_hi <> "-" <> node_low
  end

  @spec time_order_to_uuid_v1(charlist() | binary()) :: String.t
  def time_order_to_uuid_v1(time_order_uuid_v1) when is_list(time_order_uuid_v1) do
    time_order_to_uuid_v1(to_string(time_order_uuid_v1))
  end
  def time_order_to_uuid_v1(time_order_uuid_v1) when is_binary(time_order_uuid_v1) do
    [time_high, time_mid, time_low, node_hi, node_low] = String.split(time_order_uuid_v1, "-")
    time_low <> "-" <> time_mid <> "-" <> time_high <> "-" <> node_hi <> "-" <> node_low
  end

  @spec extract_uuid_v1_time(charlist() | binary()) :: integer()
  def extract_uuid_v1_time(input) when is_binary(input), do: extract_uuid_v1_time(to_charlist(input))
  def extract_uuid_v1_time(input) when is_list(input) do
    uuid = case is_time_order?(input) do
      true -> input |> time_order_to_uuid_v1
      _ -> input
    end
    uuid |> :uuid.string_to_uuid |> :uuid.get_v1_time
  end

  @spec is_time_order?(charlist() | binary()) :: true | false
  def is_time_order?(input) when is_list(input), do: is_time_order?(to_string(input))
  def is_time_order?(input) when is_binary(input) do
    Regex.match?(~r/#{@time_order_regex}/, input)
  end

  # UUID v4
  @spec get_uuid_v4() :: String.t
  def get_uuid_v4() do
    :uuid.get_v4() |> :uuid.uuid_to_string |> to_string
  end

  @spec is_uuid_v4?(charlist()|binary()) :: true|false
  def is_uuid_v4?(nil), do: false
  def is_uuid_v4?(input) when is_list(input), do: is_uuid_v4?(to_string(input))
  def is_uuid_v4?(input) when is_binary(input) do
    try do
      :uuid.is_v4(:uuid.string_to_uuid(input))
    catch
      :exit, _ -> false
    end
  end

end
