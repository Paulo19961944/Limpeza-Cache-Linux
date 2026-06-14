#!/usr/bin/env bash

set -e

echo "======================================"
echo " LIMPEZA COMPLETA DO LINUX"
echo "======================================"

# Detectar distro
if [ -f /etc/os-release ]; then
    source /etc/os-release
    echo "Sistema detectado: $PRETTY_NAME"
else
    echo "Não foi possível detectar a distribuição."
    exit 1
fi

echo

########################################
# ARCH / CACHYOS / MANJARO / ENDEAVOUR
########################################

if command -v pacman >/dev/null 2>&1; then

    echo "[1/10] Removendo pacotes órfãos..."

    orphans=$(pacman -Qdtq || true)

    if [ -n "$orphans" ]; then
        sudo pacman -Rns --noconfirm $orphans
    else
        echo "Nenhum pacote órfão encontrado."
    fi

    echo "[2/10] Limpando cache do Pacman..."

    if command -v paccache >/dev/null 2>&1; then
        sudo paccache -rk2
        sudo paccache -ruk0
    else
        sudo pacman -Scc --noconfirm
    fi

    sudo rm -rf /var/cache/pacman/pkg/download-* 2>/dev/null || true

########################################
# FEDORA / NOBARA / RHEL
########################################

elif command -v dnf >/dev/null 2>&1; then

    echo "[1/10] Removendo dependências não utilizadas..."
    sudo dnf autoremove -y

    echo "[2/10] Limpando cache do DNF..."
    sudo dnf clean all
    sudo rm -rf /var/cache/dnf/*

########################################
# DEBIAN / UBUNTU / ZORIN / MINT
########################################

elif command -v apt >/dev/null 2>&1; then

    echo "[1/10] Removendo dependências não utilizadas..."
    sudo apt autoremove -y

    echo "[2/10] Limpando cache do APT..."
    sudo apt clean
    sudo apt autoclean -y

    sudo rm -rf /var/cache/apt/archives/*.deb

else
    echo "Distribuição não suportada."
    exit 1
fi

########################################
# FLATPAK
########################################

echo "[3/10] Limpando Flatpak..."

if command -v flatpak >/dev/null 2>&1; then
    flatpak uninstall --unused -y || true
fi

########################################
# SNAP
########################################

echo "[4/10] Limpando Snap..."

if command -v snap >/dev/null 2>&1; then

    sudo snap set system refresh.retain=2

    disabled_snaps=$(snap list --all | awk '/disabled/{print $1, $3}')

    if [ -n "$disabled_snaps" ]; then
        echo "$disabled_snaps" | while read snapname revision
        do
            sudo snap remove "$snapname" --revision="$revision"
        done
    fi
fi

########################################
# DOCKER
########################################

echo "[5/10] Limpando Docker..."

if command -v docker >/dev/null 2>&1; then
    sudo docker system prune -af --volumes
fi

########################################
# LOGS
########################################

echo "[6/10] Limpando logs antigos..."

if command -v journalctl >/dev/null 2>&1; then
    sudo journalctl --vacuum-time=30d
fi

########################################
# TMPFILES
########################################

echo "[7/10] Limpando arquivos temporários..."

if command -v systemd-tmpfiles >/dev/null 2>&1; then
    sudo systemd-tmpfiles --clean
fi

########################################
# CACHE DOS NAVEGADORES
########################################

echo "[8/10] Limpando cache dos navegadores..."

rm -rf ~/.cache/mozilla/*
rm -rf ~/.cache/firefox/*

rm -rf ~/.cache/google-chrome/*
rm -rf ~/.config/google-chrome/Default/Cache/* 2>/dev/null || true

rm -rf ~/.cache/chromium/*
rm -rf ~/.config/chromium/Default/Cache/* 2>/dev/null || true

rm -rf ~/.cache/BraveSoftware/*
rm -rf ~/.config/BraveSoftware/Brave-Browser/Default/Cache/* 2>/dev/null || true

rm -rf ~/.cache/opera/*
rm -rf ~/.config/opera/Cache/* 2>/dev/null || true

rm -rf ~/.config/opera-beta/Cache/* 2>/dev/null || true
rm -rf ~/.config/opera-developer/Cache/* 2>/dev/null || true

########################################
# MINIATURAS
########################################

echo "[9/10] Limpando miniaturas..."

rm -rf ~/.cache/thumbnails/*

########################################
# CACHE GERAL DO USUÁRIO
########################################

echo "[10/10] Limpando cache geral do usuário..."

rm -rf ~/.cache/*

########################################
# RELATÓRIO
########################################

echo
echo "======================================"
echo " USO DE DISCO"
echo "======================================"

df -h /

echo
echo "======================================"
echo " MAIORES DIRETÓRIOS DO HOME"
echo "======================================"

du -sh ~/* 2>/dev/null | sort -hr | head -20

echo
echo "======================================"
echo " LIMPEZA CONCLUÍDA"
echo "======================================"
