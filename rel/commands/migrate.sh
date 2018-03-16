#!/bin/sh

# run migrations
$RELEASE_ROOT_DIR/bin/mpnetwork command Elixir.Mpnetwork.ReleaseTasks seed
