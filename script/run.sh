#!/bin/bash

docker run --rm -v $(pwd):/usr/src/app perl:carton carton exec -- perl $1
