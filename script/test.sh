#!/bin/bash

docker compose run --rm -e PAU_LIB_PATH_LIST='t/lib lib' app carton exec -- prove -lvr $1
