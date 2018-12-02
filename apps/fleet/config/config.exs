# Since configuration is shared in umbrella projects, this file
# should only configure the :fleet application itself
# and only for organization purposes. All other config goes to
# the umbrella root.
use Mix.Config

config :fleet,
  ecto_repos: [Fleet.Repo]

import_config "#{Mix.env()}.exs"