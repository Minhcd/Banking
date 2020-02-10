defmodule Hello.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :account, :string, null: false
      add :password, :string, null: false
      add :money, :int, default: 0
    end
  end
end
