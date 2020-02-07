FROM golang:latest AS builder

ARG SENSU_VERSION
ENV GOOS "linux"
ENV GOARCH "amd64"
ENV CGO_ENABLED "0"

WORKDIR /build
RUN git clone --depth=1 --single-branch --branch v${SENSU_VERSION} https://github.com/sensu/sensu-go.git

WORKDIR /build/sensu-go
RUN go mod tidy

RUN go build \
    -ldflags '-X "github.com/sensu/sensu-go/version.Version='`echo ${SENSU_VERSION}`'" \
    -X "github.com/sensu/sensu-go/version.BuildDate='`date +%Y-%m-%d`'" \
    -X "github.com/sensu/sensu-go/version.BuildSHA='`git rev-parse HEAD`'"' \
    -o bin/sensu-agent ./cmd/sensu-agent

RUN go build \
    -ldflags '-X "github.com/sensu/sensu-go/version.Version='`echo ${SENSU_VERSION}`'" \
    -X "github.com/sensu/sensu-go/version.BuildDate='`date +%Y-%m-%d`'" \
    -X "github.com/sensu/sensu-go/version.BuildSHA='`git rev-parse HEAD`'"' \
    -o bin/sensu-backend ./cmd/sensu-backend

RUN go build \
    -ldflags '-X "github.com/sensu/sensu-go/version.Version='`echo ${SENSU_VERSION}`'" \
    -X "github.com/sensu/sensu-go/version.BuildDate='`date +%Y-%m-%d`'" \
    -X "github.com/sensu/sensu-go/version.BuildSHA='`git rev-parse HEAD`'"' \
    -o bin/sensuctl ./cmd/sensuctl

FROM alpine:latest

COPY --from=builder /build/sensu-go/bin/sensu-agent /usr/local/bin/sensu-agent
COPY --from=builder /build/sensu-go/bin/sensu-backend /usr/local/bin/sensu-backend
COPY --from=builder /build/sensu-go/bin/sensuctl /usr/local/bin/sensuctl

RUN apk add --no-cache \
    ca-certificates \
    dumb-init

WORKDIR /
VOLUME /var/lib/sensu
EXPOSE 2379 2380 8080 8081 3000

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["sensu-backend"]
