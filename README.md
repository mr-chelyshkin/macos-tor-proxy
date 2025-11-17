# macos-tor-proxy

Simple shell function to enable/disable system-wide Tor SOCKS proxy on macOS.

## What it does

- Configures macOS system-level SOCKS proxy to route traffic through Tor
- Manages Tor daemon lifecycle (start/stop)
- Sets shell environment variables for CLI tools
- Supports multiple network interfaces (Wi-Fi, USB Ethernet, etc.)

## Installation

### 1. Install Tor daemon
```bash
brew install tor
```

### 2. Configure Tor
```bash
sudo mkdir -p /opt/homebrew/var/lib/tor
sudo chown "$(whoami)" /opt/homebrew/var/lib/tor
```

Edit Tor config:
```bash
vim /opt/homebrew/etc/tor/torrc
```

Add the following:
```text
Log notice stderr
DataDirectory /opt/homebrew/var/lib/tor
SocksPort 127.0.0.1:9050
```

### 3. Add function to your shell

Open your shell config:
```bash
vim ~/.zshrc  # or ~/.bashrc for bash
```

Add the `torctl()` function from [torctl.sh](./torctl.sh) at the end of the file.

Reload shell config:
```bash
source ~/.zshrc  # or source ~/.bashrc
```

### 4. Verify installation
```bash
torctl status
```

## Usage

### Enable Tor proxy
```bash
torctl on
```

This will:
- Start Tor daemon via brew services
- Wait for Tor to be ready (port 9050)
- Configure system SOCKS proxy for all network interfaces
- Set shell proxy environment variables (`ALL_PROXY`, `HTTP_PROXY`, `HTTPS_PROXY`)

### Disable Tor proxy
```bash
torctl off
```

This will:
- Disable system SOCKS proxy
- Unset shell proxy variables
- Stop Tor daemon

### Check status
```bash
torctl status
```

Shows:
- Tor service state (brew services)
- Port 9050 listener status
- System proxy configuration
- Per-interface SOCKS settings
- Shell proxy environment variables

## Verification

### Check if traffic goes through Tor

**Browser (system-wide):**
```bash
torctl on
open https://check.torproject.org
# Should show "Congratulations. This browser is configured to use Tor."
```

**CLI (curl):**
```bash
torctl on
curl -s https://check.torproject.org | grep -i "Congratulations"
# Should output: Congratulations. This browser is configured to use Tor.
```

**Check your IP:**
```bash
torctl on
curl https://api.ipify.org
# Should show Tor exit node IP (not your real IP)

torctl off
curl https://api.ipify.org
# Should show your real IP
```

## Configuration

### Custom network interfaces

If your network interface name differs from default (`Wi-Fi`, `RNDIS/Ethernet Gadget`), edit the `SERVICES` array in the function:
```bash
# List all network services
networksetup -listallnetworkservices

# Edit function
vim ~/.zshrc
# Change:
local SERVICES=(
  "Wi-Fi"
  "Your Interface Name Here"
)
```

## Uninstall
```bash
# Stop and remove Tor
torctl off  # or manually: brew services stop tor
brew uninstall tor

# Remove Tor data and configs
sudo rm -rf /opt/homebrew/etc/tor
sudo rm -rf /opt/homebrew/var/lib/tor
rm ~/Library/LaunchAgents/homebrew.mxcl.tor.plist 2>/dev/null || true

# Remove function from shell config
vim ~/.zshrc  # delete torctl() function
source ~/.zshrc
```

## Security Notes
- This routes traffic through Tor but **does not guarantee anonymity**
- Browser fingerprinting, WebRTC leaks, and application-level identifiers can still expose you
- For serious anonymity needs, use [Tor Browser](https://www.torproject.org/download/)
- System-wide proxy means **all apps** use Tor (can be slow)

## Requirements
- macOS (tested on Ventura/Sonoma)
- Homebrew
- `sudo` access (for `networksetup` commands)
- `nc` (netcat) - pre-installed on macOS

## License
Apache License