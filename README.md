# Secure Authoritative DNS Server (BIND + DNSSEC) on AWS EC2

A hands-on project where I built and secured an authoritative DNS server for `drewtest.com` using BIND on an Amazon Linux EC2 instance, then signed the zone with DNSSEC.

## What this project covers

- Installing and configuring BIND as an **authoritative-only** DNS server
- Opening DNS through the firewall
- Hardening `named.conf` (listen addresses, recursion, zone transfers)
- Generating DNSSEC keys and signing a zone
- Verifying the signed zone with `dig`

## Environment

| Item | Value |
|------|-------|
| Cloud | AWS EC2 |
| OS | Amazon Linux |
| DNS software | BIND 9 (`bind`, `bind-utils`) |
| Domain | `drewtest.com` |
| Zone file | `/etc/named/zones/db.drewtest.com` |

> **AWS note:** the EC2 security group must also allow inbound **UDP and TCP port 53**. The OS firewall alone is not enough.

---

## Step 1: Install BIND & configure DNS

```bash
sudo dnf update -y
sudo dnf install bind bind-utils -y
sudo systemctl start named
sudo systemctl enable named
sudo systemctl status named
sudo cp /etc/named.conf /etc/named.conf.backup
sudo nano /etc/named.conf
```
- Changed 'listen to port 53' to 'any' instead of '127.0.0.1'
- Changed the localhost to 'any'

```bash
sudo systemctl restart named
nslookup localhost 127.0.0.1
sudo nano /etc/named/zones/db.drewtest.com
sudo mkdir -p /etc/named/zones
sudo nano /etc/named/zones/db.drewtest.com
sudo nano /etc/named.conf
```
- Changed 'zone "." IN' to 'zone "drewtest.com" IN'
- Changed 'type' to 'master'
- Changed 'file "/etc/named/zones/db.drewtest.com"', saved and restarted the named

## Notes:
- `dnf` is the package manager on Amazon Linux.
- `-y` automatically answers "yes" to prompts.
- `bind` is the DNS server; `bind-utils` provides testing tools like `dig`.

## Step 2: Firewall

`firewalld` was not installed by default, so I installed it first:

```bash
sudo dnf install firewalld -y
sudo systemctl start firewalld
sudo systemctl enable firewalld
```

Then allowed DNS (port 53, UDP and TCP):

```bash
sudo firewall-cmd --permanent --add-service=dns
sudo firewall-cmd --reload
```

## Notes:
- `--permanent` keeps the rule after a reboot.
- `--reload` applies it right away.

## Step 3: Harden BIND (`/etc/named.conf`)

```bash
sudo nano /etc/named.conf
```

Inside the `options { ... };` block:

```
listen-on port 53 { 127.0.0.1; <PRIVATE_IP>; };
allow-query { any; };
allow-transfer { none; };
recursion no;
```

| Setting | Why |
|---------|-----|
| `listen-on` | Only listen on localhost and the server's own IP instead of `any` |
| `allow-query { any; }` | An authoritative server must answer queries from the internet |
| `allow-transfer { none; }` | Stops anyone copying the whole zone |
| `recursion no;` | An authoritative server should not resolve other domains. Open recursion lets attackers abuse the server in DNS amplification (DDoS) attacks |

Check the config and restart:

```bash
sudo named-checkconf /etc/named.conf
sudo systemctl restart named
```

`named-checkconf` prints nothing if the config is valid. BIND only reads its config at startup, so a restart is required after every edit.

## Step 4: DNSSEC

DNSSEC adds digital signatures to DNS records so resolvers can verify the answers are authentic and unmodified.

### 4.1 Generate the keys

```bash
dnssec-keygen -a RSASHA256 -b 2048 -n ZONE drewtest.com
dnssec-keygen -a RSASHA256 -b 2048 -n ZONE -f KSK drewtest.com
```

## Notes:
- `-a RSASHA256`: signing algorithm
- `-b 2048`: key size in bits
- `-n ZONE`: the key is for a DNS zone
- `-f KSK`: makes this a **Key Signing Key**. Without it, the key is a **Zone Signing Key (ZSK)**

Each command creates a `.key` (public) and a `.private` (secret) file in the current directory.

### 4.2 Put the keys next to the zone file

```bash
sudo cp ~/Kdrewtest.com.* /etc/named/zones/
```

### 4.3 Add the public keys to the zone file

```bash
cat Kdrewtest.com.*.key
sudo nano /etc/named/zones/db.drewtest.com
```

Append both `DNSKEY` lines (one starting with `256` for the ZSK, one with `257` for the KSK) to the end of the zone file.

### 4.4 Sign the zone

```bash
sudo -s
cd /etc/named/zones/
dnssec-signzone -o drewtest.com db.drewtest.com
exit
```

## Notes:
- `-o drewtest.com` sets the zone origin (the domain name).
- Output: `db.drewtest.com.signed`

### 4.5 Serve the signed zone

In `/etc/named.conf`, change the zone's `file` line:

```
zone "drewtest.com" IN {
    type master;
    file "/etc/named/zones/db.drewtest.com.signed";
};
```

Then:

```bash
sudo named-checkzone drewtest.com /etc/named/zones/db.drewtest.com.signed
sudo systemctl restart named
```

## Step 5: Verify

```bash
dig @<PRIVATE_IP> drewtest.com SOA +dnssec
dig @localhost drewtest.com DNSKEY +short
```

What to look for: an **`RRSIG`** record next to the SOA record means the zone is signed and being served.

> The `ad` (authenticated data) flag will not appear here. That flag is only set by validating resolvers, and this server has recursion disabled.

---

## Evidence

Proof the setup works, taken from the live server:

- `screenshots/` contains terminal output from the build, including:
  - the zone being signed (`Zone fully signed`)
  - `named-checkzone` reporting `DNSSEC signed` and `OK`
  - the `dig` result showing the `RRSIG` record
- `command-history.txt` is the raw command history from the server (reviewed first to remove anything sensitive).

---

## Troubleshooting notes (things that went wrong)

| Problem | Cause / fix |
|---------|-------------|
| `firewall-cmd: command not found` | `firewalld` wasn't installed. Installed it with `dnf` |
| `recursion redefined` from `named-checkconf` | There was already a `recursion` line. Edited the existing one instead of adding a second |
| `dnssec-signzone: file not found` | Wrong path. The directory was called `zones`, not `zone` |
| `No signing keys specified or found` | Keys were in `/home/ec2-user/`, not next to the zone file, and the public keys weren't in the zone file yet |
| `cd: permission denied` into `/etc/named/zones` | Directory is root-only. Used `sudo -s` for a root shell |
| `dig @localhost` connection refused | `listen-on` didn't include `127.0.0.1` as I had replaced it out during configuration. In addition, BIND wasn't restarted after the last edit |

## Security notes

- **Never commit `*.private` key files.** They are the secret half of the DNSSEC keys. Add this to `.gitignore`:
  ```
  *.private
  ```
- Treat the `.key` files and zone file as safe to share, but keep real private IPs out of public repos if you can.

## Known limitations / next steps

- [ ] **Add a DS record at the domain registrar.** This links the KSK to the parent zone and completes the chain of trust. Until then, validating resolvers on the internet will not treat the zone as secured.
- [ ] **Re-sign before signatures expire.** `dnssec-signzone` signatures last about 30 days by default. Re-run the signing step (and increase the zone serial number when editing records), or look into `auto-dnssec` / `dnssec-policy` for automation.
- [ ] Rate limiting (`rate-limit` in BIND) to reduce abuse.
- [ ] Restrict SSH access in the AWS security group.

## What I learned

- The difference between an authoritative and a recursive DNS server, and why open recursion is dangerous
- How the ZSK and KSK work together in DNSSEC
- Why a config change does nothing until the service is restarted
- How to read errors carefully: most of my problems were wrong paths and file locations
