# --- torctl --- 
# brew install tor
#
# /opt/homebrew/etc/tor/torrc
# Log notice stderr
# DataDirectory /opt/homebrew/var/lib/tor
# SocksPort 127.0.0.1:9050
#
# brew services start tor
# lsof -iTCP:9050 -sTCP:LISTEN
torctl() {
  local cmd="$1"
  shift 2>/dev/null || true

  # networksetup -listallnetworkservices
  local SERVICES=(
    "Wi-Fi"
    "RNDIS/Ethernet Gadget"
  )
  local HOST="127.0.0.1"
  local PORT="9050"

  case "$cmd" in
    on) 
      echo "[torctl] Enabling system SOCKS proxy via Tor on ${SERVICES[*]}"

      if command -v brew >/dev/null 2>&1; then
        echo "[torctl] Starting tor service via brew..."
        brew services start tor >/dev/null 2>&1 || \
          echo "[torctl] Warning: failed to start tor, check 'brew services list'"
      else
        echo "[torctl] Warning: brew not found, tor service not started"
      fi

      for SVC in "${SERVICES[@]}"; do
        echo "[torctl] Configuring '$SVC'"
        sudo networksetup -setsocksfirewallproxy "$SVC" "$HOST" "$PORT"
        sudo networksetup -setsocksfirewallproxystate "$SVC" on
      done

      echo "[torctl] System proxy state:"
      scutil --proxy

      local url="socks5h://$HOST:$PORT"
      export ALL_PROXY="$url"
      export HTTPS_PROXY="$ALL_PROXY"
      export HTTP_PROXY="$ALL_PROXY"
      echo "[torctl] shell proxy ON -> $ALL_PROXY"
      ;;

    off) 
      echo "[torctl] Disabling system SOCKS proxy on: ${SERVICES[*]}"

      for SVC in "${SERVICES[@]}"; do
        echo "[torctl] Turning OFF SOCKS proxy on '$SVC'"
        sudo networksetup -setsocksfirewallproxystate "$SVC" off
      done

      echo "[torctl] System proxy state:"
      scutil --proxy

      unset ALL_PROXY
      unset HTTPS_PROXY
      unset HTTP_PROXY
      echo "[torctl] shell proxy OFF"
      ;;

    status)
      echo "== torctl status =="

      if command -v brew >/dev/null 2>&1; then
        echo "-- brew services (tor) --"
        brew services list | grep tor || echo "tor service not found"
      else
        echo "-- brew not found --"
      fi

      echo
      echo "-- system proxy (scutil --proxy) --"
      scutil --proxy

      echo
      echo "-- per-service SOCKS state --"
      for SVC in "${SERVICES[@]}"; do
        echo "[$SVC]"
        networksetup -getsocksfirewallproxy "$SVC"
        echo
      done

      echo "-- shell proxy env --"
      env | grep -i proxy || echo "no proxy-related env vars"
      ;;

    ""|help|-h|--help)
      echo "Usage: torctl <command>"
      echo
      echo "Commands:"
      echo "  on     - enable system-wide SOCKS proxy via Tor"
      echo "  off    - disable system-wide SOCKS proxy"
      echo "  status - show Tor/system proxy/shell proxy status"
      ;;

    *)
      echo "[torctl] Unknown command: $cmd"
      echo "Usage: torctl {on|off|status}"
      return 1
      ;;
  esac
}
