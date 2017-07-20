defmodule Perhap.Paths do

  defmacro match(path, do: block) do
    quote bind_quoted: [path: path,
                        block: Macro.escape(block, unquote: true)] do
      @paths {path, block}
    end
  end

  def collate_paths(paths) do
    Enum.reduce(paths, %{}, fn({path, block}, acc) ->
                              Map.put(acc, path, [block | Map.get(acc, path, [])]) end)
    |> Enum.map(fn {path, blocks} -> {path, (blocks |> Enum.reverse)} end)
  end

end
