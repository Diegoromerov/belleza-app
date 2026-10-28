# Grafana Cloud Setup for GlowApp Observability

## Prerequisites
1. Grafana Cloud account: https://grafana.com/auth/sign-up/create-user
2. Stack created (free tier: 10k series, 50GB logs, 50GB traces)
3. API Key with `metrics:write`, `logs:write`, `traces:write`, `dashboards:write`, `alerts:write` scopes

## Configuration

### 1. Get Stack Details
After creating stack, note:
- **Stack slug**: `your-stack-name` (from URL: `https://your-stack-name.grafana.net`)
- **Prometheus URL**: `https://prometheus-prod-XX-prod-your-region.grafana.net/api/prom`
- **Loki URL**: `https://logs-prod-XX-prod-your-region.grafana.net/loki/api/v1/push`
- **Tempo URL**: `https://tempo-prod-XX-prod-your-region.grafana.net/tempo/api/v1/push`

### 2. Create API Key
Grafana Cloud → Access → API Keys → Add API Key
- Name: `glowapp-observability`
- Role: `Admin` (or custom with write scopes)
- Copy the key (format: `eyJrIjoi...`)

### 3. Configure Backend Environment Variables
Add to Railway backend service variables:

```bash
# Grafana Cloud endpoints
OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=https://tempo-prod-XX-prod-your-region.grafana.net/tempo/api/v1/push
OTEL_EXPORTER_OTLP_TRACES_HEADERS={"Authorization":"Basic <base64(user:api-key)>"}
OTEL_EXPORTER_OTLP_METRICS_ENDPOINT=https://prometheus-prod-XX-prod-your-region.grafana.net/api/prom/push
OTEL_EXPORTER_OTLP_METRICS_HEADERS={"Authorization":"Basic <base64(user:api-key)>"}
OTEL_EXPORTER_OTLP_LOGS_ENDPOINT=https://logs-prod-XX-prod-your-region.grafana.net/loki/api/v1/push
OTEL_EXPORTER_OTLP_LOGS_HEADERS={"Authorization":"Basic <base64(user:api-key)>"}

# For Prometheus remote write (alternative to OTEL metrics exporter)
PROMETHEUS_REMOTE_WRITE_URL=https://prometheus-prod-XX-prod-your-region.grafana.net/api/prom/push
PROMETHEUS_REMOTE_WRITE_HEADERS={"Authorization":"Basic <base64(user:api-key)>"}

# Grafana Cloud API for provisioning
GRAFANA_CLOUD_STACK=your-stack-name
GRAFANA_CLOUD_API_KEY=eyJrIjoi...
```

### 4. Base64 Encode Credentials
```bash
# User is the stack ID (number), password is the API key
echo -n "123456:eyJrIjoi..." | base64
# Use this in Authorization header
```

## Provisioning via API (Automated)

### Datasources
```bash
# Prometheus
curl -X POST \
  -H "Authorization: Bearer $GRAFANA_CLOUD_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"name":"Prometheus","type":"prometheus","url":"https://prometheus-prod-XX-prod-your-region.grafana.net/api/prom","access":"proxy","isDefault":true,"jsonData":{"httpHeaderName1":"Authorization","httpHeaderValue1":"Basic <base64>"}}' \
  "https://$GRAFANA_CLOUD_STACK.grafana.net/api/datasources"

# Loki
curl -X POST \
  -H "Authorization: Bearer $GRAFANA_CLOUD_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"name":"Loki","type":"loki","url":"https://logs-prod-XX-prod-your-region.grafana.net/loki","access":"proxy","jsonData":{"derivedFields":[{"name":"traceID","matcherRegex":"traceID=(\\w+)","url":"$${__value.raw}","datasourceUid":"tempo"}]}}' \
  "https://$GRAFANA_CLOUD_STACK.grafana.net/api/datasources"

# Tempo
curl -X POST \
  -H "Authorization: Bearer $GRAFANA_CLOUD_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"name":"Tempo","type":"tempo","url":"https://tempo-prod-XX-prod-your-region.grafana.net/tempo","access":"proxy","jsonData":{"tracesToLogs":{"datasourceUid":"loki","tags":["traceID"],"spanStartTimeShift":"-1h","spanEndTimeShift":"1h"}}}' \
  "https://$GRAFANA_CLOUD_STACK.grafana.net/api/datasources"
```

### Dashboards
```bash
curl -X POST \
  -H "Authorization: Bearer $GRAFANA_CLOUD_API_KEY" \
  -H "Content-Type: application/json" \
  -d @monitoring/grafana/dashboards/system-health.json \
  "https://$GRAFANA_CLOUD_STACK.grafana.net/api/dashboards/db"
```

### Alert Rules (Grafana Alerting)
```bash
# Convert Prometheus alerts to Grafana Alerting format
# Use monitoring/alerts.yml as reference
```

## Backend Code Changes

### Update instrumentation.ts for Grafana Cloud
```typescript
// Add to existing OTEL config
const traceExporter = new OTLPTraceExporter({
  url: process.env.OTEL_EXPORTER_OTLP_TRACES_ENDPOINT,
  headers: process.env.OTEL_EXPORTER_OTLP_TRACES_HEADERS
    ? JSON.parse(process.env.OTEL_EXPORTER_OTLP_TRACES_HEADERS)
    : {},
});

// Add metrics exporter for Prometheus remote write
import { PrometheusRemoteWriteExporter } from '@opentelemetry/exporter-prometheus-remote-write';
const metricsExporter = new PrometheusRemoteWriteExporter({
  url: process.env.PROMETHEUS_REMOTE_WRITE_URL,
  headers: process.env.PROMETHEUS_REMOTE_WRITE_HEADERS
    ? JSON.parse(process.env.PROMETHEUS_REMOTE_WRITE_HEADERS)
    : {},
});
```

### Add Logs Exporter (Loki)
```bash
npm install @opentelemetry/exporter-logs-otlp-http @opentelemetry/sdk-logs
```

```typescript
import { LoggerProvider, BatchLogRecordProcessor } from '@opentelemetry/sdk-logs';
import { OTLPLogExporter } from '@opentelemetry/exporter-logs-otlp-http';

const loggerProvider = new LoggerProvider({ resource });
loggerProvider.addLogRecordProcessor(new BatchLogRecordProcessor(new OTLPLogExporter({
  url: process.env.OTEL_EXPORTER_OTLP_LOGS_ENDPOINT,
  headers: process.env.OTEL_EXPORTER_OTLP_LOGS_HEADERS
    ? JSON.parse(process.env.OTEL_EXPORTER_OTLP_LOGS_HEADERS)
    : {},
})));
```

## Validation Checklist
- [ ] Backend `/metrics` returns 200 with metrics
- [ ] Traces appear in Grafana Cloud Tempo (Explore → Tempo)
- [ ] Logs appear in Grafana Cloud Loki (Explore → Loki)
- [ ] System Health dashboard loads with data
- [ ] Test alert fires and routes to Slack/PagerDuty
- [ ] Staging validated before production

## Cost Estimates (Free Tier)
| Component | Limit | GlowApp Estimate |
|-----------|-------|------------------|
| Metrics | 10k active series | ~2k series |
| Logs | 50 GB/month | ~5 GB/month |
| Traces | 50 GB/month | ~2 GB/month |
| Dashboards | Unlimited | 1 main + 2-3 aux |

## Rollback Plan
If Grafana Cloud has issues:
1. Revert backend env vars to local Prometheus/Loki/Tempo
2. Re-deploy monitoring stack to Railway (docker-compose)
3. Update DNS/endpoints accordingly