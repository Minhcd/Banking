defmodule Hello.Repo.Migrations.AlterTrasactionhistory do
  use Ecto.Migration

  def change do
    alter table(:TransactionHistory) do
      add :socialuser_id, references("socialusers", column: "id")
    end
  end
end
