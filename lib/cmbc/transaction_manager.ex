defmodule Cmbc.TransactionManager do
  use Agent

  alias CmbcWeb.Errors

  def start_link(_) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def begin_transaction(user) do
    # First, check if this user already has a transaction.
    # If it does, return an error.
    case has_transaction(user) do
      nil ->
        Agent.update(__MODULE__, fn state ->
          Map.put(state, user, %{})
        end)

        {:ok, "BEGIN"}

      _ ->
        raise Errors.TransactionAlreadyActiveError
    end
  end

  def has_transaction(user) do
    case Agent.get(__MODULE__, fn state -> Map.get(state, user) end) do
      nil -> nil
      translist -> {:ok, translist}
    end
  end

  def get_transaction(key, user) do
    # First, check if this user already has a transaction.
    # If it does, first check if the key is in transaction. if not, check the db directly.
    # If no transaction, do nothing.
    case has_transaction(user) do
      nil ->
        Cmbc.LittleDB.get(key)

      {:ok, transaction_list} ->
        case Map.get(transaction_list, key) do
          nil -> Cmbc.LittleDB.get(key)
          [_, new] -> {:ok, new}
        end
    end
  end

  def set_transaction(key, value, user) do
    case has_transaction(user) do
      nil ->
        Cmbc.LittleDB.set(key, value)

      {:ok, _} ->
        {:ok, old_val} = Cmbc.LittleDB.get(key)

        Agent.update(__MODULE__, fn state ->
          Map.update!(state, user, fn translist ->
            Map.put(translist, key, [old_val, value])
          end)
        end)

        {:ok, old_val <> " " <> value}
    end
  end

  def rollback_transaction(user) do
    case has_transaction(user) do
      nil ->
        raise Errors.TransactionInactiveError

      {:ok, _} ->
        Agent.update(__MODULE__, fn state -> Map.delete(state, user) end)
        {:ok, "ROLLBACK"}
    end
  end

  def commit_transaction(user) do
    # the most complicated function:
    # compare the transaction state with the db state.
    # if db state was changed since the transaction started,
    # return an atomicity error with a list of keys that were changed.
    # if db state was not changed, write the transaction state to the db.
    case has_transaction(user) do
      nil ->
        raise Errors.TransactionInactiveError

      {:ok, transaction_list} ->
        # for each transaction in the list, compare the old_val with the current db value
        # if they are different, return an atomicity error
        # if the are equal, continue.
        # if every value is equal, write everything to the db and delete the transaction.

        if Enum.all?(transaction_list, fn {key, [old_val, _new_val]} ->
             Cmbc.LittleDB.get(key) == {:ok, old_val}
           end) do
          # write every transaction to the db.
          Enum.each(transaction_list, fn {key, [_old_val, new_val]} ->
            Cmbc.LittleDB.set(key, new_val)
          end)

          Agent.update(__MODULE__, fn state -> Map.delete(state, user) end)
          {:ok, "COMMIT"}
        else
          changed_keys =
            Enum.filter(transaction_list, fn {key, [old_val, _new_val]} ->
              Cmbc.LittleDB.get(key) != {:ok, old_val}
            end)
            |> Enum.map(fn {key, _} -> key end)

          Agent.update(__MODULE__, fn state -> Map.delete(state, user) end)
          raise Errors.AtomicityError, changed_keys
        end
    end
  end
end
