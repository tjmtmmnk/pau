FROM perl:5.34

COPY . /app
WORKDIR /app

RUN curl -sL http://cpanmin.us/ | perl - --notest App::cpanminus App::cpm Carton

RUN mkdir -p /app/.cache

ENV PERL_CARTON_PATH /app/cpan
RUN cpm install -w $(nproc) -L $PERL_CARTON_PATH --without-test

VOLUME /src
WORKDIR /src

ENTRYPOINT ["perl", "/app/script/pau.pl"]