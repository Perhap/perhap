defmodule Perhap.EventHandler do
  use Perhap.Handler

  def handle(:get_event, conn, state) do
    case retrieve_event(state[:event_id]) do
      {:ok, event} ->
        Perhap.Response.send(conn, 200, event)
      {:error, _reason} ->
        raise(RuntimeError, message: :not_found)
    end
  end
  def handle(:get_events, conn, state) do
    args = case Keyword.has_key?(state, :entity_id) do
      true -> [context: state[:context], entity_id: state[:entity_id]]
      _ -> [context: state[:context]]
    end
    case retrieve_events(args) do
      {:ok, events} ->
        Perhap.Response.send(conn, 200, %{"events" => events})
      {:error, _reason} ->
        raise(RuntimeError, message: :not_found)
    end
  end
  def handle(:post_event, conn, _state) do
    conn |> read_event |> envelope_event |> validate_event |> save_event # |> dispatch_event
    #Perhap.Dispatcher.dispatch({state[:model], :something}, :event, :opts)
    Perhap.Response.send(conn, 204)
  end
  def handle(:get_model, _conn, _state) do
  end

  @spec read_event(:cowboy_req.req())::
    {:ok, :cowboy_req.req(), String.t} | {:error, :cowboy_req.req(), atom()}
  def read_event(conn) do
    case read_body(conn) do
      {:ok, conn2, body} -> {:ok, conn2, body}
      {:timeout, _conn2, _body} -> raise(RuntimeError, message: :request_timeout)
    end
  end

  def envelope_event({:ok, req, body}) do
    [ "" | [ context | [ event_type | _ ] ] ] = :cowboy_req.path(req) |> String.split("/")
    %Perhap.Event{ event_id: req.bindings.event_id,
                   metadata: %Perhap.Event.Metadata{ event_id: :cowboy_req.binding(:event_id, req),
                                                     entity_id: :cowboy_req.binding(:entity_id, req),
                                                     scheme: :cowboy_req.scheme(req),
                                                     host: :cowboy_req.host(req),
                                                     port: :cowboy_req.port(req),
                                                     path: :cowboy_req.path(req),
                                                     context: context |> String.to_existing_atom,
                                                     type: event_type,
                                                     user_id: nil,
                                                     ip_addr: peer_to_ip(:cowboy_req.peer(req)),
                                                     timestamp: Perhap.Event.timestamp() },
                    data: Poison.decode!(body) }
  end

  def validate_event(event) do
    case Perhap.Event.validate(event) do
      :ok -> event
      {:invalid, _reason} -> raise(RuntimeError, message: :validation)
    end
  end

  def save_event(event) do
    case Perhap.Event.save_event!(event) do
      {:ok, event} -> event
      {:error, _reason} -> raise(RuntimeError, message: :service_unavailable)
    end
  end

  def retrieve_event(event_id) do
    Perhap.Event.retrieve_event(event_id)
  end

  def retrieve_events([ context: context, entity_id: entity_id ]) do
    Perhap.Event.retrieve_events(context, entity_id)
  end
  def retrieve_events([ context: context ]) do
    Perhap.Event.retrieve_events(context)
  end

  def save_model({:ok, _model}) do
    # persist to model store
  end
  def save_model({:error, _}) do
  end

  defp peer_to_ip({ip, _port}), do: :inet.ntoa(ip) |> to_string

  defp read_body(conn), do: read_body(conn, "")
	defp read_body(conn, acc) do
		read_body_opts = %{ length: @read_length, period: @timeout }
		try do
			case :cowboy_req.read_body(conn, read_body_opts) do
				{:ok, data, conn2} -> {:ok, conn2, acc <> data};
				{:more, data, conn2} -> read_body(conn2, acc <> data)
			end
		catch
			:exit, _ -> {:timeout, conn, acc}
		end
	end

end
