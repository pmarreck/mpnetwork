#!/bin/sh

# run migrations
$RELEASE_ROOT_DIR/bin/mpnetwork command Elixir.Mpnetwork.ReleaseTasks seed
# install datadog
DD_API_KEY=6bc3c663d759eda744a9599b00c60e1b bash -c "$(curl -L https://raw.githubusercontent.com/DataDog/datadog-agent/master/cmd/agent/install_script.sh)"
