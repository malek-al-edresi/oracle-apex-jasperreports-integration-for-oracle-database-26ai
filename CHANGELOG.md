# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-06-21

### Added

- **JASPER_REPORT_PKG** — Core PL/SQL package for JasperReports integration
  - `GET_REPORT` procedure with multi-tenant schema support
  - `GET_REPORT_URL` utility function for URL debugging
  - `TEST_CONNECTION` procedure for connectivity verification
  - Configurable protocol (HTTP/HTTPS)
  - Dynamic MIME type resolution via `FILE_TYPE_LOOKUP` table
  - Structured error logging via `REPORT_ERROR_LOG_PKG`

- **REPORT_ERROR_LOG_PKG** — Autonomous transaction error logging
  - `LOG_ERROR`, `LOG_WARNING`, `LOG_INFO` procedures
  - APEX session context capture
  - Log purge capability

- **Database Tables**
  - `REPORT_SETTINGS` — Server connection configuration
  - `REPORT_CONFIG` — Individual report definitions
  - `REPORT_LOG` — Audit trail and error log
  - `FILE_TYPE_LOOKUP` — Supported output formats with MIME types

- **Security & ACL Scripts**
  - Network ACL grants (`DBMS_NETWORK_ACL_ADMIN`)
  - JasperReports database profile, roles, and users
  - Audit policies for reporting activity
  - Multi-tenant grant synchronization

- **Docker Deployment**
  - Complete `docker-compose.yml` with Oracle DB 26ai, ORDS, JasperReports, MariaDB
  - Environment variable configuration (`.env.example`)
  - Health check scripts

- **JasperReports Templates**
  - Patient Profile Report (`patient_report.jrxml`)
  - Invoice Report (`invoice_report.jrxml`)
  - Employee Directory Report (`employee_report.jrxml`)
  - Oracle datasource configuration

- **Documentation**
  - Architecture guide with diagrams
  - Step-by-step installation guide
  - ACL configuration guide
  - Network configuration guide
  - JasperReports Server setup guide
  - Database tables documentation
  - PL/SQL API reference
  - Error handling guide
  - Security best practices
  - Troubleshooting guide
  - DevOps guide

- **Examples**
  - Patient report generation example
  - Invoice report generation example
  - Employee report generation example

- **GitHub Community Files**
  - README.md, CONTRIBUTING.md, LICENSE (MIT)
  - SECURITY.md, CODE_OF_CONDUCT.md
  - .gitignore for Oracle/APEX/Docker projects
