defmodule Carpooling.Accounts do
  import Ecto.Query
  alias Carpooling.{Repo, Accounts.User}

  def list_users_with_ids(ids) do
    Repo.all(from(u in User, where: u.id in ^ids))
  end

  def get_user(id), do: Repo.get(User, id)

  def get_user!(id), do: Repo.get!(User, id)

  def get_user_by(params), do: Repo.get_by(User, params)

  def list_users, do: Repo.all(User)

  def change_user(%User{} = user), do: User.changeset(user, %{})

  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end
end
