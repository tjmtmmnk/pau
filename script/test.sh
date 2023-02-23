#!/bin/bash

docker compose run --rm app carton exec -- prove -lvr $1
