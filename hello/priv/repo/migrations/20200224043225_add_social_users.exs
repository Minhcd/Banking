defmodule Hello.Repo.Migrations.AddSocialUsers do
  use Ecto.Migration

  def change do
    create table(:socialusers) do
      add :account, :string, null: false
      add :email, :string, null: false, unique: true
      add :provider, :string, null: false
      add :money, :int, default: 0
    end

    create(unique_index(:socialusers, [:email], name: :unique_email))
  end
end
