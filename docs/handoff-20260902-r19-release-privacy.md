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

## 2026-09-05 r20 Privacy Addendum

The r20 APK and IPK contents were extracted into fresh Debian directories before router
installation. All packaged owners/groups are root/root. The config is mode 0600, the
binary and init script are 0755, and LuCI/menu/ACL files are 0644. Content scans found no
personal macOS path, build-host home path, lab login alias, router credential, cloud
project identifier, private-key header, or known personal identifier.

The IPK controls use only neutral source fields:

```text
Source: package/fakesip
Source: package/luci-app-fakesip
```

Gemini CLI 0.53.0 was requested with the authorized project environment selection, but
Code Assist returned HTTP 403 before inference because no valid product license was
available. No Gemini approval is claimed for r20. Executable tests, direct source and
artifact inspection, and live OpenWrt evidence remain the acceptance basis.

The committed r20 tag snapshot passed the same targeted credential and personal-endpoint
scan immediately before push. The anonymous annotated tag was verified from the remote.
GitHub's asset digests matched local artifacts, and a fresh download passed the published
checksum file. Release notes contain no credential, private endpoint, or personal path.

Default-branch integration also avoided GitHub's server-generated merge path because a
prior merge demonstrated that it would attach an account-linked personal email. Pull
request 7 was instead completed by pushing a local ordinary merge whose author and
committer are both `Codex <codex@local.invalid>`.

## 2026-09-06 r21 Privacy Addendum

The r21 release boundary contains only two OpenWrt 25+ APKs and `SHA256SUMS`; no IPK is
published. APK metadata and extracted contents were scanned for credentials, personal
paths, jump-host aliases, private router endpoints, cloud project identifiers, private
keys, and account tokens. All packaged files are root-owned and no matching private
identifier was found.

The new English and Traditional Chinese public documentation uses only the generic
example router address `192.168.1.1`. The real router backup remains private on router,
Debian, and local backup storage and is not a release asset. Newly added handoff text was
redacted to avoid recording the actual SSH endpoint.

Both r21 commits use `Codex <codex@local.invalid>` for author and committer. Gemini was
requested once, but Code Assist returned HTTP 403 before inference and the workspace was
not trusted; no Gemini approval is claimed. Release acceptance relies on executable
tests, artifact inspection, and live OpenWrt evidence.
