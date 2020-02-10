defmodule HelloWeb.Plugs.AuthenticateUser do
    import Plug.Conn
    import Phoenix.Controller
  
    alias HelloWeb.Router.Helpers
  
    def init(_params) do
    end
  
    def call(conn, _params) do
      if conn.assigns.user_signed_in? do
        conn
      else
        conn
        |> put_flash(:error, "Bạn cần đăng nhập để tiếp tục")
        |> redirect(to: Helpers.bank_path(conn, :signin))
        |> halt()
      end
    end
  end