#!/usr/bin/env bash
set -euo pipefail

# setup.sh - tareas base para Debian 12 / LMDE6
# Autor: generado por GitHub Copilot

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

get_os_info() {
  # Carga /etc/os-release si existe
  if [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
  fi
}

is_debian_12() {
  [ "${ID:-}" = "debian" ] && [ "${VERSION_ID:-}" = "12" ]
}

is_lmde6() {
  # LMDE6: ID=linuxmint, VERSION_ID=6, VARIANT=LMDE (a veces)
  [ "${ID:-}" = "linuxmint" ] && [ "${VERSION_ID:-}" = "6" ]
}

show_manual_steps() {
  warn "Pasos manuales (no automatizables con seguridad):"
  echo "- Editar /etc/default/grub para GRUB_DEFAULT/GRUB_SAVEDEFAULT"
  echo "- Editar /etc/sudoers para agregar tu usuario"
  echo "- Editar ~/.bashrc si deseas bash-completion"
}

enable_local_rtc() {
  log "Sincronizar reloj local para dual-boot"
  timedatectl set-local-rtc 1
}

update_grub() {
  log "Actualizar GRUB"
  update-grub
}

install_bash_completion() {
  log "Instalar bash-completion"
  apt update
  apt install -y bash-completion
}

fix_calculator_refresh() {
  log "Ajustar refresh de GNOME Calculator"
  # Se ejecuta para el usuario actual; si estás con sudo, apunta a root
  # Puedes ejecutar manualmente sin sudo para tu usuario.
  if command -v dconf >/dev/null 2>&1; then
    dconf write /org/gnome/calculator/refresh-interval 0
  else
    warn "dconf no está disponible. Omitido."
  fi
}

purge_debian_gnome_apps() {
  log "Eliminar apps/juegos GNOME en Debian 12"
  apt -y purge \
    gnome-2048 gnome-contacts gnome-weather gnome-maps gnome-calendar gnome-clocks \
    gnome-chess five-or-more simple-scan four-in-a-row cheese gnome-sound-recorder \
    hitori gnome-klotski lightsoff gnome-mines gnome-nibbles gnome-mahjongg \
    quadrapassel rhythmbox gnome-robots iagno gnome-music gnome-sudoku gnome-taquin \
    gnome-tetravex thunderbird transmission-common transmission-gtk aisleriot \
    swell-foop tali libreoffice* evolution debian-reference-common yelp
  apt -y autopurge
}

purge_lmde_apps() {
  log "Eliminar apps/juegos en LMDE6"
  apt -y purge \
    gnote gedit libreoffice* hexchat hypnotix redshift onboard celluloid transmission \
    gnome-calendar gnome-2048 gnome-chess gnome-games gnome-klotski gnome-mahjongg \
    gnome-mines gnome-nibbles gnome-robots gnome-sound-recorder gnome-sudoku \
    gnome-taquin gnome-tetravex gnome-video-effects thunderbird pidgin remmina \
    shotwell sound-juicer transmission-common transmission-gtk rhythmbox xterm \
    drawing pix sticky thingy warpinator
  apt -y autopurge
}

main() {
  require_root
  get_os_info

  log "Detectando sistema"
  echo "ID=${ID:-desconocido} VERSION_ID=${VERSION_ID:-desconocido}"

  enable_local_rtc
  install_bash_completion
  update_grub
  fix_calculator_refresh

  if is_debian_12; then
    purge_debian_gnome_apps
  elif is_lmde6; then
    purge_lmde_apps
  else
    warn "Sistema no reconocido como Debian 12 o LMDE6. Omitiendo purge de apps."
  fi

  show_manual_steps
  log "Listo."
}

main "$@"
