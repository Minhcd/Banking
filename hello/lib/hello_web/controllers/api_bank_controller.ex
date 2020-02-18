defmodule HelloWeb.ApiBankController do
    use HelloWeb,:controller
    alias HelloWeb.Router.Helpers
    alias Hello.{Repo,Usermanage}
    alias Plug.Crypto.MessageVerifier
    import Ecto.Query
    @secret   "fQ6h8olO5R+xitN6as9wTZFAk41jUeuL3AC79kw1mhk="
    def show_all(conn, _params) do
        users = Repo.all(Usermanage)
                |> Enum.map(fn struct -> struct_to_map(struct)  end)
        json conn, users
    end

    def create(conn, %{"account" => account,"password" => password}) do
        Usermanage.insert_user(account,password)
        conn |> send_resp(200,"Signup successfully")
    end

    def deposit(conn, %{"id"=> id,"deposit"=> deposit}) do
        money = Usermanage.show_money(id)
        money = money + elem(Integer.parse(deposit),0)
        Usermanage.update_money(id,money)
        conn |> send_resp(200,"Deposit successfully")
    end

    def withdraw(conn, %{"id"=> id,"withdraw"=> withdraw}) do
        money = Usermanage.show_money(id)
        money = money - elem(Integer.parse(withdraw),0)
        Usermanage.update_money(id,money)
        conn |> send_resp(200,"Withdraw successfully")
    end

    def transfer(conn,%{"receiverid"=>receiverid,"receivername"=>receivername,"money"=>money,"id"=>id}) do
        money = elem(Integer.parse(money),0)
        if elem(Integer.parse(receiverid),0) == Usermanage.show_id(receivername) do
            target_money = Usermanage.show_money(receiverid)
            source_money = Usermanage.show_money(id)
            target_money = target_money + money
            source_money = source_money - money
            Usermanage.update_money(receiverid,target_money)
            Usermanage.update_money(id,source_money)
            conn |> send_resp(200,"Transfer to #{receivername} successfully")                     
        end
        conn 
    end
    # SIGNIN
    def signin(conn,%{"account"=>account,"password"=>password}) do
        id = Usermanage.check_user(account,password)
        if id != nil do
            token = MessageVerifier.sign(account,@secret)
            user = %{id: id,accesstoken: token}
            json conn,user
        else
            conn |> send_resp(404,"Not found")
        end
    end

    defp struct_to_map(struct) do
        struct
        |> Map.from_struct()
        |> Map.drop([:__meta__])
    end
end