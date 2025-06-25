FROM alpine:3.20

RUN apk add --no-cache python3 py3-pip

# Copy app files
WORKDIR /app
COPY . /app

CMD ["python3", "--version"]
