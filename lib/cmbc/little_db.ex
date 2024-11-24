defmodule Cmbc.LittleDB do
  @file_path Application.compile_env(:cmbc, __MODULE__)[:file_path]

  def get(key) do
    case read_file() do
      {:ok, content} -> find_value(content, key)
      {:error, reason} -> {:error, "Error reading the little db file: #{reason}"}
    end
  end


  def set(key, value) do
    case read_file() do
      {:ok, content} ->
        case find_value(content, key) do
          {:ok, "NIL"} ->
            new_content = "#{content}\n#{key} -> #{value}"
            File.write(@file_path, new_content)
            {:ok, "NIL" <> " " <> value}
          {:ok, old_value} ->
            new_content = String.replace(content, "#{key} -> #{old_value}", "#{key} -> #{value}")
            File.write(@file_path, new_content)
            {:ok, old_value <> " " <> value}
        end

      {:error, reason} ->
        {:error, "Error reading the little db file: #{reason}"}
    end
  end

  defp read_file do
    File.read(@file_path)
  end

  defp find_value(content, key) do
    content
    |> String.split("\n")
    |> Enum.find(fn line ->
      [lilkey | _tail] = String.split(line, " -> ")
      lilkey == key
    end)
    |> case do
      nil ->
        {:ok, "NIL"}

      line ->
        [_, value] = String.split(line, " -> ")
        {:ok, value}
    end
  end
end
