#!/bin/bash

docker compose run --rm -e PAU_NO_CACHE=1 app carton exec -- prove -lvr $1
