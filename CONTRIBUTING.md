# Contributing to Oracle APEX + JasperReports Integration

Thank you for your interest in contributing! This project welcomes contributions from Oracle APEX developers, PL/SQL engineers, and the open-source community.

## How to Contribute

### Reporting Bugs

1. Check [existing issues](../../issues) to avoid duplicates
2. Open a new issue with:
   - Oracle Database version (23ai, 26ai)
   - Oracle APEX version (24.2, 26.1)
   - JasperReports Server version
   - Steps to reproduce
   - Error messages (ORA codes, HTTP status codes)
   - Expected vs actual behavior

### Suggesting Features

1. Open an issue with the `enhancement` label
2. Describe the use case and expected behavior
3. Include code examples if possible

### Submitting Code

1. **Fork** the repository
2. **Create a feature branch**: `git checkout -b feature/my-feature`
3. **Make your changes** following the coding standards below
4. **Test your changes** against an Oracle Database
5. **Commit**: `git commit -m "feat: add my feature"`
6. **Push**: `git push origin feature/my-feature`
7. **Open a Pull Request** with a clear description

## Coding Standards

### PL/SQL

- Use **UPPERCASE** for Oracle keywords (`SELECT`, `BEGIN`, `CREATE`)
- Use **lowercase** for variable names with `v_` prefix (`v_report_url`)
- Use **lowercase** for parameter names with `p_` prefix (`p_settings_id`)
- Use **gc_** prefix for package constants (`gc_version`)
- Add comments for every procedure and function
- Use `AUTHID CURRENT_USER` for packages that support multi-tenant schemas
- Always include proper exception handling
- Use `PRAGMA AUTONOMOUS_TRANSACTION` for logging procedures

### SQL Scripts

- Include header comments with purpose, usage, and prerequisites
- Use `SET SERVEROUTPUT ON` for scripts that produce output
- Use `WHENEVER SQLERROR CONTINUE` for idempotent scripts
- Use Oracle substitution variables (`&VARIABLE`) instead of hardcoded values

### Shell Scripts

- Use `set -euo pipefail` for safety
- Include usage comments in the header
- Use environment variables with sensible defaults
- Never hardcode passwords

### Documentation

- Write in clear, beginner-friendly English
- Include code examples for every concept
- Use proper Markdown formatting
- Keep the table of contents updated

## Commit Message Format

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add Excel export support to GET_REPORT
fix: handle null parameters in URL construction
docs: add ACL troubleshooting guide
chore: update Docker Compose to latest images
```

## Development Setup

1. Clone the repository
2. Set up the Docker environment (see [Installation Guide](docs/installation-guide.md))
3. Run the install scripts
4. Make your changes
5. Test against a running Oracle Database + JasperReports Server

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you agree to uphold this code.

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
