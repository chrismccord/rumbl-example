defmodule Rumbl.Multimedia.Annotation do
  use Ecto.Schema
  import Ecto.Changeset

  # START:annotation-relationships
  schema "annotations" do
    field :at, :integer
    field :body, :string

    belongs_to :user, Rumbl.Accounts.User
    belongs_to :video, Rumbl.Multimedia.Video

    timestamps()
  end
  # END:annotation-relationships

  @doc false
  def changeset(annotation, attrs) do
    annotation
    |> cast(attrs, [:body, :at])
    |> validate_required([:body, :at])
  end
end
