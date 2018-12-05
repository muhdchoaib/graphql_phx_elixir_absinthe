defmodule FleetGraphql.Schema.Driver do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  node(object(:driver)) do
    field(:name, non_null(:string))
    field(:accessible_vehicles, list_of(non_null(:vehicle))) do
      resolve(&FleetGraphql.Schema.Vehicle.list_accessible_for_driver/3)
    end

    field(:inserted_at, non_null(:datetime))
    field(:updated_at, non_null(:datetime))
  end

  object(:driver_queries) do
    field(:drivers, list_of(non_null(:driver))) do
      resolve(&FleetGraphql.Schema.Driver.list/3)
    end

    field(:single_driver, non_null(:driver)) do
      arg :id, non_null(:id)
      resolve(&FleetGraphql.Schema.Driver.single_driver/3)
    end

    field(:accessible_vehicles, list_of(non_null(:vehicle))) do
      resolve(&FleetGraphql.Schema.Vehicle.list_accessible_for_driver/3)
    end


  end

  object(:driver_mutations) do
    # TODO: uncomment this and write the resolver to create drivers (see vehicles for example)
     payload(field(:create_driver)) do
       input do
         field(:name, non_null(:string))
       end
     
       output do
         field(:driver, :driver)
       end
     
       resolve(&FleetGraphql.Schema.Driver.create_driver/2)
     end

    # TODO: uncomment this and write the resolver to update drivers
    payload(field(:update_driver)) do
      input do
        field(:id, non_null(:id))
        field(:name, :string)
      end

      output do
        field(:driver, :driver)
      end

      resolve(&FleetGraphql.Schema.Driver.update_driver/3)
    end
  end

  ## Resolvers

  def single_driver(_parent, %{id: id}, _info) do
    case decode_driver_ids(id) do
      {:ok, driver_id} ->
        require Ecto.Query
        query = Ecto.Query.from(v in Fleet.Data.Driver, where: v.id == ^driver_id)

        case Fleet.Repo.one(query) do
          driver = %Fleet.Data.Driver{} ->
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

  def update_driver(_parent, %{id: id, name: name}, _info) do
    #id = Map.get(args, :id, nil)
    #vehicle_vin = Map.get(args, :vin, nil)

    case decode_driver_ids(id) do
      {:ok, driver_id} ->
        require Ecto.Query
        query = Ecto.Query.from(v in Fleet.Data.Driver, where: v.id == ^driver_id)

        case Fleet.Repo.one(query) do
          driver = %Fleet.Data.Driver{} ->
            changeset = Fleet.Data.Driver.changeset(driver, %{name: name})

            case Fleet.Repo.update(changeset) do
              {:ok, driver = %Fleet.Data.Driver{}} ->
                output = %{driver: driver}
                {:ok, output}

              {:error, changeset = %Ecto.Changeset{}} ->
                errors =
                  Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
                    Enum.reduce(opts, msg, fn {key, value}, acc ->
                      String.replace(acc, "%{#{key}}", to_string(value))
                    end)
                  end)

                graphql_error = %{
                  message: "errors encountered while updating driver",
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

 def create_driver(args, _info) do
    changeset = Fleet.Data.Driver.changeset(%Fleet.Data.Driver{}, args)

    case Fleet.Repo.insert(changeset) do
      {:ok, driver = %Fleet.Data.Driver{}} ->
        output = %{driver: driver}
        {:ok, output}

      {:error, changeset = %Ecto.Changeset{}} ->
        errors =
          Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
            Enum.reduce(opts, msg, fn {key, value}, acc ->
              String.replace(acc, "%{#{key}}", to_string(value))
            end)
          end)

        graphql_error = %{
          message: "errors encountered while creating driver",
          errors: errors
        }

        {:error, graphql_error}
    end
  end

  def fetch(parent, %{type: :driver, id: driver_id}, _info) when map_size(parent) === 0 do
    require Ecto.Query
    query = Ecto.Query.from(d in Fleet.Data.Driver, where: d.id == ^driver_id)

    case Fleet.Repo.one(query) do
      driver = %Fleet.Data.Driver{} ->
        {:ok, driver}

      nil ->
        {:ok, nil}
    end
  end

  def list(parent, _args, _info) when map_size(parent) === 0 do
    require Ecto.Query
    query = Ecto.Query.from(d in Fleet.Data.Driver, order_by: [asc: d.id])
    drivers = Fleet.Repo.all(query)
    {:ok, drivers}
  end

  def list_drivers_with_access(%Fleet.Data.Vehicle{id: vehicle_id}, _args, _info) do
    ##List drivers with access to vehicle with id as parent.
    require Ecto.Query

    query =
      Ecto.Query.from(d in Fleet.Data.Driver,
        join: dvg in Fleet.Data.DriverVehicleGrant,
        on: dvg.driver_id == d.id,
        where: dvg.vehicle_id == ^vehicle_id and dvg.scope == ^[:access],
        select: d
      )

    list_of_drivers = Fleet.Repo.all(query)
    {:ok, list_of_drivers}
  end

  def list_drivers_with_access(_parent, _args, _info) do
    ##List all drivers with access to any vehicle
    require Ecto.Query

    query =
      Ecto.Query.from(d in Fleet.Data.Driver,
        join: dvg in Fleet.Data.DriverVehicleGrant,
        on: dvg.driver_id == d.id,
        where: dvg.scope == ^[:access],
        select: d
      )

    list_of_drivers = Fleet.Repo.all(query)
    {:ok, list_of_drivers}
  end

  defp decode_driver_ids(driver_id) do
    case FleetGraphql.from_global_id(driver_id) do
      {:ok, %{type: :driver, id: driver_id}} ->
        {:ok, driver_id}

      {:error, reason} ->
        {:error, reason}
    end

  end


end
