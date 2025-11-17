# macos-tor-proxy

# Install
1. Install tor daemon
```bash
brew install tor
```
2. Setup config
```bash
vim /opt/homebrew/etc/tor/torrc
```
```text
Log notice stderr
DataDirectory /opt/homebrew/var/lib/tor

SocksPort 127.0.0.1:9050
```
3. Common dir and run daemon
```bash
sudo mkdir -p /opt/homebrew/var/lib/tor
sudo chown "$(whoami)" /opt/homebrew/var/lib/tor

brew services restart tor
```
4. Add sources(./torctl.sh) to `~/.zshrc` | `~/.bashrc` file
```bash
# ~/.zshrc
... existed content

torctl() {
 ...
}
```

# Uninstall
```bash
brew services stop tor
brew uninstall tor
sudo rm -rf /opt/homebrew/etc/tor
sudo rm -rf /opt/homebrew/var/lib/tor
rm ~/Library/LaunchAgents/homebrew.mxcl.tor.plist 2>/dev/null || true
```
