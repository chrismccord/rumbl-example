defmodule RumblWeb.VideoController do
  use RumblWeb, :controller

  alias Rumbl.Multimedia
  alias Rumbl.Multimedia.Video

  plug :load_categories when action in [:new, :create, :edit, :update]

  defp load_categories(conn, _) do
    assign(conn, :categories, Multimedia.list_alphabetical_categories())
  end

  # START:action-override
  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end
  # END:action-override

  # START:scoped-index-show
  def index(conn, _params, current_user) do
    videos = Multimedia.list_user_videos(current_user) # <label id="code.scoped-index"/>
    render(conn, "index.html", videos: videos)
  end

  def show(conn, %{"id" => id}, current_user) do
    video = Multimedia.get_user_video!(current_user, id) # <label id="code.scoped-show"/>
    render(conn, "show.html", video: video)
  end
  # END:scoped-index-show

  # START:scoped-edit-update
  def edit(conn, %{"id" => id}, current_user) do
    video = Multimedia.get_user_video!(current_user, id) # <label id="code.scoped-edit"/>
    changeset = Multimedia.change_video(current_user, video)
    render(conn, "edit.html", video: video, changeset: changeset)
  end

  def update(conn, %{"id" => id, "video" => video_params}, current_user) do
    video = Multimedia.get_user_video!(current_user, id) # <label id="code.scoped-update"/>

    case Multimedia.update_video(video, video_params) do
      {:ok, video} ->
        conn
        |> put_flash(:info, "Video updated successfully.")
        |> redirect(to: Routes.video_path(conn, :show, video))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", video: video, changeset: changeset)
    end
  end
  # END:scoped-edit-update

  # START:scoped-delete
  def delete(conn, %{"id" => id}, current_user) do
    video = Multimedia.get_user_video!(current_user, id) # <label id="code.scoped-delete"/>
    {:ok, _video} = Multimedia.delete_video(video)

    conn
    |> put_flash(:info, "Video deleted successfully.")
    |> redirect(to: Routes.video_path(conn, :index))
  end
  # END:scoped-delete

  # START:new-create-build-videos
  def new(conn, _params, current_user) do
    changeset = Multimedia.change_video(current_user, %Video{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"video" => video_params}, current_user) do
    case Multimedia.create_video(current_user, video_params) do
      {:ok, video} ->
        conn
        |> put_flash(:info, "Video created successfully.")
        |> redirect(to: Routes.video_path(conn, :show, video))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
  # END:new-create-build-videos
end
