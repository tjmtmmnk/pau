#!/bin/bash

docker compose run --rm -e PAU_LIB_PATH_LIST='t/fixtures/lib' -e PAU_NO_CACHE=1 app carton exec -- prove -lvr $1
