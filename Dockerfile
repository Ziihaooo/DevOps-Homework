FROM alpine:3.20
# hadolint ignore=DL3018
RUN apk add --no-cache bash
WORKDIR /app
COPY . /app
CMD ["echo", "🧑‍💻 Hello from Bitbucket Pipeline!"]
