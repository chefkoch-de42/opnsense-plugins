# os-wancarp – Single-WAN CARP Failover Hook

OPNsense plugin that automatically **enables or disables a WAN interface**
whenever this node transitions between CARP MASTER and BACKUP state.

---

## Purpose

In a typical two-firewall HA setup with CARP, both nodes share virtual IP
addresses (VIPs). However, if you only have **one upstream WAN connection**,
only the MASTER node should hold that WAN link. The BACKUP node must not
try to obtain a DHCP lease or send packets out of an interface that has no
physical upstream.

This plugin solves that by hooking into OPNsense's CARP event system:

| CARP event | Action |
|---|---|
| → **MASTER** | WAN interface is brought **up**, `interface_configure()` runs, DHCP lease is (re-)requested |
| → **BACKUP** / INIT | WAN interface is brought **down** (`ifconfig … down`), config entry disabled |

The hook script is installed at:
```
/usr/local/etc/rc.syshook.d/carp/10-wancarp
```

---

## Installation

### Via pkg repo (recommended)

```sh
# 1. Add the repository
fetch -o /usr/local/etc/pkg/repos/opnsense-plugins.conf \
  https://chefkoch-de42.github.io/opnsense-plugins/packages/opnsense-plugins.conf

# 2. Install
pkg update && pkg install os-wancarp
```

### Removal

```sh
pkg delete os-wancarp
```

---

## Configuration

After installation navigate to **Services → WAN CARP Hook → Configuration**.

| Field | Description |
|---|---|
| **Enable** | Activate the hook. When disabled the script exits immediately on every CARP event. |
| **WAN Interface** | The OPNsense interface key to bring up/down (dropdown of all configured interfaces, e.g. `wan`). |
| **Trigger VHID** | CARP Virtual Host ID whose state change fires the hook (e.g. `1`). Leave empty to react to **every** CARP event on any VHID. Tip: use the VHID of your LAN/sync CARP VIP so all failovers are covered by a single event. |

Click **Save** – no service restart required. The settings are read live on
each CARP event.

---

## Required routing setup

> ⚠️ **Without the routes below, the BACKUP firewall will have no internet
> connectivity while it is in BACKUP state.**

Because only the MASTER node has an active WAN interface, the BACKUP node
must forward all outbound traffic through the MASTER via the LAN segment.
This requires static default routes on **both** firewalls.

### Network topology (example)

```
Internet
    │
    │  (single upstream)
    │
┌───┴────────────────────────────────────────────────────┐
│  WAN interface – only active on MASTER                 │
│                                                        │
│  FW1 (MASTER)                FW2 (BACKUP)              │
│  LAN: 192.168.10.1           LAN: 192.168.10.2         │
│  LAN IPv6: fe80::A           LAN IPv6: fe80::B         │
│                                                        │
│            LAN CARP VIP: 192.168.10.254                │
│            (moves with MASTER)                         │
└────────────────────────────────────────────────────────┘
         │
    LAN clients
```

---

### IPv4 routing

Both firewalls need their **default IPv4 gateway** set to the **shared LAN
CARP VIP** (e.g. `192.168.10.254`).

- When a node is MASTER the CARP VIP is local → traffic exits via WAN directly.
- When a node is BACKUP the CARP VIP is on the peer → traffic is forwarded
  to the MASTER which then sends it upstream.

**OPNsense setup:**

1. `System → Gateways → Configuration` – verify a gateway entry exists for
   the LAN CARP VIP (it is usually created automatically when you add the
   CARP VIP).
2. `System → Routes → Configuration` – set the default route (`0.0.0.0/0`)
   to that gateway on **both** firewalls.

Suggested gateway priority: **150** – same level as the DHCP-assigned WAN
gateway so route preferences stay consistent after failover.

---

### IPv6 routing

> ⚠️ **Do NOT use a CARP VIP as the IPv6 default gateway.**
>
> FreeBSD has a known limitation: CARP failover does **not** automatically
> flush the IPv6 neighbour cache. If the CARP VIP is used as the IPv6 default
> gateway, the BACKUP node's neighbour cache entry for the VIP goes stale
> immediately after failover and the default route becomes unreachable.

**Solution:** each firewall must point its IPv6 default route at the
**link-local address of the peer's LAN interface**. Link-local addresses are
always directly reachable on the LAN segment regardless of which node holds
the CARP VIP.

| Node | IPv6 default gateway |
|---|---|
| FW1 | link-local address of FW2's LAN interface (e.g. `fe80::B%<LAN-if>`) |
| FW2 | link-local address of FW1's LAN interface (e.g. `fe80::A%<LAN-if>`) |

**OPNsense setup:**

1. Find each peer's LAN link-local address:
   ```sh
   # run on the peer node:
   ifconfig <LAN-interface> | grep "inet6 fe80"
   ```
   Or read it from `System → Diagnostics → NDP Table`.

2. `System → Gateways → Configuration` – add a **static IPv6 gateway** on
   each firewall:
   - Interface: LAN
   - IP address: `fe80::<peer-suffix>` (the peer's link-local address)
   - Name: e.g. `LAN-fw02` (on FW1) / `LAN-fw01` (on FW2)

3. Set priority to **200** – lower than the WAN gateways (150) so the direct
   WAN path is always preferred on the MASTER.

4. `System → Routes → Configuration` – add a default IPv6 route (`::/0`)
   via the peer gateway on **both** firewalls.

**Why this works after failover:**

```
Before failover (FW1 = MASTER):
  FW1: WAN up   → traffic exits directly upstream              ✓
  FW2: WAN down → IPv6 default via fe80::A (FW1 LAN)
                  FW1 receives and forwards upstream           ✓

After failover (FW2 = new MASTER):
  FW2: WAN up   → traffic exits directly upstream              ✓
  FW1: WAN down → IPv6 default via fe80::B (FW2 LAN)
                  FW2 receives and forwards upstream           ✓
```

`fe80::B` is always reachable from FW1 on the LAN segment even when FW2 is
MASTER, so the route never goes stale.

---

## Troubleshooting

**WAN does not come up after becoming MASTER**
- Check `/var/log/system.log` for lines tagged `wancarp:`.
- Verify the interface key in the plugin matches the OPNsense interface name
  (e.g. `wan`, not the physical driver name `igc0`).
- Verify the VHID setting matches the CARP VIP that fires the event.

**BACKUP node has no internet access (IPv4)**
- Confirm the default IPv4 route points to the LAN CARP VIP, not to the WAN
  gateway directly.
- Check routing table: `netstat -rn` on the BACKUP node.

**BACKUP node has no internet access (IPv6)**
- Confirm the default IPv6 route points to the peer's link-local address.
- Test reachability: `ping6 fe80::<peer>%<LAN-if>`
- Check routing table: `netstat -rn -f inet6` on the BACKUP node.

**Both nodes believe they are MASTER (split-brain)**
- This is a CARP configuration issue unrelated to this plugin. Check CARP VIP
  settings and network connectivity between the nodes (sync interface).

---

## Changelog

### 0.0.1
- Initial release

---

## License

2-Clause BSD – see [source repository](https://github.com/chefkoch-de42/opnsense-plugins) for full text.
