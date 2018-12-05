defmodule Fleet.Data.Cab do
  use Ecto.Schema
  import Ecto.Changeset

  @type t() :: %__MODULE__{}

  schema "cabs" do
    field :type, :string
    belongs_to(:vehicle, Fleet.Data.Vehicle)
    timestamps(type: :utc_datetime)
  end

  def changeset(struct = %__MODULE__{}, params) do
    struct
    |> cast(params, [
      :vehicle_id,
      :type
    ])
    |> validate_required([
      :vehicle_id,
      :type
    ])
  end
end