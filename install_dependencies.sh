#!/bin/bash

# ============================================================================
# Script de Instalação de Dependências
# Instala todas as ferramentas necessárias para executar Bateria_testes.sh
# ============================================================================

set -e  # Parar em caso de erro

echo "================================================================="
echo " Instalador de Dependências - Workload Generator"
echo "================================================================="
echo ""

# Detectar o sistema operacional
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VER=$VERSION_ID
else
    echo "✗ Erro: Não foi possível detectar o sistema operacional"
    exit 1
fi

echo "Sistema detectado: $OS $VER"
echo ""

# Função para instalar dependências
install_dependencies() {
    case "$OS" in
        ubuntu|debian)
            echo "→ Instalando dependências para Ubuntu/Debian..."
            sudo apt-get update
            sudo apt-get install -y build-essential make git curl
            sudo apt-get install -y pcp 
          
            ;;
        
        fedora)
            echo "→ Instalando dependências para Fedora..."
            sudo dnf install -y gcc gcc-c++ make git curl
            sudo dnf install -y pcp pcp-gui
            
            ;;
        
        rhel|centos)
            echo "→ Instalando dependências para RHEL/CentOS..."
            sudo yum install -y gcc gcc-c++ make git curl
            sudo yum install -y pcp pcp-gui
           
            ;;
        
        arch)
            echo "→ Instalando dependências para Arch Linux..."
            sudo pacman -Sy
            sudo pacman -S --noconfirm base-devel
            sudo pacman -S --noconfirm pcp
           
            ;;
        
        *)
            echo "✗ Sistema operacional não suportado: $OS"
            echo "Por favor, instale manualmente:"
            echo "  - gcc/g++"
            echo "  - make"
            echo "  - PCP (Performance Co-Pilot)"
      
            exit 1
            ;;
    esac
}

# Função para verificar instalação
verify_installation() {
    echo ""
    echo "================================================================="
    echo " Verificando Instalação de Dependências"
    echo "================================================================="
    
    local all_ok=true
    
    if command -v g++ &> /dev/null; then
        echo "✓ G++ instalado: $(g++ --version | head -n 1)"
    else
        echo "✗ G++ NÃO instalado"
        all_ok=false
    fi
    
    if command -v make &> /dev/null; then
        echo "✓ Make instalado: $(make --version | head -n 1)"
    else
        echo "✗ Make NÃO instalado"
        all_ok=false
    fi
    
    if command -v pmrep &> /dev/null; then
        echo "✓ PCP (pmrep) instalado"
    else
        echo "✗ PCP (pmrep) NÃO instalado"
        all_ok=false
    fi

    echo ""
    
    if [ "$all_ok" = true ]; then
        return 0
    else
        return 1
    fi
}

# Função para compilar o workload_generator
compile_workload() {
    echo "================================================================="
    echo " Compilando workload_generator"
    echo "================================================================="
    
    if [ ! -f "workload_generator.cpp" ]; then
        echo "✗ Erro: workload_generator.cpp não encontrado"
        return 1
    fi
    
    echo "→ Compilando ..."
    g++ -o workload_generator workload_generator.cpp
    
    if [ -f "workload_generator" ]; then
        echo "✓ Compilação bem-sucedida!"
        ls -lh workload_generator
        return 0
    else
        echo "✗ Erro na compilação"
        return 1
    fi
}



# ============================================================================
# EXECUÇÃO PRINCIPAL
# ============================================================================


# Instalar dependências
install_dependencies

# Verificar instalação
if ! verify_installation; then
    echo ""
    echo "✗ Erro: Nem todas as dependências foram instaladas corretamente"
    exit 1
fi

# Compilar
if ! compile_workload; then
    echo ""
    echo "✗ Erro: Falha na compilação"
    exit 1
fi

echo ""
echo "================================================================="
echo " ✓ INSTALAÇÃO CONCLUÍDA COM SUCESSO!"
echo "================================================================="
echo ""
echo "Próximos passos:"
echo "  1. Execute a bateria de testes:"
echo "     ./Bateria_testes.sh"

echo "Os resultados serão salvos em: metricas_out/[Nome do Monitor]/"
echo "================================================================="
