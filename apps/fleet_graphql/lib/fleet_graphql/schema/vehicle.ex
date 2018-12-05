defmodule FleetGraphql.Schema.Vehicle do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  node(object(:vehicle)) do
    field(:vin, non_null(:string))
    # TODO: uncomment this and write the resolver to list drivers with access to a specific vehicle
    field(:drivers_with_access, list_of(non_null(:driver))) do
      resolve(&FleetGraphql.Schema.Driver.list_drivers_with_access/3)
    end

    field(:inserted_at, non_null(:datetime))
    field(:updated_at, non_null(:datetime))
  end
  
  object(:vehicle_queries) do
    # TODO: uncomment this and write the resolver to list all vehicles (see drivers for example)
    field(:vehicles, list_of(non_null(:vehicle))) do
      resolve(&FleetGraphql.Schema.Vehicle.list/3)
    end

    field(:single_vehicle, non_null(:vehicle)) do
      arg :id, non_null(:id)
      resolve(&FleetGraphql.Schema.Vehicle.single_vehicle/3)
    end

    field(:drivers_with_access, list_of(non_null(:driver))) do
      resolve(&FleetGraphql.Schema.Driver.list_drivers_with_access/3)
    end

  end

  object(:vehicle_mutations) do
    payload(field(:create_vehicle)) do
      input do
        field(:vin, non_null(:string))
      end

      output do
        field(:vehicle, :vehicle)
      end

      resolve(&FleetGraphql.Schema.Vehicle.create_vehicle/2)
    end

    # TODO: uncomment this and write the resolver to update vehicles
    payload(field(:update_vehicle)) do
      input do
        field(:id, non_null(:id))
        field(:vin, :string)
      end
    
      output do
        field(:vehicle, :vehicle)
      end
    
      resolve(&FleetGraphql.Schema.Vehicle.update_vehicle/3)
    end
  end

  ## Resolvers

  def single_vehicle(_parent, %{id: id}, _info) do
    case decode_vehicle_ids(id) do
      {:ok, vehicle_id} ->
        require Ecto.Query
        query = Ecto.Query.from(v in Fleet.Data.Vehicle, where: v.id == ^vehicle_id)

        case Fleet.Repo.one(query) do
          driver = %Fleet.Data.Vehicle{} ->
            #            output = %{driver: driver}
            {:ok, driver}
          nil ->
            graphql_error = %{
              message: "errors encountered while querying driver"
            }
            {:error, graphql_error}
        end
      {:error, reason} ->
        {:error, reason}
    end
  end

  def update_vehicle(_parent, %{id: id, vin: vehicle_vin}, _info) do
    #id = Map.get(args, :id, nil)
    #vehicle_vi = Map.get(args, :vin, nil)

    case decode_vehicle_ids(id) do
      {:ok, vehicle_id} ->
      require Ecto.Query
      query = Ecto.Query.from(v in Fleet.Data.Vehicle, where: v.id == ^vehicle_id)
   
      case Fleet.Repo.one(query) do
        vehicle = %Fleet.Data.Vehicle{} ->
          changeset = Fleet.Data.Vehicle.changeset(vehicle, %{vin: vehicle_vin})

          case Fleet.Repo.update(changeset) do
            {:ok, vehicle = %Fleet.Data.Vehicle{}} ->
              output = %{vehicle: vehicle}
              {:ok, output}

            {:error, changeset = %Ecto.Changeset{}} ->
              errors =
                Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
                  Enum.reduce(opts, msg, fn {key, value}, acc ->
                    String.replace(acc, "%{#{key}}", to_string(value))
                  end)
                end)

              graphql_error = %{
                message: "errors encountered while updating vehicle",
                errors: errors
              }

              {:error, graphql_error}
          end
        nil ->
          graphql_error = %{
            message: "errors encountered while querying driver"
          }
          {:error, graphql_error}
      end
        {:error, reason} ->
          {:error, reason}
      end
  end

  def create_vehicle(args, _info) do
    changeset = Fleet.Data.Vehicle.changeset(%Fleet.Data.Vehicle{}, args)

    case Fleet.Repo.insert(changeset) do
      {:ok, vehicle = %Fleet.Data.Vehicle{}} ->
        output = %{vehicle: vehicle}
        {:ok, output}

      {:error, changeset = %Ecto.Changeset{}} ->
        errors =
          Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
            Enum.reduce(opts, msg, fn {key, value}, acc ->
              String.replace(acc, "%{#{key}}", to_string(value))
            end)
          end)

        graphql_error = %{
          message: "errors encountered while creating vehicle",
          errors: errors
        }

        {:error, graphql_error}
    end
  end

  def fetch(parent, %{type: :vehicle, id: vehicle_id}, _info) when map_size(parent) === 0 do
    require Ecto.Query
    query = Ecto.Query.from(v in Fleet.Data.Vehicle, where: v.id == ^vehicle_id)

    case Fleet.Repo.one(query) do
      vehicle = %Fleet.Data.Vehicle{} ->
        {:ok, vehicle}

      nil ->
        {:ok, nil}
    end
  end

  def list_accessible_for_driver(%Fleet.Data.Driver{id: driver_id}, _args, _info) do
    require Ecto.Query

    query =
      Ecto.Query.from(v in Fleet.Data.Vehicle,
        join: dvg in Fleet.Data.DriverVehicleGrant,
        on: dvg.vehicle_id == v.id,
        where: dvg.driver_id == ^driver_id and dvg.scope == ^[:access],
        select: v
      )

    accessible_vehicles = Fleet.Repo.all(query)
    {:ok, accessible_vehicles}
  end

  def list(parent, _args, _info) when map_size(parent) === 0 do
    require Ecto.Query
    query = Ecto.Query.from(v in Fleet.Data.Vehicle, order_by: [asc: v.id])
    vehicles = Fleet.Repo.all(query)
    {:ok, vehicles}
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
