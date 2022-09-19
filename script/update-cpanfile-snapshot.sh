#!/bin/bash

docker compose run --rm -e PERL_CARTON_PATH=/tmp/cpan app bash -c "carton install"