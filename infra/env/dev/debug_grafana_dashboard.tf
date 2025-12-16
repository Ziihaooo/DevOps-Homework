resource "grafana_dashboard" "debug_client_domains" {
  config_json = file("${path.module}/../grafana/default_dashboards/client_domains_dashboard.json")
}
