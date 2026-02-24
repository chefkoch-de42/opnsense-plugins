# Build, Release & Contributing Guide

This document explains how the CI/CD pipeline works, how to create releases,
and how to add new plugins to this repository.

---

## Table of contents

1. [Repository layout](#repository-layout)
2. [How the build pipeline works](#how-the-build-pipeline-works)
3. [Day-to-day development (push to master)](#day-to-day-development-push-to-master)
4. [Creating a release](#creating-a-release)
5. [Adding a new plugin](#adding-a-new-plugin)
6. [Plugin Makefile reference](#plugin-makefile-reference)
7. [Local development tips](#local-development-tips)

---

## Repository layout

```
opnsense-plugins/
├── .github/
│   └── workflows/
│       └── build-pkg.yml       ← single workflow for build, publish & release
├── README.md                   ← repo index (user-facing)
├── CONTRIBUTING.md             ← this file
└── <category>/                 ← FreeBSD port category, e.g. sysutils, net
    └── <plugin-name>/
        ├── Makefile            ← declares PLUGIN_NAME, PLUGIN_VERSION, …
        ├── pkg-descr           ← shown by `pkg info <name>`
        ├── README.md           ← full plugin documentation
        └── src/                ← files installed under /usr/local/
            └── …
```

Any directory that contains a `Makefile` with a `PLUGIN_NAME` variable is
picked up automatically by the workflow — no changes to the workflow are
needed when you add a new plugin.

---

## How the build pipeline works

The workflow (`.github/workflows/build-pkg.yml`) has four jobs:

```
┌───────────┐
│  discover │  Scans for all plugins (or just the tagged one on a tag push)
└─────┬─────┘
      │  matrix
      ▼
┌───────────┐
│   build   │  Builds one FreeBSD .pkg per plugin in parallel
│           │  • runs inside a FreeBSD 14.3 VM (vmactions/freebsd-vm)
│           │  • ABI: FreeBSD:14:amd64  (matches OPNsense 26.x)
└─────┬─────┘
      │  artifacts
      ▼
┌───────────┐
│  publish  │  Runs `pkg repo` to build the packagesite index,
│           │  then pushes everything to the gh-pages branch →
│           │  https://chefkoch-de42.github.io/opnsense-plugins/
└─────┬─────┘
      │  only on tag push
      ▼
┌───────────┐
│  release  │  Creates a GitHub Release with the .pkg file as a
│           │  downloadable asset  (skipped on normal branch pushes)
└───────────┘
```

### Triggers

| Event | Jobs that run | Release created? |
|---|---|---|
| Push to `master` | discover → build → publish | No |
| `workflow_dispatch` (manual) | discover → build → publish | No |
| Push of tag `os-<name>/<version>` | discover → build → publish → **release** | **Yes** |

---

## Day-to-day development (push to master)

Normal code changes are simply committed and pushed to `master`.
The workflow will build all plugins and update the GitHub Pages pkg repo
automatically. No release is created.

```sh
# make your changes …
git add .
git commit -m "fix: improve wancarp hook error handling"
git push
```

The updated packages are live on GitHub Pages within ~5 minutes.

---

## Creating a release

A release is triggered by pushing a **Git tag** in the format:

```
os-<plugin-name>/<version>
```

### Step-by-step

**1. Update the version in the plugin Makefile**

```sh
# sysutils/os-wancarp/Makefile
PLUGIN_VERSION=   0.0.2
```

**2. Update the changelog in `pkg-descr`**

```
0.0.2

* describe what changed
```

**3. Commit and push to master first**

```sh
git add sysutils/os-wancarp/Makefile sysutils/os-wancarp/pkg-descr
git commit -m "chore: bump os-wancarp to 0.0.2"
git push
```

**4. Create and push the tag**

```sh
git tag -a "os-wancarp/0.0.2" -m "os-wancarp 0.0.2 – short description"
git push origin "os-wancarp/0.0.2"
```

### What happens automatically

1. The `discover` job detects the tag format and selects **only** the
   `os-wancarp` plugin for the build matrix.
2. The `build` job compiles `os-wancarp-0.0.2.pkg` on FreeBSD 14.3.
3. The `publish` job updates the GitHub Pages pkg repo — OPNsense systems
   running `pkg update` will see the new version immediately.
4. The `release` job creates a GitHub Release named `os-wancarp/0.0.2` with:
   - The `.pkg` file attached as a downloadable asset
   - Installation instructions in the release body

### Viewing releases

```
https://github.com/chefkoch-de42/opnsense-plugins/releases
```

### Installing a specific version directly (without the repo)

```sh
# Download the .pkg from the GitHub Release assets page and install:
pkg add https://github.com/chefkoch-de42/opnsense-plugins/releases/download/os-wancarp%2F0.0.2/os-wancarp-0.0.2.pkg
```

---

## Adding a new plugin

1. **Create the directory structure:**

   ```
   <category>/os-<name>/
   ├── Makefile
   ├── pkg-descr
   ├── README.md
   └── src/
       └── … (files to install under /usr/local/)
   ```

2. **Write the Makefile** (see [reference below](#plugin-makefile-reference)).

3. **Commit and push** — the workflow discovers the new plugin automatically.

4. **Add a row** to the plugin table in the root `README.md`:

   ```markdown
   | [os-myplugin](sysutils/os-myplugin/) | Short description | [README](sysutils/os-myplugin/README.md) |
   ```

5. **Create the first release tag** when ready:

   ```sh
   git tag -a "os-myplugin/0.0.1" -m "os-myplugin 0.0.1 – initial release"
   git push origin "os-myplugin/0.0.1"
   ```

---

## Plugin Makefile reference

```makefile
PLUGIN_NAME=        myplugin          # short name, no spaces (directory must be os-<name>)
PLUGIN_VERSION=     0.0.1             # semver: MAJOR.MINOR.PATCH
PLUGIN_COMMENT=     My plugin summary # one-line description (shown in pkg search)
PLUGIN_MAINTAINER=  you@example.com
PLUGIN_WWW=         https://github.com/chefkoch-de42/opnsense-plugins
```

| Variable | Required | Description |
|---|---|---|
| `PLUGIN_NAME` | ✅ | Identifier used by the workflow to match tags. Must equal the directory name without the `os-` prefix. |
| `PLUGIN_VERSION` | ✅ | Semantic version. Must match the version in the Git tag when releasing. |
| `PLUGIN_COMMENT` | ✅ | One-line description shown in `pkg search` and on the Pages landing page. |
| `PLUGIN_MAINTAINER` | optional | Contact e-mail. Defaults to the GitHub actor. |
| `PLUGIN_WWW` | optional | URL shown in `pkg info`. |

---

## Local development tips

**Validate YAML syntax of the workflow locally:**

```sh
source .venv/bin/activate
pip install pyyaml
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/build-pkg.yml')); print('OK')"
```

**Check the current published pkg repo:**

```sh
# List all packages in the repo
curl -s https://chefkoch-de42.github.io/opnsense-plugins/packages/packagesite.pkg \
  | tar xOf - packagesite.yaml \
  | python3 -c "import sys,json; [print(json.loads(l)['name'], json.loads(l)['version'], json.loads(l)['abi']) for l in sys.stdin]"
```

**Verify the repo config is valid UCL:**

```sh
curl -s https://chefkoch-de42.github.io/opnsense-plugins/packages/opnsense-plugins.conf
```

**Re-run the workflow manually** (without pushing code):

```sh
gh workflow run build-pkg.yml --repo chefkoch-de42/opnsense-plugins
```

**Watch a running workflow:**

```sh
gh run watch --repo chefkoch-de42/opnsense-plugins
```

**List all releases:**

```sh
gh release list --repo chefkoch-de42/opnsense-plugins
```

