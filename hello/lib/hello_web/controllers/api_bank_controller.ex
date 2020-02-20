defmodule HelloWeb.ApiBankController do
    use HelloWeb,:controller
    alias HelloWeb.Router.Helpers
    alias Hello.{Repo,Usermanage,Guardian}
    alias Plug.Crypto.MessageVerifier
    import Ecto.Query

    def show_all(conn, _params) do
        users = Repo.all(Usermanage)
                |> Enum.map(fn struct -> struct_to_map(struct)  end)
        json conn, users
    end

    def create(conn, %{"account" => account,"password" => password}) do
        Usermanage.insert_user(account,password)
        conn |> send_resp(200,"Signup successfully")
    end

    def deposit(conn, %{"id"=> id,"deposit"=> deposit,"accesstoken"=>token}) do
        case verify_token(token) do
        {:ok, token_sub_id} ->
            if (token_sub_id == id ) do
            money = Usermanage.show_money(id)
            money = money + elem(Integer.parse(deposit),0)
            Usermanage.update_money(id,money)
            conn |> send_resp(200,"Deposit successfully")
            else
            conn |> send_resp(401,"Unauthorized")
            end
        {:error, reason} -> 
            conn |> send_resp(401, reason)
        _ ->
            conn
        end
    end

    def withdraw(conn, %{"id"=> id,"withdraw"=> withdraw,"accesstoken"=>token}) do
        case verify_token(token) do
            {:ok, token_sub_id} ->
                if (token_sub_id == id ) do
                    money = Usermanage.show_money(id)
                    money = money - elem(Integer.parse(withdraw),0)
                    Usermanage.update_money(id,money)
                    conn |> send_resp(200,"Withdraw successfully")
                else
                conn |> send_resp(401,"Unauthorized")
                end
            {:error, reason} -> 
                conn |> send_resp(401, reason)
            _ ->
                conn
            end
        # -------------------------------------------
        
    end

    def transfer(conn,%{"receiverid"=>receiverid,"receivername"=>receivername,"money"=>money,"id"=>id,"accesstoken"=>token}) do
        case verify_token(token) do
            {:ok, token_sub_id} ->
                if (token_sub_id == id ) do
                    money = elem(Integer.parse(money),0)
                    if elem(Integer.parse(receiverid),0) == Usermanage.show_id(receivername) do
                        target_money = Usermanage.show_money(receiverid)
                        source_money = Usermanage.show_money(id)
                        target_money = target_money + money
                        source_money = source_money - money
                        Usermanage.update_money(receiverid,target_money)
                        Usermanage.update_money(id,source_money)
                        conn |> send_resp(200,"Transfer to #{receivername} successfully")                     
                    else
                        conn |> send_resp(406,"")
                    end
                    
                else
                conn |> send_resp(403,"")
                end
            {:error, reason} -> 
                conn |> send_resp(401, reason)
            _ ->
                conn
            end
        # ----------------------------------
        
    end
    # SIGNIN
    def signin(conn,%{"account"=>account,"password"=>password})  do
        case token_sign_in(account,password) do
             {:ok, token, claims} -> json conn, %{accesstoken: token}
                                _ ->  send_resp(conn, 404, "Not found")
            end
    end



    defp struct_to_map(struct) do
        struct
        |> Map.from_struct()
        |> Map.drop([:__meta__])
    end


    def verify_account_password(account,password) do
        id = Usermanage.check_user(account,password)
        if is_nil(id) do
            {:error, "Account or password not true"}
        else
            {:ok, id}
        end
    end

    def token_sign_in(account,password) do
        case verify_account_password(account,password) do
            {:ok, id} -> Guardian.encode_and_sign(Usermanage.get_user(id),%{}, ttl: {1, :minute})
                    _ ->  {:error, :unauthorized}
        end
    end

    def verify_token(token) do
        case Guardian.decode_and_verify(token) do
        {:ok,claim} -> {:ok, claim["sub"]}
                  _ -> {:error, "Unauthorized"}
        end
    end

    def facebook_login(conn,_params) do
        redirect(conn, external: "https://www.facebook.com/v6.0/dialog/oauth?client_id=#{"197695828014122"}&redirect_uri=#{"http://localhost:4000/api/bank/FacebookHandler"}&state=#{"{st=state123abc,ds=123456789}"}&response_type=token")
    end

    def facebook_login_handler(conn, %{"state"=> state}) do
        IO.inspect state
        params = %{st: state}
        json conn, params
    end
  end