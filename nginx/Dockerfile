# build stage: prepare config file
FROM alpine:3.20 AS builder
WORKDIR /config
COPY default.conf .

# final stage: build nginx image
FROM nginx:1.29.3-alpine3.22
COPY ./html /usr/share/nginx/html
COPY --from=builder /config/default.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
