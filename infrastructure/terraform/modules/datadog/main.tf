terraform {
  required_providers {
    datadog = {
      source  = "DataDog/datadog"
      version = "~> 3.0"
    }
  }
}

resource "datadog_dashboard" "ecommerce_overview" {
  title       = "E-commerce Platform Overview"
  description = "Comprehensive monitoring dashboard"
  layout_type = "ordered"

  widget {
    servicemap_definition {
      service = "user-service"
      filters = ["env:${var.environment}"]
      title   = "Service Map"
    }
  }

  widget {
    timeseries_definition {
      title = "Request Rate"
      request {
        q = "sum:trace.http.request.hits{env:${var.environment}} by {service}.as_rate()"
        display_type = "line"
      }
    }
  }
}

resource "datadog_monitor" "high_error_rate" {
  name    = "High Error Rate - ${var.environment}"
  type    = "metric alert"
  message = "Service has high error rate @slack-alerts"
  
  query = "avg(last_5m):sum:trace.http.request.errors{env:${var.environment}} by {service}.as_rate() > 0.05"
  
  monitor_thresholds {
    critical = 0.05
    warning  = 0.02
  }

  tags = ["env:${var.environment}", "team:platform"]
}