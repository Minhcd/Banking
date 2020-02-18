defmodule Hello.HistoryTransaction do
    use Ecto.Schema
    import Ecto.Changeset
    import Ecto.Query
    alias Hello.{HistoryTransaction,Repo}

    schema "TransactionHistory" do
        field :user_id, :integer
        field :datetime, :utc_datetime_usec
        field :action, :string
        field :receiver_id, :integer
        field :money, :integer
    end

    def changeset(%HistoryTransaction{} = user, attrs) do
        user
        |> cast(attrs,[:user_id, :datetime, :action, :receiver_id, :money])
        |> validate_required([:user_id, :datetime, :action, :money])
    end

    def transfer_changeset(%HistoryTransaction{} = user, attrs) do
        user
        |> cast(attrs,[:user_id, :datetime, :action, :receiver_id, :money])
        |> validate_required([:user_id, :datetime, :action, :receiver_id, :money])
    end

    def create_datetime(params) do
        changeset = changeset(%HistoryTransaction{},params)
        Repo.insert(changeset)
    end

    def create_transfertime(params) do
        changeset = transfer_changeset(%HistoryTransaction{},params)
        Repo.insert(changeset)
    end

    def show_all_history(id) do 
        Repo.get(HistoryTransaction, id)
    end

end