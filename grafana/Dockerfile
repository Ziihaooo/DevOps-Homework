FROM grafana/grafana:10.4.3

USER root

# Copy dashboards (these are your default dashboards)
COPY default_dashboards /var/lib/grafana/dashboards

# Copy provisioning
COPY provisioning /etc/grafana/provisioning

USER grafana

EXPOSE 3000

ENTRYPOINT ["/entrypoint.sh"]
