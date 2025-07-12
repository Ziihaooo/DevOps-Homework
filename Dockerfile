# ---------- build stage ------------------------------------------------------
FROM alpine:3.20 AS builder
WORKDIR /build
RUN echo '<!DOCTYPE html><html><head><title>Landing Page</title>\
<style>body{margin:0;font-family:sans-serif;display:flex;justify-content:center;align-items:center;height:100vh;background:#f0f4f8;}h1{font-size:2rem;text-align:center;}\
</style></head><body><h1>🏖️ Welcome to the Alpine Landing Page – Fast. Secure. Beautiful.</h1></body></html>' \
> index.html

# ---------- runtime stage ----------------------------------------------------
FROM nginx:1.25-alpine
RUN addgroup -S app -g 1001 && adduser -S -G app -u 1001 app
RUN rm -rf /usr/share/nginx/html/*
COPY --from=builder /build/index.html /usr/share/nginx/html/
COPY nginx.conf /etc/nginx/nginx.conf
RUN chown -R app:app /usr/share/nginx/html && chmod -R 750 /usr/share/nginx/html
USER app
EXPOSE 8080
ENTRYPOINT ["nginx","-g","daemon off;"]
