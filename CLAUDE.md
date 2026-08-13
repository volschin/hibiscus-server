# hibiscus-server packaging repository notes

This repository packages the upstream Hibiscus Server banking application; it is
not the application source. The Dockerfile downloads the upstream release and
MariaDB JDBC driver, then builds a distroless Java 21 image. A Node ESM scraper
updates `release-version` from the upstream changelog.

## Commands

```bash
npm install
npm run get-version
docker build --build-arg HIBISCUS_VERSION="$(cat release-version)" -t hibiscus-server .
```

There is no test suite; `npm test` intentionally fails and is not a validation
command.

## Release invariants

- `release-version` is one line without a trailing newline. Verify that it
  actually changes after scraper edits.
- The daily workflow commits and tags a discovered version. Tags pushed with the
  default `GITHUB_TOKEN` do not trigger the image workflow because of GitHub's
  recursion guard; new version images currently require `workflow_dispatch` on
  the tag.
- Image builds pass `release-version` as `HIBISCUS_VERSION`; the Dockerfile
  default is only a fallback.
- Keep multi-arch publication and Cosign OIDC signing intact.
- The MariaDB JDBC URL is pinned directly in the Dockerfile and must be changed
  there deliberately.
- Runtime expects the Jameica master password at
  `/run/secrets/hibiscus-pwd`; never bake it into the image or Compose file.

After workflow changes, verify the complete tag-to-image path rather than only
YAML syntax.
