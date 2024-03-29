#!/bin/sh
# Adapted from Alex Kleissner's post, Running a Phoenix 1.3 project with docker-compose
# https://medium.com/@hex337/running-a-phoenix-1-3-project-with-docker-compose-d82ab55e43cf

set -e

echo "MIX_ENV=$MIX_ENV"
# Ensure any app auth prereqs are installed
mix local.hex --force
mix local.rebar --force
mix hex.organization auth oban --key ${OBAN_LICENSE_KEY}

# Ensure the app's dependencies are installed
mix deps.get

# Prepare Dialyzer if the project has Dialyxer set up
# if mix help dialyzer >/dev/null 2>&1
# then
#   echo "\nFound Dialyxer: Setting up PLT..."
#   mix do deps.compile, dialyzer --plt
# else
#   echo "\nNo Dialyxer config: Skipping setup..."
# fi

# Install JS libraries
# echo "Installing JS..."
# npm install --prefix=assets

# DEBUGGING MISSING PSQL
# ls -al /usr/local/bin
# ls -al /usr/bin
# uname -a

# Potentially Set up the database
mix ecto.create
mix ecto.migrate

# Wait for Postgres to become available.
# DBHOST=localhost:5432
# until psql -h $DBHOST -U postgres -c '\q' 2>/dev/null; do
# do not mute psql errors for now:
until psql -h localhost -U postgres -c '\q' ; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 1
done

echo "Postgres is available: continuing with database setup..."

#Analysis style code
# Prepare Credo if the project has Credo start code analyze
# if mix help credo >/dev/null 2>&1
# then
#   echo "\nFound Credo: analyzing..."
#   mix credo || true
# else
#   echo "\nNo Credo config: Skipping code analyze..."
# fi

echo "Testing the installation..."
# "Prove" that install was successful by running the tests
MIX_ENV=test mix test

echo "Compiling js assets..."
cd assets; npm install; cd ..

echo "Launching Phoenix web server..."
# Start the phoenix web server
mix phx.server
curl localhost:4000
