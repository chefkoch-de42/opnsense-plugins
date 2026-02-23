# os-wancarp – OPNsense Plugin

> Automatically enables or disables a WAN interface when this node transitions
> between **CARP MASTER** and **BACKUP** state.

## What it does

On a single-WAN HA pair only the master node should hold the upstream link.
This plugin installs a CARP syshook script
(`/usr/local/etc/rc.syshook.d/carp/10-wancarp`) that reads its settings from
the OPNsense config and:

* **→ MASTER** – enables the WAN interface and triggers a DHCP re-lease.
* **→ BACKUP / INIT** – shuts the WAN interface down.

## Configuration

After installation go to **Services → WAN CARP Hook → Configuration**:

| Field | Description |
|-------|-------------|
| Enable | Activate the hook |
| WAN Interface | The interface key to up/down (dropdown of all configured interfaces) |
| Trigger VHID | CARP Virtual Host ID whose state change fires the hook (e.g. `1`). Leave empty to react to **every** CARP event. |

## Installation via pkg repo (recommended)

```sh
# 1. Add the repository config
fetch -o /usr/local/etc/pkg/repos/opnsense-plugins.conf \
  https://chefkoch-de42.github.io/opnsense-plugins/packages/opnsense-plugins.conf

# 2. Install
pkg update && pkg install os-wancarp
```

Alternatively add the repo URL in OPNsense under
**System → Firmware → Plugins → Add repository**.

### Repository URL

```
https://chefkoch-de42.github.io/opnsense-plugins/packages
```

## Manual installation

```sh
git clone https://github.com/chefkoch-de42/opnsense-plugins
cd os-wancarp/sysutils/os-wancarp
# on an OPNsense box with make/pkg available:
make package
pkg add work/pkg/os-wancarp-*.pkg
```

## Repository layout

```
os-wancarp/
├── .github/workflows/build-pkg.yml   ← GitHub Actions: build + publish to gh-pages
└── sysutils/os-wancarp/
    ├── Makefile
    ├── pkg-descr
    └── src/
        ├── etc/
        │   ├── inc/plugins.inc.d/wancarp.inc
        │   └── rc.syshook.d/carp/10-wancarp      ← the actual hook script
        └── opnsense/mvc/app/
            ├── controllers/OPNsense/WanCarp/
            │   ├── GeneralController.php
            │   ├── Api/GeneralController.php
            │   └── forms/general.xml
            ├── models/OPNsense/WanCarp/
            │   ├── General.php + General.xml      ← stores ifkey + vhid
            │   ├── ACL/ACL.xml
            │   └── Menu/Menu.xml
            └── views/OPNsense/WanCarp/
                └── general.volt
```

## License

2-Clause BSD

