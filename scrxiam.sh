#!/bin/sh
# OpenWrt setup: base pkgs + youtubeUnblock + podkop + replace /etc/config/youtubeUnblock
# Лира ❤

set -e

GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; NC='\033[0m'

say() { printf "${GREEN}%s${NC}\n" "$*"; }
warn() { printf "${YELLOW}%s${NC}\n" "$*"; }
err() { printf "${RED}%s${NC}\n" "$*" >&2; }

[ "$(id -u)" -eq 0 ] || { err "Нужны root-права. Запусти: sudo -i, затем sh $0"; exit 1; }

RAW_CFG_URL="https://raw.githubusercontent.com/amndamaru/mggdfghldsgdfsg/main/youtubeUnblock"
CFG_DIR="/etc/config"
CFG_PATH="$CFG_DIR/youtubeUnblock"

# --- 1) OPKG update + базовые пакеты ---
say "[1/6] opkg update…"
opkg update

say "[2/6] Устанавливаю базовые пакеты…"
# Пакеты: локализация, тема, менеджер пакетов, SSH, SFTP, netfilter/nft queue и conntrack
opkg install \
  luci-i18n-base-ru \
  luci-theme-material \
  luci-i18n-package-manager-ru \
  openssh-server openssh-sftp-server \
  kmod-nfnetlink-queue \
  kmod-nft-queue \
  kmod-nf-conntrack

# --- 2) youtubeUnblock (ipk) ---
say "[3/6] Ставлю youtubeUnblock…"
TMP="/tmp"
YT_IPK="$TMP/youtubeUnblock.ipk"
LUCI_YT_IPK="$TMP/luci-app-youtubeUnblock.ipk"

# ВНИМАНИЕ: этот ipk собран под aarch64_cortex-a53 для OpenWrt 23.05.
warn "Если архитектура/версия не совпадают – установка может не пройти."

wget -O "$YT_IPK" "https://github.com/Waujito/youtubeUnblock/releases/download/v1.1.0/youtubeUnblock-1.1.0-2-2d579d5-aarch64_cortex-a53-openwrt-23.05.ipk"
opkg install "$YT_IPK"

wget -O "$LUCI_YT_IPK" "https://github.com/Waujito/youtubeUnblock/releases/download/v1.1.0/luci-app-youtubeUnblock-1.1.0-1-473af29.ipk"
opkg install "$LUCI_YT_IPK"

# --- 3) Podkop installer ---
say "[4/6] Устанавливаю podkop…"
# В busybox/ash нельзя использовать процессную подстановку <(...).
# Поэтому качаем и передаём в sh через pipe:
wget -O- "https://raw.githubusercontent.com/itdoginfo/podkop/refs/heads/main/install.sh" | sh

# --- 4) Заменить конфиг youtubeUnblock из твоего репозитория в /etc/configs/ ---
say "[5/6] Обновляю файл конфигурации в $CFG_PATH…"
mkdir -p "$CFG_DIR"

if [ -f "$CFG_PATH" ]; then
  cp "$CFG_PATH" "$CFG_PATH.bak.$(date +%Y%m%d-%H%M%S)"
  warn "Старый файл сохранён как $(basename "$CFG_PATH").bak.*"
fi

# Скачиваем «raw» вариант файла, а не web-страницу GitHub
wget --no-check-certificate -O "$CFG_PATH.new" "$RAW_CFG_URL"
mv -f "$CFG_PATH.new" "$CFG_PATH"
chmod 644 "$CFG_PATH"

# --- 5) Финал/очистка ---
say "[6/6] Очистка временных файлов…"
rm -f "$YT_IPK" "$LUCI_YT_IPK"

say "Готово! Если нужно — перезапусти сервисы:"
printf "${YELLOW}service dnsmasq restart; service odhcpd restart${NC}\n"
