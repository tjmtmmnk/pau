#!/bin/bash

docker compose run --rm -e app carton exec -- perl -Ilib $1
