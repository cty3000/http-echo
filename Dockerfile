ARG RUNTIME_IMAGE=alpine:3.15

FROM golang:1.17-alpine AS builder

# Arguments go here so that the previous steps can be cached if no external
#  sources have changed.
ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG VERSION=v0.2.3

LABEL maintainer="CTY <admin@ctyavalon.com>"

RUN set -eux \
    && apk --no-cache add --virtual build-dependencies unzip curl git tzdata make
RUN cp /usr/share/zoneinfo/Japan /etc/localtime

RUN go install github.com/hashicorp/http-echo@${VERSION}

# Build binary and make sure there is at least an empty key file.
#  This is useful for GCP App Engine custom runtime builds, because
#  you cannot use multiline variables in their app.yaml, so you have to
#  build the key into the container and then tell it where it is
#  by setting OAUTH2_PROXY_JWT_KEY_FILE=/etc/ssl/private/jwt_signing_key.pem
#  in app.yaml instead.
# Set the cross compilation arguments based on the TARGETPLATFORM which is
#  automatically set by the docker engine.
#RUN case ${TARGETPLATFORM} in \
#         "linux/amd64")  echo ${TARGETPLATFORM} ;; \
#         "linux/arm64" | "linux/arm64/v8")  echo ${TARGETPLATFORM}  ;; \
#    esac

FROM ${RUNTIME_IMAGE}

RUN set -eux \
    && apk --no-cache add --virtual build-dependencies unzip curl git tzdata
RUN cp /usr/share/zoneinfo/Japan /etc/localtime

COPY --from=builder /go/bin/http-echo /usr/local/bin/http-echo

# UID/GID 65532 is also known as nonroot user in distroless image
USER 65532:65532

ENTRYPOINT /usr/local/bin/http-echo
