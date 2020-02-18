defmodule Hello.Repo.Migrations.CreateTransactionHistory do
  use Ecto.Migration

  def change do
    create table(:TransactionHistory) do 
      add :user_id, references("users", column: "id")
      add :datetime, :utc_datetime_usec, null: false
      add :action, :string, null: false
      add :receiver_id, :integer, default: nil
      add :money, :integer, default: 0 
    end
  end
end
