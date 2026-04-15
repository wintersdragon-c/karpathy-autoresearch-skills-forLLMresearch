# Security Policy

## Reporting a Vulnerability

Please do not open a public issue for security-sensitive problems.

Instead, report the issue privately to the maintainer or repository owner and include:

- affected files or skills
- reproduction steps
- impact assessment
- any suggested mitigation

You should receive an acknowledgment after the report is reviewed. Until a fix is available, please avoid public disclosure.

## Scope

This repository primarily contains skill prompts, templates, and test harnesses. The most likely security-relevant issues are:

- unsafe shell instructions in skill prompts
- path handling mistakes in tests or templates
- installation instructions that encourage insecure local setup
- accidental disclosure of secrets in example commands or fixtures
