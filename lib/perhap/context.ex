defmodule Perhap.Context do

  def collate_paths(paths) do
    Enum.reduce(paths, %{}, fn({path, block}, acc) ->
                              Map.put(acc, path, [block | Map.get(acc, path, [])]) end)
    |> Enum.map(fn {path, blocks} -> {path, (blocks |> Enum.reverse)} end)
  end

end
