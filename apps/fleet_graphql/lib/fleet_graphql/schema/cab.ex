defmodule FleetGraphql.Schema.Cab do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  node(object(:cab)) do
    field(:type, non_null(:string))
    field(:inserted_at, non_null(:datetime))
    field(:updated_at, non_null(:datetime))
  end

  object(:cab_queries) do
    field(:cabs, list_of(non_null(:cab))) do
      resolve(&FleetGraphql.Schema.Cab.list/3)
    end
  end


  object(:cab_mutations) do
    payload(field(:add_cab)) do
      input do
        field(:vehicle_id, non_null(:id))
        field(:type, :string)
      end

      output do
        field(:result, :boolean)
      end

      resolve(&FleetGraphql.Schema.Cab.add_cab/3)
    end
  end

##Resolvers

#  def fetch(parent, %{type: :cab, id: vehicle_id}, _info) when map_size(parent) === 0 do
#    require Ecto.Query
#    query = Ecto.Query.from(v in Fleet.Data.Cab, where: v.id == ^vehicle_id)
#
#     case Fleet.Repo.one(query) do
#      cab = %Fleet.Data.Cab{} ->
#        {:ok, cab}
#        nil ->
#      {:ok, nil}
#      end
#  end

  def list(parent, _args, _info) when map_size(parent) === 0 do
    require Ecto.Query
    query = Ecto.Query.from(c in Fleet.Data.Cab, order_by: [asc: c.id])
    cabs = Fleet.Repo.all(query)
    {:ok, cabs}
  end

  def add_cab(_parent, %{vehicle_id: vehicle_id, type: type}, _info) do
    case decode_vehicle_ids(vehicle_id) do
      {:ok, vehicle_id} ->
        require Ecto.Query

        changeset = Fleet.Data.Cab.changeset(%Fleet.Data.Cab{},
          %{vehicle_id: vehicle_id, type: type})

        _ = Fleet.Repo.insert(changeset)
        output = %{result: true}
        {:ok, output}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp decode_vehicle_ids(vehicle_id) do
    case FleetGraphql.from_global_id(vehicle_id) do
      {:ok, %{type: :vehicle, id: vehicle_id}} ->
        {:ok, vehicle_id}

      {:error, reason} ->
        {:error, reason}
    end
  end


end

