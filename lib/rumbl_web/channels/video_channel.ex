defmodule RumblWeb.VideoChannel do
  use RumblWeb, :channel

  alias Rumbl.{Accounts, Multimedia}
  alias RumblWeb.{AnnotationView, Presence}

  # START:last_seen_id
  def join("videos:" <> video_id, params, socket) do
    last_seen_id = params["last_seen_id"] || 0 # <label id="code.last-seen-id-param"/>
    video_id = String.to_integer(video_id)
    video = Multimedia.get_video!(video_id)

    annotations =
      video
      |> Multimedia.list_annotations(last_seen_id) # <label id="code.annotations-last-seen-id"/>
      |> Phoenix.View.render_many(AnnotationView, "annotation.json")

    send(self(), :after_join)

    {:ok, %{annotations: annotations}, assign(socket, :video_id, video_id)}
  end
  # END:last_seen_id

  def handle_info(:after_join, socket) do
    push socket, "presence_state", Presence.list(socket)
    {:ok, _} = Presence.track(socket, socket.assigns.user_id, %{})
    {:noreply, socket}
  end

  def handle_in(event, params, socket) do # <label id="code.handle-in-all"/>
    user = Accounts.get_user!(socket.assigns.user_id)
    handle_in(event, params, user, socket)
  end

  def handle_in("new_annotation", params, user, socket) do # <label id="code.handle-in-new-ann"/>
    case Multimedia.annotate_video(user, socket.assigns.video_id, params) do
      {:ok, annotation} ->
        broadcast!(socket, "new_annotation", %{
          id: annotation.id,
          user: RumblWeb.UserView.render("user.json", %{user: user}), # <label id="code.user-show-json"/>
          body: annotation.body,
          at: annotation.at
        })
        {:reply, :ok, socket}

      {:error, changeset} ->
        {:reply, {:error, %{errors: changeset}}, socket}
    end
  end
end
