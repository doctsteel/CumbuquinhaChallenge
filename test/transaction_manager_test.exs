defmodule Cmbc.TransactionManagerTest do
  use ExUnit.Case, async: false

  alias Cmbc.TransactionManager, as: TM

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

  test "begin_transaction/1 starts a transaction for a user" do
    assert TM.begin_transaction("user1") == :ok
    assert TM.has_transaction("user1") == {:ok, %{}}
  end

  test "begin_transaction/1 returns an error if the user already has a transaction" do
    assert TM.begin_transaction("user2") == :ok
    assert TM.begin_transaction("user2") == {:error, "User already has a transaction happening"}
  end

  test "get_transaction/2 retrieves a value when not in transaction" do
    assert TM.get_transaction("alphinaud", "user3") == {:ok, "\"vamoooooooo porra\""}
    assert TM.get_transaction("estinien", "user3") == {:ok, "AB\"C"}
  end

  test "get_transaction/2 retrieves a value inside transaction and outside of it for one user" do
    assert TM.begin_transaction("user4") == :ok
    assert TM.set_transaction("haurchefant", "alive", "user4") == {:ok, "NIL alive"}
    assert TM.get_transaction("haurchefant", "user4") == {:ok, "alive"}
    assert TM.get_transaction("estinien", "user4") == {:ok, "AB\"C"}
  end

  test "get_transaction/2 retrieves old value for users not inside transactions" do
    assert TM.begin_transaction("user5") == :ok
    assert TM.set_transaction("y'shtola", "FALSE", "user5") == {:ok, "TRUE FALSE"}
    assert TM.get_transaction("y'shtola", "user4") == {:ok, "TRUE"}
    assert TM.get_transaction("y'shtola", "user5") == {:ok, "FALSE"}
  end

  test "set_transaction/3 creates new key in transaction" do
    assert TM.begin_transaction("user6") == :ok
    assert TM.set_transaction("lahabrea", "123", "user6") == {:ok, "NIL 123"}
    assert TM.get_transaction("lahabrea", "user6") == {:ok, "123"}
    assert TM.get_transaction("lahabrea", "user4") == {:ok, "NIL"}
  end

  test "set_transaction/3 updates existing key in transaction" do
    assert TM.set_transaction("haurchefant", "alive", "user7") == {:ok, "NIL alive"}
    assert TM.begin_transaction("user7") == :ok
    assert TM.get_transaction("haurchefant", "user7") == {:ok, "alive"}
    assert TM.set_transaction("haurchefant", "dead", "user7") == {:ok, "alive dead"}
    assert TM.get_transaction("haurchefant", "user7") == {:ok, "dead"}
    assert TM.get_transaction("haurchefant", "user4") == {:ok, "alive"}
  end

  test "rollback_transaction/1 returns an error if the user does not have a transaction" do
    assert TM.rollback_transaction("user8") == {:error, "User does not have a transaction"}
  end

  test "rollback_transaction/1 rolls back a transaction" do
    assert TM.begin_transaction("user9") == :ok
    assert TM.set_transaction("haurchefant", "alive", "user9") == {:ok, "NIL alive"}
    assert TM.rollback_transaction("user9") == {:ok, "ROLLBACK"}
    assert TM.get_transaction("haurchefant", "user9") == {:ok, "NIL"}
  end

  test "commit_transaction/1 commits a transaction" do
    assert TM.begin_transaction("user10") == :ok
    assert TM.set_transaction("haurchefant", "alive", "user10") == {:ok, "NIL alive"}
    assert TM.commit_transaction("user10") == {:ok, "COMMIT"}
    assert TM.get_transaction("haurchefant", "user10") == {:ok, "alive"}
  end

  test "commit_transaction/1 returns an error if the user does not have a transaction" do
    assert TM.commit_transaction("user11") == {:error, "User does not have a transaction"}
  end

  test "commit_transaction/1 fails if the values from transaction are not the same from when they were read" do
    assert TM.begin_transaction("user12") == :ok
    assert TM.set_transaction("tataru", "moneyyyyyy", "user12") == {:ok, "cash moneyyyyyy"}
    assert TM.get_transaction("tataru", "user12") == {:ok, "moneyyyyyy"}
    assert TM.set_transaction("tataru", "out of cash", "user4") == {:ok, "cash out of cash"}
    assert TM.get_transaction("tataru", "user4") == {:ok, "out of cash"}
    assert TM.commit_transaction("user12") == {:error, "Atomicity error in field(s): tataru"}
  end

end
