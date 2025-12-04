###############################
# Stage 1: Base config files
###############################
FROM alpine:3.20 AS base
WORKDIR /config
COPY default.conf default.conf
COPY default.local.conf default.local.conf
COPY html/ /html/


###############################
# Stage 2: Local Version
###############################
FROM base AS local
RUN echo "=== BUILDING LOCAL VERSION ===" && cp default.local.conf final.conf


###############################
# Stage 3: Cloud Version
###############################
FROM base AS cloud
RUN echo "=== BUILDING CLOUD VERSION ===" && cp default.conf final.conf


###############################
# Stage 4: Runtime (Local)
###############################
#let local run until this step be the final image
FROM nginx:1.29.3-alpine3.22 AS runtime-local
COPY --from=local /config/final.conf /etc/nginx/conf.d/default.conf
COPY --from=local /html /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]


###############################
# Stage 5: Runtime (Cloud)
###############################
#let pipelines cloud run until this step be the final image
FROM nginx:1.29.3-alpine3.22 AS runtime-cloud
COPY --from=cloud /config/final.conf /etc/nginx/conf.d/default.conf
COPY --from=cloud /html /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
