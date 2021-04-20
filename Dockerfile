FROM dlang2/dmd-ubuntu:2.096.0 AS build

WORKDIR /app

COPY dub.json dub.selections.json ./
RUN dub build
COPY . .
RUN dub build

FROM ubuntu:20.04 AS runtime

RUN apt update && apt install -y libssl-dev

COPY --from=build /app/xthl .

EXPOSE 8080

ENTRYPOINT ["/xthl"]