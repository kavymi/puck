# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 2.0.x   | ✅ Yes     |
| < 2.0   | ❌ No      |

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

If you discover a security vulnerability in Pluck, please report it by opening a [GitHub Security Advisory](../../security/advisories/new). This keeps the disclosure private until a fix is released.

### What to include

- A description of the vulnerability and its potential impact
- Steps to reproduce or a proof-of-concept
- The version of Pluck affected
- Your macOS version

### What to expect

- Acknowledgement within **72 hours**
- A fix or mitigation plan within **14 days** for critical issues
- Credit in the release notes if you wish

## Scope

Pluck is a macOS desktop application that spawns `yt-dlp` and `ffmpeg` as child processes. Security-relevant areas include:

- **Entitlements** — network access and file system permissions (`Pluck.entitlements`)
- **Process spawning** — arguments passed to `yt-dlp` / `ffmpeg` child processes
- **URL handling** — input validation of pasted or dropped URLs
- **File paths** — output directory selection and file write operations

## Out of Scope

- Vulnerabilities in `yt-dlp` or `ffmpeg` themselves — report those to their respective projects
- Issues requiring physical access to the machine
- Social engineering attacks
