defmodule HelloWeb.GuardianSerializer do
    @behaviour Guardian.Serializer
  
    alias Hello.Repo
    alias Hello.Usermanage
  
    def for_token(user = %Usermanage{}), do: {:ok, "User:#{user.id}"}
    def for_token(_), do: {:error, "Unknown resource type"}
  
    def from_token("User:" <> id), do: {:ok, Repo.get(Usermanage, id)}
    def from_token(_), do: {:error, "Unknown resource type"}
  end