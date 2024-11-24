FROM elixir:alpine

RUN apk update && apk add inotify-tools && apk add git

RUN mix local.hex --force && \
    mix local.rebar --force

WORKDIR /app 

COPY mix.exs mix.lock ./

RUN mix deps.get

COPY . .

RUN mix compile

EXPOSE 4000
RUN mix setup

RUN mix phx.gen.secret

CMD ["mix", "phx.server"]