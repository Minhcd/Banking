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

    #jwt
    defp jwt_encode() do
        header = %{
            "alg"=>"alg",
            "typ"=>"typ"
        }
        claim= %{
            "exp"=>"exp",
            "nbf"=>"nbf",
            "lat"=>"lat",
            "sub"=>"sub",
            "iss"=>"iss",
            "aud"=>"aud",
            "jti"=>"jti"
        }
        
    end

    defp jwt_decode() do
    end

    #Oauth
    @app_id "197695828014122"
    @app_secret "dd085e5054471410b9fc55fb1fd4de8e"
    @redirect_url "http://localhost:4000/api/bank/FacebookHandler"

    def facebook_login(conn,_params) do
        redirect(conn, external: "https://www.facebook.com/v6.0/dialog/oauth?client_id=#{@app_id}&redirect_uri=#{@redirect_url}&state=#{"{st=state123abc,ds=123456789}"}")
    end
    #exchange code for access token
    def facebook_login_handler(conn, %{"code"=> code}) do

        %{
            "access_token"=> access_token,
            "expires_in"=> expires_in,
            "token_type" => token_type
            } = exchange_access_token(code) # expire : second till expire

        %{
            "app_id" => app_id,
            "application" => application,
            "data_access_expires_at" => data_access_expires_at,
            "expires_at" => expires_at,
            "is_valid" => is_valid,
            "issued_at" => issued_at,
            "scopes" => scope,
            "type" => type,
            "user_id" => user_id
            } = inspect_access_token(access_token)

        %{
            "email"=>email,
            "name"=> name
        } = get_username_email(access_token,user_id)

        user = Repo.get_by(Usermanage, account: name)
        if is_nil(user) do
            create(conn, %{"account" => name,"password" => user_id })
        else
            signin(conn,%{"account"=> name,"password"=> user_id })
        end

    end

    defp exchange_access_token(code)do
        url = "https://graph.facebook.com/v6.0/oauth/access_token?client_id=#{@app_id}&redirect_uri=#{@redirect_url}&client_secret=#{@app_secret}&code=#{code}"
        {:ok, resp} = HTTPoison.get(url)
        {:ok, json_resp} = JSON.decode(resp.body)
        json_resp
    end

    defp get_app_access_token() do
        url = "https://graph.facebook.com/oauth/access_token?client_id=#{@app_id}&client_secret=#{@app_secret}&grant_type=client_credentials"
        {:ok, resp} = HTTPoison.get(url)
        {:ok, json_resp} = JSON.decode(resp.body)
        json_resp["access_token"]
    end

    defp inspect_access_token(access_token) do
        app_access_token = get_app_access_token()
        url = "https://graph.facebook.com/debug_token?input_token=#{access_token}&access_token=#{app_access_token}"
        {:ok, resp} = HTTPoison.get(url)
        {:ok, json_resp} = JSON.decode(resp.body)
         json_resp["data"]
    end
   
    defp get_username_email(access_token,user_id) do
        url = "https://graph.facebook.com/#{user_id}?fields=name,email&access_token=#{access_token}"
        {:ok, resp} = HTTPoison.get(url)
        {:ok, json_resp} = JSON.decode(resp.body)
        json_resp
    end
  end

#   https://graph.facebook.com/v6.0/oauth/access_token?client_id=197695828014122&redirect_uri=http://localhost:4000/api/bank/FacebookHandler&client_secret=dd085e5054471410b9fc55fb1fd4de8e&code=AQDmbXNlQ4DImBioeDSAdFFZn_7nKC9gU6MSYZJYihkqmM_OFhnmWE-ui6S2hJvDnEk46qPwPzmBK6Fk8VnmdHZIMyH7ApeSCXrsPgH9_KFwgUV3U7fs0gCF0YNwv2r61P_Pk57o1r5ZCrpJ6SsCjv2wVFToCxH_dQVMq0P8aHIvd6gMXUaYQYDcOmJCeggjqxyz0ql2zMg6RBhJY28Udn02o4t_syfrZaXKd0vRSf7-aMx0_yRGGawZ4GBgpmUhyHWeM5hbN4ti1QUWOrXWMD5zjgqZxOQ_06iU6-bHJeMrtBxAiVeAAQUcTb09ca_1uTNSmUY4Rf_7dkt_IkZCD1aj%26state=%7Bst%3Dstate123abc%2Cds%3D123456789%7D#_=_

#   url = "https://graph.facebook.com/v6.0/oauth/access_token?client_id=#{client_id}&redirect_uri=#{redirect_url}&client_secret=#{client_secret}&code=#{code}"     