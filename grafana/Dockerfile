FROM grafana/grafana:10.4.3

USER root
RUN apk update && apk add curl

RUN grafana-cli plugins install grafana-aws-cloudwatch-datasource

EXPOSE 3000