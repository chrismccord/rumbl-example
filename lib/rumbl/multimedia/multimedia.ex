defmodule Rumbl.Multimedia do
  import Ecto.Query, warn: false

  alias Rumbl.Repo
  alias Rumbl.Multimedia.{Video, Category}
  alias Rumbl.Accounts

  # START:user-preloads
  def list_videos do
    Video
    |> Repo.all()
    |> preload_user()
  end

  def create_category(name) do
    Repo.get_by(Category, name: name) || Repo.insert!(%Category{name: name})
  end

  def list_alphabetical_categories do
    Category
    |> Category.alphabetical()
    |> Repo.all()
  end

  def list_user_videos(%Accounts.User{} = user) do
    Video
    |> user_videos_query(user)
    |> Repo.all()
    |> preload_user()
  end

  def get_user_video!(%Accounts.User{} = user, id) do
    from(v in Video, where: v.id == ^id)
    |> user_videos_query(user)
    |> Repo.one!()
    |> preload_user()
  end

  def get_video!(id), do: preload_user(Repo.get!(Video, id))

  defp preload_user(video_or_videos), do: Repo.preload(video_or_videos, :user)
  # END:user-preloads

  defp user_videos_query(query, %Accounts.User{id: user_id}) do
    from(v in query, where: v.user_id == ^user_id)
  end

  def update_video(%Video{} = video, attrs) do
    video
    |> Video.changeset(attrs)
    |> Repo.update()
  end

  def delete_video(%Video{} = video) do
    Repo.delete(video)
  end

  def create_video(%Accounts.User{} = user, attrs \\ %{}) do
    %Video{}
    |> Video.changeset(attrs)
    |> put_user(user)
    |> Repo.insert()
  end

  def change_video(%Accounts.User{} = user, %Video{} = video) do
    video
    |> Video.changeset(%{})
    |> put_user(user)
  end

  defp put_user(changeset, user) do
    Ecto.Changeset.put_assoc(changeset, :user, user)
  end

  alias Rumbl.Multimedia.Annotation

  def annotate_video(%Accounts.User{} = user, video_id, attrs) do # <label id="code.annotate_video"/>
    %Annotation{video_id: video_id}
    |> Annotation.changeset(attrs)
    |> put_user(user)
    |> Repo.insert()
  end

  # START:annotations-since
  def list_annotations(%Video{} = video, since_id \\ 0) do
    Repo.all(
      from a in Ecto.assoc(video, :annotations),
        where: a.id > ^since_id, # <label id="code.last-seen-id-query"/>
        order_by: [asc: a.at, asc: a.id],
        limit: 500,
        preload: [:user]
    )
  end
  # END:annotations-since
end
