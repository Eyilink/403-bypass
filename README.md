# 🔓 URL Encode / Path Normalization Bypass Tool

A fast, parallel **URL path normalization & encoding bypass testing tool** written in pure **Bash**, designed for **security researchers, bug bounty hunters, and penetration testers**.

This tool automates detection of access control bypasses caused by:
- URL encoding inconsistencies
- Path traversal normalization
- Reverse proxy vs backend parsing differences
- WAF / CDN path handling issues

---

## ✨ Features

- 🚀 Parallel requests for fast scanning
- 🧠 Smart `--path-as-is` usage only when curl would normalize paths
- 🎯 Accurate status-based detection
  - `2xx` → real success (bypass)
  - `3xx` → interesting behavior
  - `4xx` → blocked
  - `5xx` → backend / WAF anomalies
- 🔁 Dynamic payload substitution using `${pat}`
- 📄 Custom payload wordlist support
- 🧩 Custom HTTP method support
- 🧷 Custom headers support (repeatable)
- 📏 Response length comparison
- 🧪 Reproducible curl command output
- 🖥️ Clean, colored terminal output
- 🧷 Bypass with headers support

---

## 🚀 Usage

```bash
Usage: 403bypass.sh -u <url> [options]
Options:
  -u, --url        Specify <Target_Url>
  -m, --method     Specify Method <POST, PUT, PATCH> (Default, GET)
  -H, --header     Add custom header (repeatable)
  -a, --all        Run both URL encode and header bypass tests
  -fs              Exclude a certain size , Ffuf style
  -d               When POST is used, it enable to transmit data, Curl style
  -st              Mask unsuccessful result, for screenshots mostly
  -h, --help       Display help and exit
```

---

## 🧪 Examples

```bash
./403bypass.sh -u https://example.com/admin

./403bypass.sh -u https://example.com/api/admin -m POST

./403bypass.sh -u https://example.com/admin \
  -H "Authorization: Bearer TOKEN" \
  -H "X-Forwarded-For: 127.0.0.1"

./403bypass.sh -u https://example.com/admin \
  -H "Authorization: Bearer TOKEN" \
  --all
```

---

# 👤 Author
Recylced from -> Ahmad Mugheera








