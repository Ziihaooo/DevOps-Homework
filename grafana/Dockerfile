FROM grafana/grafana:10.4.3

USER root

# 默认 dashboards（每次起容器都会加载）
COPY default_dashboards /var/lib/grafana/dashboards

# provisioning（datasource + dashboard provider）
COPY provisioning /etc/grafana/provisioning

USER grafana

EXPOSE 3000
