# Dockerfile for minimal Prometheus + Grafana on Railway
FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    ca-certificates \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Install Prometheus
ARG PROMETHEUS_VERSION=2.47.0
RUN wget -q https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz \
    && tar -xzf prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz \
    && mv prometheus-${PROMETHEUS_VERSION}.linux-amd64/prometheus /usr/local/bin/ \
    && mv prometheus-${PROMETHEUS_VERSION}.linux-amd64/promtool /usr/local/bin/ \
    && rm -rf prometheus-${PROMETHEUS_VERSION}.linux-amd64*

# Install Grafana
ARG GRAFANA_VERSION=10.1.0
RUN wget -q https://dl.grafana.com/oss/release/grafana-${GRAFANA_VERSION}.linux-amd64.tar.gz \
    && tar -xzf grafana-${GRAFANA_VERSION}.linux-amd64.tar.gz \
    && mv grafana-${GRAFANA_VERSION}/bin/grafana-server /usr/local/bin/ \
    && mv grafana-${GRAFANA_VERSION}/public /usr/share/grafana/ \
    && mv grafana-${GRAFANA_VERSION}/conf /etc/grafana/ \
    && mkdir -p /usr/share/grafana/plugins \
    && rm -rf grafana-${GRAFANA_VERSION}*

# Create prometheus user
RUN useradd -r -s /bin/false prometheus

# Create directories
RUN mkdir -p /etc/prometheus /var/lib/prometheus /etc/grafana/provisioning/datasources /etc/grafana/provisioning/dashboards /var/lib/grafana /var/log/grafana /var/lib/grafana/plugins /var/lib/grafana/dashboards

# Copy configs
COPY prometheus.yml /etc/prometheus/prometheus.yml
COPY grafana/datasources/datasources.yml /etc/grafana/provisioning/datasources/datasources.yml
COPY grafana/dashboards/dashboard-provider.yml /etc/grafana/provisioning/dashboards/dashboard-provider.yml
COPY grafana/dashboards/system-health.json /var/lib/grafana/dashboards/system-health.json
COPY grafana.ini /etc/grafana/grafana.ini

# Supervisord config
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Expose ports
EXPOSE 9090 3000

# Set permissions
RUN chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus /etc/grafana /var/lib/grafana

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]