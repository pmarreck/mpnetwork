#!/bin/sh

# run migrations
# $RELEASE_ROOT_DIR/bin/mpnetwork command Elixir.Mpnetwork.ReleaseTasks seed
release_ctl eval --mfa "Mpnetwork.ReleaseTasks.migrate/1" --argv -- "$@"
