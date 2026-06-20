# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it responsibly.

### How to Report

1. **Do NOT** open a public GitHub issue for security vulnerabilities
2. Email the maintainer directly at: **malek.m.edresi@gmail.com**
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

### Response Timeline

- **Acknowledgment**: Within 48 hours
- **Initial Assessment**: Within 1 week
- **Fix Release**: Within 2 weeks for critical issues

### Security Best Practices for Users

When deploying this integration:

1. **Never commit `.env` files** — Use `.env.example` as a template
2. **Use Oracle Wallet** or **APEX Web Credentials** for production credential storage
3. **Restrict ACL grants** — Only grant network access to schemas that need it
4. **Use HTTPS** in production — Configure SSL/TLS for JasperReports Server
5. **Apply least privilege** — The `JASPER_REPORT_USER` should have SELECT-only access
6. **Enable Unified Auditing** — Monitor JasperReports database access
7. **Rotate passwords** regularly — Use the `JASPER_REPORTING_PROFILE` password policies
8. **Keep Docker images updated** — Regularly pull latest security patches

## Scope

This security policy covers:

- PL/SQL packages and procedures
- SQL scripts (DDL, DML, ACL)
- Docker Compose configurations
- Shell scripts
- Documentation accuracy

This policy does **NOT** cover:

- Oracle Database security (refer to Oracle's security guides)
- JasperReports Server vulnerabilities (refer to TIBCO/Jaspersoft)
- Third-party Docker images (Oracle, Bitnami)
