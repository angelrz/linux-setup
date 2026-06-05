#!/usr/bin/env bash
set -euo pipefail

# setup.sh - Configuración de Powerline (Ubuntu)
# Ejecutar con: sudo bash setup.sh

log() {
  printf "\n==> %s\n" "$*"
}

warn() {
  printf "\n[!] %s\n" "$*"
}

require_root() {
  if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    warn "Este script necesita privilegios. Ejecuta: sudo bash setup.sh"
    exit 1
  fi
}

install_fonts() {
  log "Instalar fonts-powerline"
  apt update
  apt install -y fonts-powerline
}

configure_font_alias() {
  local conf_file="/etc/fonts/conf.d/10-powerline-symbols.conf"
  local alias_block="    <alias>\n        <family>Ubuntu Sans Mono</family>\n        <prefer><family>PowerlineSymbols</family></prefer>\n    </alias>"

  log "Ajustar alias de fuente en ${conf_file}"

  if [ ! -f "$conf_file" ]; then
    warn "No existe ${conf_file}. Se omitirá el ajuste de alias."
    return 0
  fi

  if grep -q "PowerlineSymbols" "$conf_file"; then
    log "Alias ya presente. No se realizaron cambios."
    return 0
  fi

  cp -a "$conf_file" "${conf_file}.bak"

  if grep -q "</fontconfig>" "$conf_file"; then
    awk -v block="$alias_block" '
      /<\/fontconfig>/ {
        print block
      }
      { print }
    ' "$conf_file" > "${conf_file}.tmp"
    mv "${conf_file}.tmp" "$conf_file"
  else
    printf "\n%s\n" "$alias_block" >> "$conf_file"
  fi
}

refresh_font_cache() {
  log "Actualizar cache de fuentes"
  fc-cache -vf
}

main() {
  require_root
  install_fonts
  configure_font_alias
  refresh_font_cache
  log "Listo."
}

main "$@"
