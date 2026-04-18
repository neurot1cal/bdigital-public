# Security Policy

## Supported versions

This repository hosts code samples rather than a versioned library. All
samples on the `main` branch are treated as current. Historical commits are
not patched; always pull from `main` for the latest material.

## Reporting a vulnerability

If you discover a vulnerability in any sample, workflow, or site asset in this
repository, please report it privately rather than opening a public issue.

- Use the GitHub "Report a vulnerability" button on the repository's Security
  tab to open a private security advisory.
- Alternatively, open a GitHub issue titled "security disclosure" with no
  sensitive details in the body and request a private channel.

Please include:

- The file path or workflow name where the issue appears.
- A short description of the impact.
- A minimal reproduction if the issue is exploitable in the sample as written.

Do not include exploit code, sensitive credentials, or details that would put
third parties at risk in the public-facing report. Maintainers will respond
within a reasonable timeframe and coordinate disclosure from there.

## Scope

In scope:

- Workflow files under `.github/workflows/` that could execute untrusted input
  or leak secrets.
- Sample scripts under `samples/` that mishandle user input or escalate
  privileges beyond what the sample is meant to demonstrate.
- Site assets under `site/` that could enable XSS, open redirects, or
  injection on the deployed landing page.

Out of scope:

- Findings in external dependencies. Please report those upstream.
- Hypothetical risks without a reproduction path in this repository.
- Configuration issues that require altering the sample beyond its published
  form.

## Hardening notes for downstream users

Samples in this repository are intended as starting points, not production
hardened systems. When adapting a sample into your own environment, review
the relevant blog post for the threat model and hygiene notes specific to
that sample (secrets management, permission scoping, network egress, and so
on).
