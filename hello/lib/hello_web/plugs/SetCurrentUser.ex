defmodule HelloWeb.Plugs.SetCurrentUser do
    import Plug.Conn
    alias Hello.{Usermanage,Repo}

    def init(_params) do
    end

    def call(conn,_params)do
        user_id = get_session(conn, :user_id)
        user_account = get_session(conn, :user_account)
        
        cond do
            user_id && Repo.get(Usermanage, user_id) ->
                conn
                |> assign(:user_id,user_id)
                |> assign(:user_account, user_account)                
                |> assign(:user_signed_in?, true)
            true ->
                conn
                |> assign(:user_id, nil)
                |> assign(:user_account, nil)
                |> assign(:user_signed_in?,false)
            end
    end

end