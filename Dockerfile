FROM perl:5.34

RUN cpanm Carton \
    && mkdir -p /usr/src/app
WORKDIR /usr/src/app

ONBUILD COPY cpanfile* /usr/src/app
ONBUILD RUN carton install

ONBUILD COPY . /usr/src/app
