FROM envoyproxy/envoy-alpine:v1.21-latest

RUN apk update
RUN apk add ngrep

CMD ["envoy", "-l","trace", "-c","/etc/envoy/config.yaml"]
