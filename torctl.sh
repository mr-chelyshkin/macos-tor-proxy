# === torctl ===
# $ brew install tor
#
# $ vim /opt/homebrew/etc/tor/torrc
# Log notice stderr
# DataDirectory /opt/homebrew/var/lib/tor
# SocksPort 127.0.0.1:9050
#
# $ brew services start tor
# $ lsof -iTCP:9050 -sTCP:LISTEN
torctl() {
  local cmd="$1"
  shift 2>/dev/null || true

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
        if ! brew services start tor >/dev/null 2>&1; then
          echo "[torctl] ERROR: failed to start tor service"
          echo "[torctl] Check: brew services list"
          return 1
        fi
      else
        echo "[torctl] ERROR: brew not found, cannot start tor"
        return 1
      fi

      echo "[torctl] Waiting for Tor to start..."
      local ready=0

      for _ in {1..30}; do
        if nc -z "$HOST" "$PORT" 2>/dev/null; then
          ready=1
          echo "[torctl] Tor is ready (port $PORT is listening)"
          break
        fi
        sleep 1
      done

      if [ $ready -eq 0 ]; then
        echo "[torctl] ERROR: Tor failed to start within 30 seconds"
        echo "[torctl] Check: lsof -iTCP:$PORT -sTCP:LISTEN"
        brew services stop tor >/dev/null 2>&1
        return 1
      fi

      for SVC in "${SERVICES[@]}"; do
        echo "[torctl] Configuring '$SVC'"

        if ! sudo networksetup -setsocksfirewallproxy "$SVC" "$HOST" "$PORT" 2>/dev/null; then
          echo "[torctl] WARNING: failed to configure proxy for '$SVC' (interface may not exist)"
          continue
        fi

        if ! sudo networksetup -setsocksfirewallproxystate "$SVC" on 2>/dev/null; then
          echo "[torctl] WARNING: failed to enable proxy for '$SVC'"
          continue
        fi
      done

      echo "[torctl] System proxy state:"
      scutil --proxy

      local url="socks5h://$HOST:$PORT"
      export ALL_PROXY="$url"
      export HTTPS_PROXY="$ALL_PROXY"
      export HTTP_PROXY="$ALL_PROXY"
      echo "[torctl] Shell proxy ON -> $ALL_PROXY"
      echo "[torctl] NOTE: shell proxy env works only in current shell session"
      ;;

    off)
      echo "[torctl] Disabling system SOCKS proxy on: ${SERVICES[*]}"

      for SVC in "${SERVICES[@]}"; do
        echo "[torctl] Turning OFF SOCKS proxy on '$SVC'"
        sudo networksetup -setsocksfirewallproxystate "$SVC" off 2>/dev/null || \
          echo "[torctl] WARNING: failed to disable proxy for '$SVC'"
      done

      echo "[torctl] System proxy state:"
      scutil --proxy

      unset ALL_PROXY
      unset HTTPS_PROXY
      unset HTTP_PROXY
      echo "[torctl] Shell proxy OFF"

      if command -v brew >/dev/null 2>&1; then
        echo "[torctl] Stopping tor service via brew..."
        brew services stop tor >/dev/null 2>&1 || \
          echo "[torctl] WARNING: failed to stop tor service"
      fi
      ;;

    status)
      echo "=== torctl status ==="

      if command -v brew >/dev/null 2>&1; then
        echo "-- brew services (tor) --"
        brew services list | grep tor || echo "tor service not found"
      else
        echo "-- brew not found --"
      fi

      echo
      echo "-- tor port check --"
      if nc -z "$HOST" "$PORT" 2>/dev/null; then
        echo "Port $PORT is LISTENING"
        lsof -iTCP:$PORT -sTCP:LISTEN 2>/dev/null || true
      else
        echo "Port $PORT is NOT listening"
      fi

      echo
      echo "-- system proxy (scutil --proxy) --"
      scutil --proxy

      echo
      echo "-- per-service SOCKS state --"
      for SVC in "${SERVICES[@]}"; do
        echo "[$SVC]"
        networksetup -getsocksfirewallproxy "$SVC" 2>/dev/null || \
          echo "  (interface not found or not accessible)"
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
      echo "  off    - disable system-wide SOCKS proxy and stop Tor"
      echo "  status - show Tor/system proxy/shell proxy status"
      echo
      echo "Note: If your network interface has a different name,"
      echo "      edit SERVICES array in the function."
      echo "      Run: networksetup -listallnetworkservices"
      ;;

    *)
      echo "[torctl] Unknown command: $cmd"
      echo "Usage: torctl {on|off|status}"
      return 1
      ;;
  esac
}