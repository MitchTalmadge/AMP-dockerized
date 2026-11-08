# Container packaging design

This is an experimental staging redesign, not a verified Unraid release.

## AMP 2 comparison

The upstream AMP 2 Dockerfile downloads and extracts the instance-manager package rather than running its maintainer scripts. This image applies that packaging approach to the official AMP 3 panel and system-agent packages. APT authenticates repository metadata and package hashes. The image does not register extracted AMP packages as installed in dpkg; AMP package updates belong to rebuilt images, alongside AMP's application update mechanism.

The repository signing key is obtained over HTTPS from the configured official repository. Its trust is the same repository trust used by the vendor installer; it is not an independently pinned signing-key fingerprint.

## Why systemd and cgroups remain

The official amp3 3.0.0 package includes the documentation files packaging-and-containers.md and per-shard-identity.md. The latter describes native game servers as systemd transient services launched through systemd-run. Without that facility the native platform refuses launches with native.noSystemd. The system agent also uses transient root units to create accounts and apply permissions.

Cgroups provide the process boundary for these services. Removing systemd merely because the panel can start without it would leave native game launching incomplete. The host cgroup namespace and writable /sys/fs/cgroup mount remain in the examples because this pairing resolved the observed Unraid /init.scope path error. A private cgroup namespace with delegated writable cgroups may be possible on other hosts, but has not been validated here.

The existing SYS_ADMIN, NET_ADMIN and AppArmor options remain pending runtime verification. Their minimum necessary scope has not been established. Console logging defaults move into the image; a TTY remains for the observed systemd console behavior. The image supplies its stop signal, so examples do not repeat it.

## Hardlink setting and ownership

The official AMP package post-install scripts refuse to hand files to amp as root when fs.protected_hardlinks is zero. This guards ownership operations on files in an unprivileged user's directory. The redesign does not falsify the setting, edit the installer check, or change the host sysctl.

Instead, packages are extracted into the image's root-owned application paths at build time. At startup prepare-data.py opens directory descriptors without following symlinks and changes only directory ownership. It never recursively chowns regular files in the persistent data directory. seed-data.py runs as amp, so seed files and settings start with their intended owner. The system-agent ledger remains root-owned with mode 0700. The vendor system-agent binary and service sandbox are retained.

This replaces installer responsibilities; it does not prove that every AMP runtime feature works with the host setting unchanged. Existing data files with incompatible ownership are not automatically repaired. Incomplete or blacklisted versions are preserved and cause an initialization error rather than automatic deletion.

## Package evidence

The inspected preview repository index was https://cdn-repo.c7rs.com/amp3/deb/dists/preview/main/binary-amd64/Packages. Package payloads and maintainer scripts were downloaded from that official repository and inspected locally.

| Package | Version | SHA-256 of inspected artifact |
|---|---|---|
| amp3 | 3.0.0 | 913a2435c6503ff908abab837fda06b5e13a1859f33fe0105994f695a5aa1515 |
| amp3-sysagent | 3.0.0 | 9262f022ab5a1df58e89430c2068255a4022c2a4503182d9ca1e0b06ad66f9d0 |

These hashes identify the reviewed artifacts; builds resolve the selected stream's current packages. CI refreshes the package extraction layer for each run attempt.

## Validation still required

Before production publication, build an amd64 staging image and check first startup, panel setup, system-agent readiness, a real native game-server launch and stop, container restart, and recreation against retained test data. Run those checks on the affected Unraid host with its hardlink setting unchanged. Check service sandbox failures and permissions in the journal. Also exercise changed panel ports and existing data, including interrupted seeds. Keep a backup and use a separate test directory.

Static syntax and configuration checks cannot establish Unraid runtime compatibility. Production tags and the public repository must not be updated without the owner's approval.

Local checks completed: Bash syntax for all shell entrypoints/examples, Python AST syntax for both initialization helpers, Unraid XML parsing, and git diff --check. Docker Compose validation could not run because this environment lacks the Compose CLI plugin. No image build or runtime test has been performed.
