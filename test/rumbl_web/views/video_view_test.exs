defmodule RumblWeb.VideoViewTest do
  use RumblWeb.ConnCase, async: true
  import Phoenix.View

  # <label id="code.render-index"/>
  test "renders index.html", %{conn: conn} do
    videos = [
      %Rumbl.Multimedia.Video{id: "1", title: "dogs"},
      %Rumbl.Multimedia.Video{id: "2", title: "cats"}
    ]

    content = render_to_string(RumblWeb.VideoView, "index.html", conn: conn, videos: videos)

    assert String.contains?(content, "Listing Videos")

    for video <- videos do
      assert String.contains?(content, video.title)
    end
  end

  # <label id="code.render-new"/>
  test "renders new.html", %{conn: conn} do
    owner = %Rumbl.Accounts.User{}
    changeset = Rumbl.Multimedia.change_video(owner, %Rumbl.Multimedia.Video{})
    categories = [%Rumbl.Multimedia.Category{id: 123, name: "cats"}]

    content =
      render_to_string(RumblWeb.VideoView,"new.html",
        conn: conn,
        changeset: changeset,
        categories: categories
      )

    assert String.contains?(content, "New Video")
  end
end
