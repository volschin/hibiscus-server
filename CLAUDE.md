# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

This is **not** the Hibiscus Server application — it is the packaging/release automation that builds a Docker image of the upstream [Hibiscus Server](https://www.willuhn.de/products/hibiscus-server/) (a German Java banking/HBCI app by willuhn). The published image lives at `ghcr.io/volschin/hibiscus-server`.

The repo has two moving parts:
1. A multi-stage **Dockerfile** that downloads an upstream release zip + the MariaDB JDBC connector and packages them onto a distroless Java 21 base.
2. A Node ESM script (`get-version-from-changelog.js`) that scrapes the upstream changelog to discover the latest released version.

## Commands

```bash
npm install                 # install xmldom + xpath deps
npm run get-version         # scrape upstream changelog, write latest version to ./release-version

# build the image locally (release-version holds the version string, no newline)
docker build --build-arg HIBISCUS_VERSION=$(cat release-version) -t hibiscus-server .
```

There is no test suite — `npm test` is a placeholder that exits 1.

## Release automation (how a new version ships)

The version lifecycle is driven entirely by GitHub Actions; understanding the chain matters before touching any workflow:

1. **`.github/workflows/get-releases.yml`** (daily cron `0 11 * * *`): runs `npm run get-version`, which writes the scraped version into the `release-version` file, then auto-commits it as `Release version X.Y.Z` **and creates git tag `vX.Y.Z`**.
2. **`.github/workflows/docker-image.yml`** triggers on **tag `v**`** (and on `Dockerfile` changes / PRs). It reads `release-version`, builds with `HIBISCUS_VERSION` build-arg, pushes multi-tag to GHCR (`docker/metadata-action` → semver + sha tags), and **signs each image with Cosign** via GitHub OIDC.
3. **`.github/workflows/trivy.yml`** (weekly cron): scans the published `:main` image for CRITICAL/HIGH CVEs, uploads SARIF to the Security tab.

Gotcha: the `release-version` path trigger in `docker-image.yml` is **commented out**, so a bare commit to `release-version` does *not* rebuild the image — only the `vX.Y.Z` tag that `get-releases.yml` pushes alongside it does. If you bump the version by hand, push a matching `v` tag or the image won't build.

## Key details

- `release-version` is a single line with **no trailing newline** — the build-arg and `$GITHUB_ENV` step depend on `cat` returning exactly the version.
- The Dockerfile's `ARG HIBISCUS_VERSION` default (e.g. `2.10.24`) is a fallback; real builds always pass the build-arg from `release-version`, so the default is usually stale.
- The MariaDB JDBC connector is pinned by a hard-coded URL in the Dockerfile (`ADD https://dlm.mariadb.com/.../mariadb-java-client-*.jar`); bumping it means editing that line directly.
- Runtime config: the container expects the Jameica master password mounted at `/run/secrets/hibiscus-pwd` (see `CMD`); `example/compose.yaml` shows the full stack (Hibiscus + MariaDB + Traefik routing).
- `get-version-from-changelog.js` parses the upstream HTML changelog via XPath `//pre/text()`; if upstream changes that page's markup, the scrape silently breaks — verify `release-version` actually updated after changes.
- Dependency updates are automated via Renovate (`.github/renovate.json5`, extends a shared external config).
