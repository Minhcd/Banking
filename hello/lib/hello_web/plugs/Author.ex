defmodule HelloWeb.Plugs.Authorization do
    import Plug.Conn
    #import Phoenix.Controller
    use Phoenix.Controller

    def init(_params)do
    end

    def call(conn,_params)do
        # send_resp(conn,200, "Authorization")
        # IO.inspect conn
        
        %{params: %{"id"=> id_from_url, "name"=> account_from_url}}=conn
        id_from_url = elem(Integer.parse(id_from_url),0)
        user_id =   conn.assigns[:user_id]
        user_account = conn.assigns[:user_account]
        user_signed_in? = conn.assigns[:user_signed_in?]
        if user_signed_in? and id_from_url == user_id and account_from_url == user_account do
        conn
        else
        conn
        |> halt()
        end
    end

end

