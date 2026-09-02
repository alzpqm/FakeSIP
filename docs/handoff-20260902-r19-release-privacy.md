# FakeSIP r19 Release Privacy Handoff

Date: 2026-09-02 (Asia/Taipei)

## Publication Identity

- Git author and committer: `Codex <codex@local.invalid>`.
- Public repository: the existing pseudonymous fork.
- Planned tag: `v0.9.1-openwrt-r19`.
- Release notes and assets contain no router credentials or private API keys.

## Scan Boundary

The committed release snapshot, added diff lines, decoded Markdown, source, tests,
OpenWrt files, and package control metadata were scanned. Base64 handoffs were validated
by decoding and comparing them byte for byte with their Markdown sources.

The scan rejected these patterns:

- personal macOS account paths and usernames;
- laboratory IPv4 addresses, SSH aliases, and the nonstandard router SSH port;
- the known router password;
- private-key headers, GitHub token prefixes, Google API-key prefixes, bearer/basic
  authorization headers, credential URLs, and password assignments.

No matching secret or personal identifier remains in the release snapshot. Generic
RFC1918 examples and source-level private-network bypass ranges are product behavior and
were not treated as personal data.

## Artifact Metadata

The OpenWrt 25 APK metadata uses neutral package fields and root ownership. The first
OpenWrt 22.03 IPKs leaked an absolute Debian path through the generated `Source:` field;
those files were rejected. Final IPKs use only:

```text
Source: package/fakesip
Source: package/luci-app-fakesip
```

No release artifact control record contains an absolute build path, local account path,
or laboratory IP data.

## Residual History Note

Older public commits and tags previously contained local-path text in historical audit
documents. This release removes those identifiers from the tagged snapshot but does not
rewrite published Git history. Rewriting the fork history was outside this release and
would be disruptive to existing tags and users.

## External Review

Gemini CLI was requested after the public diff had been cleaned, but Code Assist OAuth
returned HTTP 403 before inference. No source review result was produced and no Gemini
approval is claimed.
