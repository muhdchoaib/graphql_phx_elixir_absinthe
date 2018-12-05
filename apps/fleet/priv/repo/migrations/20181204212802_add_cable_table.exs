defmodule Fleet.Repo.Migrations.AddCabsTable do
  use Ecto.Migration

  def change() do
    create(table("cabs", primary_key: false)) do
      add(:id, :serial, primary_key: true)
      add(:vehicle_id, references("vehicles", type: :integer), null: false)
      add(:type, :text, null: false)
      timestamps(type: :utc_datetime, default: fragment("now()"))
    end
  end
end