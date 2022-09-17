#!/bin/bash

docker compose run --rm app carton exec -- perl -Ilib $1
