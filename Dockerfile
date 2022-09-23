FROM perl:5.34

WORKDIR /app
COPY . /app

RUN curl -sL http://cpanmin.us/ | perl - --notest App::cpanminus App::cpm Carton

RUN mkdir /app/.cache

ENV PERL_CARTON_PATH /cpan
RUN carton install -w $(nproc) -L $PERL_CARTON_PATH --with-develop