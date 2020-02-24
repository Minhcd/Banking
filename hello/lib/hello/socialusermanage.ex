defmodule Hello.Socialusermanage do
    use Ecto.Schema
    import Ecto.Changeset
    import Ecto.Query
    alias Hello.{Socialusermanage,Repo}

    schema "socialusers" do
        field :account, :string
        field :email, :string
        field :provider, :string
        field :money, :integer
    end
    @doc false
    def changeset(%Socialusermanage{} = socialuser, attrs) do
        socialuser
        |> cast(attrs,[:account, :email, :provider, :money])
        |> validate_required([:account, :email, :provider])
    end

    def insert_user(account, email, provider) do
        params = %{account: account, email: email, provider: provider}
        changeset = changeset(%Socialusermanage{}, params)
        Repo.insert(changeset)
    end

    def show_money(id) do
        Socialusermanage
        |> where([u], u.id == ^id)
        |> select([u], u.money)
        |> Repo.one()
    end

    def update_money(id,money) do
        params = %{money: money}
        changeset = changeset(%Socialusermanage{id: elem(Integer.parse(id),0)},params)
        Repo.update(changeset)
    end
end