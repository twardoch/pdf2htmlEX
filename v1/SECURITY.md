# Security Policy

## Supported Versions

We take security seriously and aim to promptly address any security vulnerabilities in the pdf2htmlEX Homebrew formula.

| Version | Supported          |
| ------- | ------------------ |
| latest  | :white_check_mark: |

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please report security vulnerabilities by emailing the maintainers directly. If you cannot find contact information in the repository, create a private security advisory:

1. Go to the Security tab of this repository
2. Click on "Report a vulnerability"
3. Fill in the details of the vulnerability

### What to Include

Please include the following information:

- Type of issue (e.g., buffer overflow, privilege escalation, arbitrary code execution)
- Full paths of source file(s) related to the issue
- The location of the affected source code (tag/branch/commit or direct URL)
- Any special configuration required to reproduce the issue
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if possible)
- Impact of the issue, including how an attacker might exploit it

## Response Timeline

- **Initial Response**: Within 48 hours
- **Status Update**: Within 7 days
- **Resolution Target**: 
  - Critical: Within 7 days
  - High: Within 14 days
  - Medium: Within 30 days
  - Low: Within 60 days

## Security Considerations

### Build Security

The formula implements several security measures:

1. **Static Linking**: Reduces runtime dependency vulnerabilities
2. **Compiler Flags**: Uses security-hardening flags like `-fstack-protector-strong`
3. **HTTPS Only**: All downloads use HTTPS with SHA256 verification
4. **Sandboxed Build**: Homebrew's sandboxed build environment

### Known Security Considerations

1. **PDF Processing**: pdf2htmlEX processes potentially untrusted PDF files. Users should:
   - Only process PDFs from trusted sources
   - Run pdf2htmlEX with minimal privileges
   - Consider using sandboxing for untrusted PDFs

2. **Dependencies**: The formula depends on:
   - Poppler: Check [Poppler security](https://gitlab.freedesktop.org/poppler/poppler/-/issues)
   - FontForge: Check [FontForge security](https://github.com/fontforge/fontforge/security)

### Security Best Practices for Users

1. **Keep Updated**: Regularly update the formula
   ```bash
   brew update && brew upgrade pdf2htmlex
   ```

2. **Verify Installation**: Check formula integrity
   ```bash
   brew audit --strict pdf2htmlex
   ```

3. **Minimal Privileges**: Run pdf2htmlEX with minimal privileges
   ```bash
   # Create a restricted user for PDF processing
   sudo dscl . -create /Users/pdfprocessor
   sudo -u pdfprocessor pdf2htmlEX untrusted.pdf
   ```

4. **Sandbox Usage**: Use macOS sandbox for additional protection
   ```bash
   sandbox-exec -f pdf2htmlex.sb pdf2htmlEX input.pdf
   ```

## Security Updates

Security updates will be released as new formula revisions. To receive security notifications:

1. Watch this repository
2. Enable GitHub security alerts
3. Subscribe to release notifications

## Vulnerability Disclosure

We follow responsible disclosure:

1. Security issues are embargoed until a fix is available
2. We coordinate with upstream projects when needed
3. Public disclosure happens after patches are available

## Contact

For security-related questions that don't need to be private, use the Security Discussions section of this repository.