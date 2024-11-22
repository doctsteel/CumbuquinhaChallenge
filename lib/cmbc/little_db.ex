defmodule Cmbc.LittleDB do
  @file_path "priv/dbzinho.txt"
  @types ["string", "boolean", "integer"]
  def get(key) do
    case read_file() do
      {:ok, content} -> find_value(content, key)
      {:error, reason} -> {:error, "Error reading the little db file: #{reason}"}
    end
  end

  def set(key, value) do
    case read_file() do
      {:ok, content} ->
        # get old content, update it and write it back
       case find_value(content, key) do
        # if the key does not exist, create it
        {:ok, "NIL"} ->
            new_content = "#{content}\n#{key} -> #{value}"
            File.write(@file_path, new_content)
            {:ok, "NIL", value}
        # if the key already exists, update it
          {:ok, old_value} ->
            new_content = String.replace(content, "#{key} -> #{old_value}", "#{key} -> #{value}")
            File.write(@file_path, new_content)
            {:ok, old_value, value}
       end
      {:error, reason} -> {:error, "Error reading the little db file: #{reason}"}
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
      nil -> {:ok, "NIL"}
      line ->
        [_, value] = String.split(line, " -> ")
        {:ok, value}
    end


  end

  defp parse_value_from_string(input, key) do
    # removes the key, the type and the space from the string
    # and returns the value.
    # example: "key string value" -> "value"
  end

  defp type_checker(value) do
    # formats value accordingly:
    # they can be strings, booleans or integers.
    # example: ABC is a string.
    # "ABC" is also the same string.
    # "123" is a string.
    # 123 is an integer.
    # "TRUE" is a string.
    # TRUE is boolean
    # AB C are two separate strings.
    # "AB C" is a string.
    # "AB"C" is invalid due to the peeled quote.
    # "AB\"C" is a string equivalent to AB"C.
    # "AB\\C" is a string equivalent to AB\C.



  end
end
