# opnsense-plugins

Community OPNsense plugin repository – hosted as a FreeBSD pkg repo via
GitHub Pages.

---

## Available plugins

| Plugin | Description | Documentation |
|--------|-------------|---------------|
| [os-wancarp](sysutils/os-wancarp/) | Automatically enables/disables a WAN interface on CARP master/backup transitions (single-WAN HA setup) | [README](sysutils/os-wancarp/README.md) |

---

## Add this repository to OPNsense

```sh
fetch -o /usr/local/etc/pkg/repos/opnsense-plugins.conf \
  https://chefkoch-de42.github.io/opnsense-plugins/packages/opnsense-plugins.conf

pkg update
```

Or add it in the GUI under **System → Firmware → Plugins → Add repository**:

```
https://chefkoch-de42.github.io/opnsense-plugins/packages
```

---

## Repository layout

```
opnsense-plugins/
├── .github/workflows/build-pkg.yml   ← build & publish on every push to master
├── README.md                         ← this file
└── <category>/
    └── <plugin-name>/
        ├── Makefile                  ← PLUGIN_NAME, PLUGIN_VERSION, …
        ├── pkg-descr                 ← shown by `pkg info`
        ├── README.md                 ← full documentation
        └── src/                      ← files installed under /usr/local/
```

Any directory containing a `Makefile` with `PLUGIN_NAME` is picked up
automatically by the build workflow – no changes to the workflow needed when
adding new plugins.

→ See [CONTRIBUTING.md](CONTRIBUTING.md) for build, release and contribution details.

---

## License

2-Clause BSD
