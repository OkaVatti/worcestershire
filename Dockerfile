FROM crystallang/crystal:1.19.1-alpine AS builder
WORKDIR /app
COPY shard.yml shard.lock ./
RUN shards install --production
COPY src ./src
RUN crystal build src/worcestershire.cr --release --static

FROM alpine:latest
RUN apk add --no-cache libc6-compat
COPY --from=builder /app/worcestershire /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/worcestershire"]