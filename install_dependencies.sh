#!/bin/bash

# ============================================================================
# Instalador de Dependências - Workload Generator
# Instala g++, stress-ng e fio e compila o workload_generator.
# Use --gpu para também instalar o gpu-burn (requer GPU NVIDIA + CUDA).
# ============================================================================

set -e

WITH_GPU=false
for arg in "$@"; do
    case "$arg" in
        --gpu) WITH_GPU=true ;;
        -h|--help)
            echo "Uso: $0 [--gpu]"
            echo "  --gpu   também instala o gpu-burn (opcional)"
            exit 0
            ;;
    esac
done

cd "$(dirname "$0")"

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "✗ Não foi possível detectar o sistema operacional"
    exit 1
fi

echo "Sistema detectado: $OS ${VERSION_ID:-}"

install_dependencies() {
    case "$OS" in
        ubuntu|debian)
            sudo apt-get update
            sudo apt-get install -y build-essential git stress-ng fio
            ;;
        fedora)
            sudo dnf install -y gcc-c++ make git stress-ng fio
            ;;
        rhel|centos|rocky|almalinux)
            sudo yum install -y gcc-c++ make git stress-ng fio
            ;;
        arch)
            sudo pacman -Sy --noconfirm base-devel git stress-ng fio
            ;;
        *)
            echo "✗ Sistema não suportado: $OS"
            echo "Instale manualmente: g++, stress-ng, fio"
            exit 1
            ;;
    esac
}

install_gpu_burn() {
    if command -v gpu-burn &> /dev/null; then
        echo "✓ gpu-burn já instalado"
        return 0
    fi

    echo "→ Instalando gpu-burn..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get install -y nvidia-cuda-toolkit || true
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y cuda-toolkit || true
    elif command -v yum &> /dev/null; then
        sudo yum install -y cuda || true
    fi

    local tmp
    tmp=$(mktemp -d)
    git clone https://github.com/wilicc/gpu-burn.git "$tmp" || return 1
    (cd "$tmp" && make) || return 1
    sudo install -m 755 "$tmp/gpu_burn" /usr/local/bin/gpu-burn || return 1
    rm -rf "$tmp"
    echo "✓ gpu-burn instalado em /usr/local/bin/gpu-burn"
}

verify_installation() {
    local ok=true
    for cmd in g++ stress-ng fio; do
        if command -v "$cmd" &> /dev/null; then
            echo "✓ $cmd"
        else
            echo "✗ $cmd NÃO encontrado"
            ok=false
        fi
    done
    $ok
}

install_dependencies

if $WITH_GPU; then
    install_gpu_burn || echo "Aviso: falha ao instalar gpu-burn. Instale manualmente se precisar de carga de GPU."
fi

verify_installation || { echo "✗ Dependências incompletas"; exit 1; }

echo "→ Compilando workload_generator..."
g++ -O2 -pthread -o workload_generator workload_generator.cpp
echo "✓ Pronto! Execute: ./workload_generator --help"
