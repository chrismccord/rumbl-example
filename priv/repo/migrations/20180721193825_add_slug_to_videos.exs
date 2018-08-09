defmodule Rumbl.Repo.Migrations.AddSlugToVideos do
  use Ecto.Migration

  # START:add-slug
  def change do
    alter table(:videos) do
      add :slug, :string
    end
  end
  # END:add-slug
end
