alias Rumbl.{Accounts, Multimedia}

{:ok, user} = Accounts.register_user(%{
  name: "User 1",
  username: "user1",
  credential: %{
    email: "user1@example.com",
    password: "password",
  }
})

for category <- ~w(Action Drama Romance Comedy Sci-fi) do
  Multimedia.create_category(category)
end

{:ok, _video} = Multimedia.create_video(user, %{
  title: "Elixir Documentary",
  url: "https://www.youtube.com/watch?v=lxYFOM3UJzo&feature=youtu.be",
  description: "Get ready to explore the origins of the #Elixir programming language",
})
