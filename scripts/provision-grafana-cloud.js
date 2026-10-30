#!/usr/bin/env node
/**
 * Grafana Cloud Provisioning Script
 * Provisions datasources, dashboards, and alert rules for GlowApp observability
 * 
 * Usage:
 *   GRAFANA_CLOUD_STACK=your-stack GRAFANA_CLOUD_API_KEY=your-key node scripts/provision-grafana-cloud.js
 * 
 * Required env vars:
 *   GRAFANA_CLOUD_STACK - Grafana Cloud stack slug (e.g., "glowapp-prod")
 *   GRAFANA_CLOUD_API_KEY - API key with Admin role
 *   PROMETHEUS_URL - Prometheus datasource URL (e.g., "https://prometheus-prod-xx-prod-us.grafana.net/api/prom")
 *   LOKI_URL - Loki datasource URL (e.g., "https://logs-prod-xx-prod-us.grafana.net/loki")
 *   TEMPO_URL - Tempo datasource URL (e.g., "https://tempo-prod-xx-prod-us.grafana.net/tempo")
 *   PROMETHEUS_USER - Prometheus user ID (stack ID number)
 *   PROMETHEUS_PASSWORD - API key (same as GRAFANA_CLOUD_API_KEY)
 */

const fs = require('fs');
const path = require('path');

const STACK = process.env.GRAFANA_CLOUD_STACK;
const API_KEY = process.env.GRAFANA_CLOUD_API_KEY;
const PROMETHEUS_URL = process.env.PROMETHEUS_URL;
const LOKI_URL = process.env.LOKI_URL;
const TEMPO_URL = process.env.TEMPO_URL;
const PROMETHEUS_USER = process.env.PROMETHEUS_USER;
const PROMETHEUS_PASSWORD = process.env.PROMETHEUS_PASSWORD; // Requerido: configurar en entorno

if (!STACK || !API_KEY || !PROMETHEUS_URL || !LOKI_URL || !TEMPO_URL || !PROMETHEUS_USER) {
  console.error('❌ Missing required environment variables:');
  console.error('  GRAFANA_CLOUD_STACK, GRAFANA_CLOUD_API_KEY, PROMETHEUS_URL, LOKI_URL, TEMPO_URL, PROMETHEUS_USER');
  process.exit(1);
}

const BASE_URL = `https://${STACK}.grafana.net`;
const AUTH_HEADER = `Bearer ${API_KEY}`;
const PROM_AUTH = Buffer.from(`${PROMETHEUS_USER}:${PROMETHEUS_PASSWORD}`).toString('base64');

async function request(method, endpoint, body = null) {
  const options = {
    method,
    headers: {
      'Authorization': AUTH_HEADER,
      'Content-Type': 'application/json',
    },
  };
  if (body) options.body = JSON.stringify(body);
  
  const response = await fetch(`${BASE_URL}${endpoint}`, options);
  const text = await response.text();
  
  if (!response.ok) {
    throw new Error(`${method} ${endpoint} failed: ${response.status} ${text}`);
  }
  
  return text ? JSON.parse(text) : {};
}

async function upsertDatasource(ds) {
  try {
    await request('POST', '/api/datasources', ds);
    console.log(`  ✅ ${ds.name} datasource created`);
  } catch (err) {
    if (err.message.includes('409') || err.message.includes('already exists')) {
      // Get existing and update
      const existing = await request('GET', `/api/datasources/name/${encodeURIComponent(ds.name)}`);
      await request('PUT', `/api/datasources/${existing.id}`, { ...ds, id: existing.id, uid: existing.uid, version: existing.version });
      console.log(`  ♻️ ${ds.name} datasource updated`);
    } else {
      throw err;
    }
  }
}

async function provisionDatasources() {
  console.log('📊 Provisioning datasources...');

  // Prometheus datasource
  await upsertDatasource({
    name: 'Prometheus',
    type: 'prometheus',
    url: PROMETHEUS_URL,
    access: 'proxy',
    isDefault: true,
    jsonData: {
      httpHeaderName1: 'Authorization',
      httpHeaderValue1: `Basic ${PROM_AUTH}`,
    },
  });

  // Loki datasource with traceID derived field
  await upsertDatasource({
    name: 'Loki',
    type: 'loki',
    url: LOKI_URL,
    access: 'proxy',
    jsonData: {
      derivedFields: [{
        name: 'traceID',
        matcherRegex: 'traceID=(\\w+)',
        url: '$${__value.raw}',
        datasourceUid: 'tempo',
      }],
      httpHeaderName1: 'Authorization',
      httpHeaderValue1: `Basic ${PROM_AUTH}`,
    },
  });

  // Tempo datasource with tracesToLogs
  await upsertDatasource({
    name: 'Tempo',
    type: 'tempo',
    url: TEMPO_URL,
    access: 'proxy',
    jsonData: {
      tracesToLogs: {
        datasourceUid: 'loki',
        tags: ['traceID'],
        spanStartTimeShift: '-1h',
        spanEndTimeShift: '1h',
      },
      httpHeaderName1: 'Authorization',
      httpHeaderValue1: `Basic ${PROM_AUTH}`,
    },
  });
}

async function provisionDashboard() {
  console.log('📈 Provisioning System Health dashboard...');

  const dashboardPath = path.join(__dirname, '../monitoring/grafana/dashboards/system-health.json');
  const fileContent = JSON.parse(fs.readFileSync(dashboardPath, 'utf8'));

  // File has { dashboard: {...}, overwrite: true } — extract the inner dashboard object
  const dashboard = fileContent.dashboard || fileContent;

  // Ensure dashboard has required fields for API
  const payload = {
    dashboard: {
      ...dashboard,
      id: null, // Let Grafana assign ID
      uid: 'glowapp-system-health',
      version: 1,
    },
    overwrite: true,
    message: 'Provisioned via script',
  };

  await request('POST', '/api/dashboards/db', payload);
  console.log('  ✅ System Health dashboard created/updated');
}

async function provisionAlertRules() {
  console.log('🚨 Provisioning alert rules...');
  
  // Note: Grafana Cloud uses Grafana Alerting (not Prometheus Alertmanager)
  // Alert rules need to be created via the Grafana Alerting API
  // This is a simplified version - full implementation would convert monitoring/alerts.yml
  
  const alertRules = [
    {
      title: 'HighErrorRate',
      condition: 'A',
      data: [{
        refId: 'A',
        relativeTimeRange: { from: 600, to: 0 },
        datasourceUid: 'prometheus',
        model: {
          expr: 'sum(rate(http_requests_total{status=~"5.."}[2m])) / sum(rate(http_requests_total[2m])) > 0.01',
          intervalMs: 10000,
          refId: 'A',
        },
      }],
      noDataState: 'NoData',
      execErrState: 'Error',
      for: '2m',
      annotations: {
        summary: 'High error rate detected (>1% 5xx)',
        runbook_url: 'https://github.com/Diegoromerov/belleza-app/blob/main/docs/runbooks/incident-response.md#1-high-error-rate',
      },
      labels: {
        severity: 'critical',
        team: 'backend',
      },
    },
    {
      title: 'HighLatency',
      condition: 'A',
      data: [{
        refId: 'A',
        relativeTimeRange: { from: 300000, to: 0 },
        datasourceUid: 'prometheus',
        model: {
          expr: 'histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le, route)) > 2',
          intervalMs: 10000,
          refId: 'A',
        },
      }],
      noDataState: 'NoData',
      execErrState: 'Error',
      for: '5m',
      annotations: {
        summary: 'High latency detected (P95 > 2s)',
        runbook_url: 'https://github.com/Diegoromerov/belleza-app/blob/main/docs/runbooks/incident-response.md#2-high-latency',
      },
      labels: {
        severity: 'warning',
        team: 'backend',
      },
    },
    {
      title: 'DBPoolExhausted',
      condition: 'A',
      data: [{
        refId: 'A',
        relativeTimeRange: { from: 300000, to: 0 },
        datasourceUid: 'prometheus',
        model: {
          expr: 'db_pool_connections{state="active"} / db_pool_connections{state="idle"} > 0.8',
          intervalMs: 10000,
          refId: 'A',
        },
      }],
      noDataState: 'NoData',
      execErrState: 'Error',
      for: '5m',
      annotations: {
        summary: 'Database connection pool exhausted (>80%)',
        runbook_url: 'https://github.com/Diegoromerov/belleza-app/blob/main/docs/runbooks/incident-response.md#3-db-pool-exhausted',
      },
      labels: {
        severity: 'critical',
        team: 'backend',
      },
    },
    {
      title: 'HostingDown',
      condition: 'A',
      data: [{
        refId: 'A',
        relativeTimeRange: { from: 60000, to: 0 },
        datasourceUid: 'prometheus',
        model: {
          expr: 'up{job="glowapp-backend"} == 0',
          intervalMs: 10000,
          refId: 'A',
        },
      }],
      noDataState: 'NoData',
      execErrState: 'Error',
      for: '1m',
      annotations: {
        summary: 'Backend service is down',
        runbook_url: 'https://github.com/Diegoromerov/belleza-app/blob/main/docs/runbooks/incident-response.md#5-deploy-rollback',
      },
      labels: {
        severity: 'critical',
        team: 'backend',
      },
    },
  ];
  
  for (const rule of alertRules) {
    try {
      await request('POST', '/api/v1/provisioning/alert-rules', rule);
      console.log(`  ✅ Alert rule created: ${rule.title}`);
    } catch (err) {
      if (err.message.includes('409') || err.message.includes('already exists')) {
        console.log(`  ⚠️ Alert rule already exists: ${rule.title}`);
      } else {
        console.error(`  ❌ Failed to create alert rule ${rule.title}:`, err.message);
      }
    }
  }
}

async function testAlerting() {
  console.log('🧪 Testing alert notification...');
  
  try {
    await request('POST', '/api/v1/alerts', {
      receiver: 'test',
      alerts: [{
        labels: {
          alertname: 'TestAlert',
          severity: 'info',
        },
        annotations: {
          summary: 'Test alert from GlowApp provisioning script',
        },
      }],
    });
    console.log('  ✅ Test alert sent');
  } catch (err) {
    console.error('  ❌ Test alert failed:', err.message);
  }
}

async function main() {
  console.log(`🚀 Provisioning Grafana Cloud stack: ${STACK}`);
  console.log(`   Base URL: ${BASE_URL}`);
  console.log('');
  
  try {
    await provisionDatasources();
    await provisionDashboard();
    await provisionAlertRules();
    await testAlerting();
    
    console.log('');
    console.log('✅ Grafana Cloud provisioning complete!');
    console.log(`🔗 Dashboard: ${BASE_URL}/d/glowapp-system-health`);
    console.log(`🔗 Explore: ${BASE_URL}/explore`);
  } catch (err) {
    console.error('❌ Provisioning failed:', err.message);
    process.exit(1);
  }
}

main();