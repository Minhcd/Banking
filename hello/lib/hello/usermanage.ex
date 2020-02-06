defmodule Hello.Usermanage do
    use Ecto.Schema
    import Ecto.Changeset
    alias Hello.Usermanage
    schema "users" do
      field :account, :string
      field :password, :string
      field :money, :integer
    end
    @doc false
    def changeset(%Usermanage{} = user, attrs) do
      user
      |> cast(attrs,[:account, :password, :money])
      |> validate_required([:money])
    end

  end

