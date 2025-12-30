FROM grafana/grafana:10.4.3

USER root

# Copy provisioning configurations
COPY ./provisioning/ /etc/grafana/provisioning/
# Copy your dashboard JSON into the location defined in dashboards.yml
COPY ./default_dashboards/client_domains_dashboard.json /etc/grafana/provisioning/dashboards/
USER grafana

EXPOSE 3000
