defmodule Cmbc.LittleDBTest do
  use ExUnit.Case, async: true

  alias Cmbc.LittleDB

  @test_file_path "test/mock_db/cumbuquinha_test.txt"
  @backup_file_path "test/mock_db/cumbuquinha_test_backup.txt"

  setup do
    File.cp!(@test_file_path, @backup_file_path)

    on_exit(fn ->
      File.cp!(@backup_file_path, @test_file_path)
      File.rm(@backup_file_path)
    end)

    :ok
  end

  test "get/1 retrieves the value of a key from cumbuquinha" do
    assert LittleDB.get("lahabrea") == {:ok, "NIL"}
    assert LittleDB.get("alphinaud") == {:ok, "\"vamoooooooo porra\""}
    assert LittleDB.get("estinien") == {:ok, "AB\"C"}
  end

  test "set/2 creates a new key in cumbuquinha" do
    assert LittleDB.set("lahabrea", "123") == {:ok, "NIL 123"}
    assert LittleDB.get("lahabrea") == {:ok, "123"}
  end

  test "set/2 updates an existing key in cumbuquinha" do
    assert LittleDB.set("haurchefant", "alive") == {:ok, "NIL alive"}
    assert LittleDB.get("haurchefant") == {:ok, "alive"}
    assert LittleDB.set("haurchefant", "dead") == {:ok, "alive dead"}
    assert LittleDB.get("haurchefant") == {:ok, "dead"}
  end

  test "set/2 creates a new key in cumbuquinha when the file is empty" do
    File.write!(@test_file_path, "")
    assert LittleDB.set("lahabrea", "123") == {:ok, "NIL 123"}
    assert LittleDB.get("lahabrea") == {:ok, "123"}
  end




end
