defmodule Cmbc.TransactionManagerTest do
  use ExUnit.Case, async: false

  alias Cmbc.TransactionManager, as: TM
  alias CmbcWeb.Errors.{TransactionAlreadyActiveError, TransactionInactiveError, AtomicityError}

  @test_file_path "test/mock_db/cumbuquinha_test.txt"
  @copy_from_path "test/mock_db/cumbuquinha_test_copy.txt"

  setup do
    File.cp!(@copy_from_path, @test_file_path)
    :ok
  end

  test "begin_transaction/1 starts a transaction for a user" do
    assert TM.begin_transaction("user1") == {:ok, "OK"}
    assert TM.has_transaction("user1") == {:ok, %{}}
  end

  test "begin_transaction/1 raises an error if the user already has a transaction" do
    assert TM.begin_transaction("user2") == {:ok, "OK"}

    assert_raise TransactionAlreadyActiveError, fn ->
      TM.begin_transaction("user2")
    end
  end

  test "get_transaction/2 retrieves a value when not in transaction" do
    assert TM.get_transaction("alphinaud", "user3") == {:ok, "\"vamoooooooo porra\""}
    assert TM.get_transaction("estinien", "user3") == {:ok, "AB\"C"}
  end

  test "get_transaction/2 retrieves a value inside transaction and outside of it for one user" do
    assert TM.begin_transaction("user4") == {:ok, "OK"}
    assert TM.set_transaction("haurchefant", "alive", "user4") == {:ok, "NIL alive"}
    assert TM.get_transaction("haurchefant", "user4") == {:ok, "alive"}
    assert TM.get_transaction("estinien", "user4") == {:ok, "AB\"C"}
  end

  test "get_transaction/2 retrieves old value for users not inside transactions" do
    assert TM.begin_transaction("user5") == {:ok, "OK"}
    assert TM.set_transaction("y'shtola", "FALSE", "user5") == {:ok, "TRUE FALSE"}
    assert TM.get_transaction("y'shtola", "userNotTransaction") == {:ok, "TRUE"}
    assert TM.get_transaction("y'shtola", "user5") == {:ok, "FALSE"}
  end

  test "set_transaction/3 creates new key in transaction" do
    assert TM.begin_transaction("user6") == {:ok, "OK"}
    assert TM.set_transaction("lahabrea", "123", "user6") == {:ok, "NIL 123"}
    assert TM.get_transaction("lahabrea", "user6") == {:ok, "123"}
    assert TM.get_transaction("lahabrea", "userNotTransaction") == {:ok, "NIL"}
  end

  test "set_transaction/3 updates existing key in transaction" do
    assert TM.set_transaction("haurchefant", "alive", "user7") == {:ok, "NIL alive"}
    assert TM.begin_transaction("user7") == {:ok, "OK"}
    assert TM.get_transaction("haurchefant", "user7") == {:ok, "alive"}
    assert TM.set_transaction("haurchefant", "dead", "user7") == {:ok, "alive dead"}
    assert TM.get_transaction("haurchefant", "user7") == {:ok, "dead"}
    assert TM.get_transaction("haurchefant", "userNotTransaction") == {:ok, "alive"}
  end

  test "rollback_transaction/1 raises an error if no transaction is active" do
    assert_raise TransactionInactiveError, fn ->
      TM.rollback_transaction("user8")
    end
  end

  test "commit_transaction/1 raises an error if no transaction is active" do
    assert_raise TransactionInactiveError, fn ->
      TM.commit_transaction("user9")
    end
  end

  test "commit_transaction/1 commits the transaction if no conflicts" do
    assert TM.begin_transaction("user10") == {:ok, "OK"}
    assert TM.set_transaction("haurchefant", "alive", "user10") == {:ok, "NIL alive"}
    assert TM.commit_transaction("user10") == {:ok, "COMMIT"}
    assert TM.get_transaction("haurchefant", "user10") == {:ok, "alive"}
  end

  test "commit_transaction/1 raises an atomicity error if there are conflicts" do
    assert TM.begin_transaction("user11") == {:ok, "OK"}
    assert TM.set_transaction("haurchefant", "alive", "user11") == {:ok, "NIL alive"}
    # Simulate a conflict by changing the value in the database directly
    Cmbc.LittleDB.set("haurchefant", "dead")

    assert_raise AtomicityError, fn ->
      TM.commit_transaction("user11")
    end
  end
end
