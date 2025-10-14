#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Clover Compiler Builder v14.3 - Complete Version
# Based on stable v12.3 with proper repository management
# + Full compatibility with macOS Tahoe Beta (26.x)
# + Homebrew tools priority (git, bash, coreutils)
# + Enhanced AcpiParser fixes from v12.3
# + Fixed repository validation logic
# + NEW: Automatic Anaconda detection and activation
# + NEW: Automatic distutils.util error detection and fixing
# + NEW: Enhanced dependency checking and installation
# ============================================================================

SCRIPT_VERSION="14.3-fixed"
SCRIPT_NAME="Clover Compiler Builder"
WORKDIR="$HOME/src"
REPO_DIR="$WORKDIR/CloverBootloader"
CLOVER_REPO="https://github.com/CloverHackyColor/CloverBootloader.git"

# Color functions
say() { echo -e "\033[36m$*\033[0m"; }
ok() { echo -e "\033[32m✔ $*\033[0m"; }
warn() { echo -e "\033[33m⚠ $*\033[0m"; }
err() { echo -e "\033[31m✘ $*\033[0m"; }
info() { echo -e "\033[94mℹ $*\033[0m"; }

# Global variables
MACOS_VERSION=""
PYTHON_CMD=""
PYTHON_VERSION=""
PYTHON_PATH=""
DEPLOYMENT_TARGET=""

# Error handling
handle_error() {
    err "Script failed at line $1"
    exit 1
}
trap 'handle_error $LINENO' ERR

# --- util: sed inline flag (BSD vs GNU) + helpers ---
detect_sed_inplace_flag() {
    if sed --version >/dev/null 2>&1; then
        echo "-i"
    else
        echo "-i ''"
    fi
}
SED_INPLACE_FLAG=($(detect_sed_inplace_flag))

timestamp() { date +"%Y%m%d-%H%M%S"; }
backup_copy() { local f="$1"; local bk="${f}.backup.$(timestamp)"; cp "$f" "$bk"; echo "$bk"; }

# ============================================================================
# NEW: Prioritize Homebrew tools (fix for macOS Tahoe beta issues)
# ============================================================================
# Setup environment with Anaconda PATH
setup_environment() {
    say "=== Setting Up Environment ==="
    
    # Add Anaconda to PATH if it exists
    local anaconda_paths=(
        "/opt/anaconda3/bin"
        "$HOME/anaconda3/bin"
        "$HOME/opt/anaconda3/bin"
        "/usr/local/anaconda3/bin"
    )
    
    for path in "${anaconda_paths[@]}"; do
        if [ -d "$path" ]; then
            export PATH="$path:$PATH"
            ok "Anaconda PATH adicionado: $path"
            break
        fi
    done
    
    # Add Homebrew to PATH
    if [ -d "/opt/homebrew" ]; then
        export PATH="/opt/homebrew/bin:$PATH"
    elif [ -d "/usr/local/Homebrew" ]; then
        export PATH="/usr/local/bin:$PATH"
    fi
    
    # Prioritize system Git over old versions
    if [ -x "/usr/bin/git" ]; then
        export PATH="/usr/bin:$PATH"
        ok "Sistema Git priorizado: /usr/bin/git"
    else
        # Se não tem Git do sistema, instalar via Homebrew
        if command -v brew >/dev/null 2>&1; then
            warn "Git do sistema não encontrado. Instalando Git moderno..."
            brew install git
            ok "Git moderno instalado via Homebrew"
        fi
    fi
    
    ok "Environment configured"
}

setup_homebrew_environment() {
    say "=== Setting Up Homebrew Environment ==="
    
    # Detect Homebrew installation
    local brew_prefix=""
    if [ -d "/opt/homebrew" ]; then
        brew_prefix="/opt/homebrew"
    elif [ -d "/usr/local/Homebrew" ]; then
        brew_prefix="/usr/local"
    fi
    
    if [ -n "$brew_prefix" ]; then
        # Prioritize Homebrew tools over system tools
        export PATH="${brew_prefix}/bin:${brew_prefix}/opt/coreutils/libexec/gnubin:$PATH"
        
        # Check if critical tools are from Homebrew
        local git_path=$(which git 2>/dev/null || echo "")
        local bash_path=$(which bash 2>/dev/null || echo "")
        
        if [[ "$git_path" == "${brew_prefix}"* ]]; then
            ok "Using Homebrew git: $git_path"
        else
            warn "System git detected. Installing Homebrew git for stability..."
            brew install git 2>/dev/null || true
        fi
        
        if [[ "$bash_path" == "${brew_prefix}"* ]]; then
            ok "Using Homebrew bash: $bash_path"
        else
            info "System bash detected. Consider: brew install bash"
        fi
        
        # Install coreutils if not present
        if ! brew list coreutils >/dev/null 2>&1; then
            info "Installing coreutils for better compatibility..."
            brew install coreutils 2>/dev/null || true
        fi
        
        ok "Homebrew tools prioritized"
    else
        warn "Homebrew not found. System tools will be used."
        info "For better stability on macOS Tahoe: brew install git bash coreutils"
    fi
}

# Intelligent GNU binaries management with verification
manage_gnu_binaries() {
    say "=== Intelligent GNU Binaries Management ==="
    
    local safe_binaries="$HOME/src-binaries"
    local download_dir="$REPO_DIR/toolchain/tools/download"
    
    info "Checking for binaries in: $download_dir"
    
    # Function to verify binary copy was successful
    verify_binary_copy() {
        local source_dir="$1"
        local dest_dir="$2"
        local source_count=$(find "$source_dir" -name "*.tar.gz" -o -name "*.tar.xz" 2>/dev/null | wc -l | tr -d ' ')
        local dest_count=$(find "$dest_dir" -name "*.tar.gz" -o -name "*.tar.xz" 2>/dev/null | wc -l | tr -d ' ')
        
        if [ "$source_count" -eq "$dest_count" ] && [ "$dest_count" -gt 0 ]; then
            ok "Binary copy verified: $dest_count files copied successfully"
            return 0
        else
            warn "Binary copy verification failed: expected $source_count, got $dest_count"
            return 1
        fi
    }
    
    # Check if download directory exists and has binaries
    if [ -d "$download_dir" ]; then
        local count
        count=$(find "$download_dir" -name "*.tar.gz" -o -name "*.tar.xz" 2>/dev/null | wc -l | tr -d ' ')
        
        if [ "$count" -gt 0 ]; then
            ok "Found $count binary files in download folder"
            
            # Check if we have saved binaries
            local saved_count=0
            if [ -d "$safe_binaries" ]; then
                saved_count=$(find "$safe_binaries" -name "*.tar.gz" -o -name "*.tar.xz" 2>/dev/null | wc -l | tr -d ' ')
            fi
            
            if [ "$saved_count" -gt 0 ]; then
                info "Also found $saved_count saved binaries in src-binaries"
            fi
            
            echo
            echo "Binaries Management Options:"
            echo "1) Use current binaries in download folder"
            echo "2) Save current binaries to src-binaries for future use"
            if [ "$saved_count" -gt 0 ]; then
                echo "3) Use saved binaries from src-binaries (replace current)"
            fi
            echo
            
            local choice
            if [ "$saved_count" -gt 0 ]; then
                read -p "Choose option (1-3): " choice
            else
                read -p "Choose option (1-2): " choice
            fi
            
            case "$choice" in
                1)
                    ok "Using current binaries in download folder"
                    ;;
                2)
                    mkdir -p "$safe_binaries"
                    cp "$download_dir"/*.tar.* "$safe_binaries/" 2>/dev/null
                    if verify_binary_copy "$download_dir" "$safe_binaries"; then
                        ok "Binaries saved to src-binaries for future use"
                    else
                        warn "Failed to save all binaries to src-binaries"
                    fi
                    ;;
                3)
                    if [ "$saved_count" -gt 0 ]; then
                        # Create backup of current binaries
                        local backup_dir="$download_dir.backup.$(date +%Y%m%d-%H%M%S)"
                        if [ "$count" -gt 0 ]; then
                            mkdir -p "$backup_dir"
                            cp "$download_dir"/*.tar.* "$backup_dir/" 2>/dev/null
                            info "Current binaries backed up to: $backup_dir"
                        fi
                        
                        # Copy saved binaries to download folder
                        mkdir -p "$download_dir"
                        cp "$safe_binaries"/*.tar.* "$download_dir/" 2>/dev/null
                        if verify_binary_copy "$safe_binaries" "$download_dir"; then
                            ok "Saved binaries restored to download folder"
                        else
                            warn "Failed to restore all saved binaries"
                            # Restore backup if copy failed
                            if [ -d "$backup_dir" ]; then
                                cp "$backup_dir"/*.tar.* "$download_dir/" 2>/dev/null
                                info "Restored backup binaries"
                            fi
                        fi
                    else
                        warn "No saved binaries found"
                    fi
                    ;;
                *)
                    ok "Using current binaries in download folder"
                    ;;
            esac
        else
            warn "No binary files found in download folder"
            
            # Check for saved binaries
            if [ -d "$safe_binaries" ]; then
                local saved_count
                saved_count=$(find "$safe_binaries" -name "*.tar.gz" -o -name "*.tar.xz" 2>/dev/null | wc -l | tr -d ' ')
                if [ "$saved_count" -gt 0 ]; then
                    echo
                    echo "Found $saved_count saved binaries in src-binaries"
                    read -p "Restore saved binaries? (y/N): " choice
                    case "$choice" in
                        [Yy]*)
                            mkdir -p "$download_dir"
                            cp "$safe_binaries"/*.tar.* "$download_dir/" 2>/dev/null
                            if verify_binary_copy "$safe_binaries" "$download_dir"; then
                                ok "Saved binaries restored successfully"
                            else
                                warn "Failed to restore all saved binaries"
                            fi
                            ;;
                        *)
                            info "Will download fresh binaries during build"
                            ;;
                    esac
                else
                    info "No saved binaries found. Will download fresh during build"
                fi
            else
                info "Will download fresh binaries during build"
            fi
        fi
    else
        info "Download directory will be created during build"
        
        # Check for saved binaries to restore
        if [ -d "$safe_binaries" ]; then
            local saved_count
            saved_count=$(find "$safe_binaries" -name "*.tar.gz" -o -name "*.tar.xz" 2>/dev/null | wc -l | tr -d ' ')
            if [ "$saved_count" -gt 0 ]; then
                echo
                echo "Found $saved_count saved binaries in src-binaries"
                read -p "Create download folder and restore saved binaries? (y/N): " choice
                case "$choice" in
                    [Yy]*)
                        mkdir -p "$download_dir"
                        cp "$safe_binaries"/*.tar.* "$download_dir/" 2>/dev/null
                        if verify_binary_copy "$safe_binaries" "$download_dir"; then
                            ok "Download folder created and saved binaries restored successfully"
                        else
                            warn "Failed to restore all saved binaries"
                        fi
                        ;;
                    *)
                        info "Will download fresh binaries during build"
                        ;;
                esac
            fi
        fi
    fi
    
    # Final verification before continuing
    if [ -d "$download_dir" ]; then
        local final_count
        final_count=$(find "$download_dir" -name "*.tar.gz" -o -name "*.tar.xz" 2>/dev/null | wc -l | tr -d ' ')
        if [ "$final_count" -gt 0 ]; then
            ok "Ready for build: $final_count binaries available in download folder"
        else
            info "No binaries in download folder - buildme will download as needed"
        fi
    fi
    
    echo
}

# Auto-save successful binaries after compilation
auto_save_binaries() {
    say "=== Auto-saving Binaries ==="
    
    local safe_binaries="$HOME/src-binaries"
    local download_dir="$REPO_DIR/toolchain/tools/download"
    
    # Check if compilation was successful and binaries exist
    if [ -d "$download_dir" ] && [ -f "$REPO_DIR/BaseTools/Source/C/bin/GenFw" ]; then
        local count
        count=$(find "$download_dir" -name "*.tar.gz" -o -name "*.tar.xz" 2>/dev/null | wc -l | tr -d ' ')
        
        if [ "$count" -gt 0 ]; then
            mkdir -p "$safe_binaries"
            cp "$download_dir"/*.tar.* "$safe_binaries/" 2>/dev/null
            ok "Successfully compiled binaries saved to src-binaries"
            info "Next time you can use these binaries for faster setup"
        fi
    fi
}

# Detect macOS version
detect_macos() {
    say "=== Detecting macOS Version ==="
    
    if command -v sw_vers >/dev/null 2>&1; then
        MACOS_VERSION=$(sw_vers -productVersion)
        local major=$(echo "$MACOS_VERSION" | cut -d. -f1)
        
        case "$major" in
            "26"|"27")
                DEPLOYMENT_TARGET="14.0"
                warn "macOS Tahoe Beta detected ($MACOS_VERSION)"
                info "Using stable Homebrew tools recommended"
                ;;
            "15") DEPLOYMENT_TARGET="14.0" ;;
            "14") DEPLOYMENT_TARGET="13.0" ;;
            "13") DEPLOYMENT_TARGET="12.0" ;;
            "12") DEPLOYMENT_TARGET="11.0" ;;
            *) DEPLOYMENT_TARGET="14.0" ;;
        esac
        
        info "macOS: $MACOS_VERSION, Deployment Target: $DEPLOYMENT_TARGET"
    else
        err "Cannot detect macOS version"
        exit 1
    fi
}

# ============================================================================
# NOVO: Verificador de Dependências Python/Anaconda
# ============================================================================

# Verificar se Anaconda está instalado
check_anaconda() {
    local anaconda_found=false
    
    # Verificar conda no PATH
    if command -v conda >/dev/null 2>&1; then
        local conda_info=$(conda info --envs 2>/dev/null | grep -E "base|root" | head -1)
        if [ -n "$conda_info" ]; then
            anaconda_found=true
            info "Anaconda/Conda encontrado no PATH"
        fi
    fi
    
    # Verificar instalações típicas do Anaconda
    local anaconda_paths=(
        "/opt/anaconda3"
        "$HOME/anaconda3"
        "$HOME/opt/anaconda3"
        "/usr/local/anaconda3"
        "/Applications/Anaconda-Navigator.app"
    )
    
    for path in "${anaconda_paths[@]}"; do
        if [ -d "$path" ]; then
            anaconda_found=true
            info "Anaconda encontrado em: $path"
            break
        fi
    done
    
    if [ "$anaconda_found" = true ]; then
        # Tentar ativar o ambiente base
        if command -v conda >/dev/null 2>&1; then
            info "Ativando ambiente Anaconda base..."
            eval "$(conda shell.bash hook)" 2>/dev/null || true
            conda activate base 2>/dev/null || true
            ok "Ambiente Anaconda ativado"
        else
            warn "Anaconda instalado mas conda não está no PATH"
            info "Adicione ao ~/.zshrc: export PATH=\"\$HOME/anaconda3/bin:\$PATH\""
        fi
    fi
    
    return $([ "$anaconda_found" = true ] && echo 0 || echo 1)
}

# Verificar se distutils.util está disponível
check_distutils() {
    local python_cmd="$1"
    
    if [ -z "$python_cmd" ]; then
        return 1
    fi
    
    # Testar importação do distutils.util
    if "$python_cmd" -c "import distutils.util" 2>/dev/null; then
        return 0  # Disponível
    else
        return 1  # Não disponível
    fi
}

# Instalar setuptools automaticamente - VERSÃO ROBUSTA
install_setuptools() {
    local python_cmd="$1"
    
    if [ -z "$python_cmd" ]; then
        err "Comando Python não especificado para instalação do setuptools"
        return 1
    fi
    
    say "=== Instalando setuptools (versão robusta) ==="
    
    # Verificar se pip está disponível
    if ! "$python_cmd" -m pip --version >/dev/null 2>&1; then
        warn "pip não encontrado. Tentando instalar..."
        
        # Instalar pip via Homebrew se disponível
        if command -v brew >/dev/null 2>&1; then
            info "Instalando pip via Homebrew..."
            brew install python-pip 2>/dev/null || true
        fi
        
        # Ou instalar pip via get-pip.py
        if ! "$python_cmd" -m pip --version >/dev/null 2>&1; then
            info "Baixando get-pip.py..."
            curl -sSL https://bootstrap.pypa.io/get-pip.py | "$python_cmd" 2>/dev/null || true
        fi
    fi
    
    # Tentar múltiplas formas de instalar setuptools
    info "Tentando instalar setuptools..."
    
    # Método 1: pip install
    if "$python_cmd" -m pip install setuptools --user 2>/dev/null; then
        ok "setuptools instalado via pip --user"
    elif "$python_cmd" -m pip install setuptools 2>/dev/null; then
        ok "setuptools instalado via pip"
    else
        # Método 2: easy_install
        if command -v easy_install >/dev/null 2>&1; then
            info "Tentando easy_install..."
            easy_install setuptools 2>/dev/null || true
        fi
        
        # Método 3: Homebrew
        if command -v brew >/dev/null 2>&1; then
            info "Tentando via Homebrew..."
            brew install python-setuptools 2>/dev/null || true
        fi
    fi
    
    # Verificar se funcionou
    if "$python_cmd" -c "import distutils.util" 2>/dev/null; then
        ok "✅ distutils.util agora está disponível!"
        return 0
    else
        warn "setuptools instalado mas distutils.util ainda não funciona"
        return 1
    fi
}

# Verificar e corrigir problema do distutils
fix_distutils_issue() {
    local python_cmd="$1"
    
    if [ -z "$python_cmd" ]; then
        err "Comando Python não especificado"
        return 1
    fi
    
    # Debug: mostrar qual comando está sendo usado
    info "Testando distutils.util com: $python_cmd"
    
    if check_distutils "$python_cmd"; then
        ok "distutils.util está funcionando corretamente ($python_cmd)"
        return 0
    fi
    
    warn "distutils.util não está disponível - isso causará erro na compilação!"
    echo
    info "Este é um problema comum em Python 3.12+ onde distutils foi removido."
    echo
    
    # Tentar instalar setuptools
    if install_setuptools "$python_cmd"; then
        return 0
    fi
    
    # Se falhou, mostrar alternativas
    echo
    warn "Não foi possível corrigir automaticamente. Alternativas:"
    echo
    info "1) Instalar Anaconda 3.9.x (recomendado):"
    info "   - Intel: https://repo.anaconda.com/archive/Anaconda3-2021.11-MacOSX-x86_64.pkg"
    info "   - ARM64: https://repo.anaconda.com/archive/Anaconda3-2022.05-MacOSX-arm64.pkg"
    echo
    info "2) Usar Python mais antigo:"
    info "   brew install python@3.9"
    echo
    info "3) Instalar manualmente:"
    info "   $python_cmd -m pip install setuptools"
    echo
    
    read -p "Deseja continuar mesmo assim? (s/N): " answer
    case "$answer" in
        [Ss]*)
            warn "Continuando sem distutils.util - pode falhar na compilação"
            return 0
            ;;
        *)
            err "Abortando por falta de distutils.util"
            exit 1
            ;;
    esac
}

# Configure Python with enhanced dependency checking
configure_python() {
    say "=== Python Detection & Dependency Check ==="
    
    local found=false
    local anaconda_available=false
    
    # Primeiro, verificar se Anaconda está disponível E é compatível
    if check_anaconda; then
        # Verificar se o Python do Anaconda é compatível (tem distutils)
        local anaconda_python=""
        if command -v conda >/dev/null 2>&1; then
            anaconda_python=$(conda run python -c "import sys; print(sys.executable)" 2>/dev/null || echo "")
        fi
        
        if [ -n "$anaconda_python" ]; then
            local anaconda_version=$("$anaconda_python" --version 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | cut -d' ' -f2)
            local major_version=$(echo "$anaconda_version" | cut -d. -f1)
            local minor_version=$(echo "$anaconda_version" | cut -d. -f2)
            
            # Python 3.12+ não tem distutils nativo
            if [ "$major_version" -eq 3 ] && [ "$minor_version" -ge 12 ]; then
                warn "Anaconda Python $anaconda_version detectado - mas não tem distutils nativo"
                info "Vamos usar Python do sistema ou instalar Python 3.9"
                anaconda_available=false
            else
                anaconda_available=true
                info "Anaconda Python $anaconda_version detectado - será priorizado"
            fi
        else
            anaconda_available=false
            warn "Anaconda detectado mas Python não acessível"
        fi
    else
        warn "Anaconda não encontrado - usando Python do sistema"
        info "Para melhor compatibilidade, instale Anaconda 3.9.x"
    fi
    
    # Buscar Python (priorizando Anaconda se disponível)
    local search_commands=()
    
    if [ "$anaconda_available" = true ]; then
        # Se Anaconda está disponível, priorizar seus Pythons
        search_commands=(python python3 conda python3.9 python3.10 python3.11 python3.12 python3.13)
    else
        # Caso contrário, buscar no sistema
        search_commands=(python3.9 python3.10 python3.11 python3.12 python3.13 python3 python)
    fi
    
    for cmd in "${search_commands[@]}"; do
        if command -v "$cmd" >/dev/null 2>&1; then
            local version=$("$cmd" --version 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | cut -d' ' -f2)
            
            # Verificar se é uma versão compatível
            if echo "$version" | grep -qE "^3\.(9|10|11|12|13)\."; then
                PYTHON_CMD="$cmd"
                PYTHON_VERSION="$version"
                PYTHON_PATH=$(which "$cmd")
                found=true
                
                if [ "$anaconda_available" = true ]; then
                    ok "Python do Anaconda: $PYTHON_CMD ($version)"
                else
                    info "Python do sistema: $PYTHON_CMD ($version)"
                fi
                break
            fi
        fi
    done
    
    # Se não encontrou Python compatível, NÃO instalar automaticamente
    if [ "$found" = false ]; then
        warn "Nenhum Python compatível encontrado!"
        echo
        err "Python compatível é obrigatório para compilar Clover"
        echo
        info "SOLUÇÕES RECOMENDADAS:"
        info "1) Instalar Anaconda 3.9.x (RECOMENDADO):"
        info "   - Intel: https://repo.anaconda.com/archive/Anaconda3-2021.11-MacOSX-x86_64.pkg"
        info "   - ARM64: https://repo.anaconda.com/archive/Anaconda3-2022.05-MacOSX-arm64.pkg"
        echo
        info "2) Ou instalar Python 3.9 via Homebrew:"
        info "   brew install python@3.9"
        echo
        info "Execute este script novamente após instalar Python compatível!"
        exit 1
    fi
    
    # Verificar e corrigir distutils.util
    if [ "$found" = true ]; then
        fix_distutils_issue "$PYTHON_CMD"
    fi
    
    export PYTHON_CMD PYTHON_VERSION PYTHON_PATH
    ok "Python configurado: $PYTHON_CMD ($PYTHON_VERSION)"
}

# Install Homebrew
install_homebrew() {
    say "=== Installing Homebrew ==="
    
    if command -v brew >/dev/null 2>&1; then
        info "Homebrew found, updating..."
        brew update || warn "Update failed"
    else
        warn "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add to PATH
        if [ -x /opt/homebrew/bin/brew ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [ -x /usr/local/bin/brew ]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi
    ok "Homebrew ready"
}

# Install Python 3.9 with setuptools
install_python39() {
    say "=== Installing Python 3.9 + setuptools ==="
    
    # Instalar Homebrew se necessário
    if ! command -v brew >/dev/null 2>&1; then
        install_homebrew
    fi
    
    # Instalar Python 3.9
    info "Instalando Python 3.9..."
    if brew install python@3.9; then
        ok "Python 3.9 instalado com sucesso!"
        
        # Verificar se setuptools está disponível
        if ! python3.9 -c "import distutils.util" 2>/dev/null; then
            info "Instalando setuptools para Python 3.9..."
            python3.9 -m pip install setuptools 2>/dev/null || {
                warn "Falha ao instalar setuptools via pip, tentando via Homebrew..."
                brew install python-setuptools 2>/dev/null || true
            }
        fi
        
        # Verificar se funcionou
        if python3.9 -c "import distutils.util" 2>/dev/null; then
            ok "✅ Python 3.9 + setuptools funcionando!"
        else
            warn "Python 3.9 instalado mas setutils.util não funciona"
        fi
    else
        err "Falha ao instalar Python 3.9"
        return 1
    fi
}

# Verificar e corrigir Xcode Command Line Tools
verify_and_fix_xcode() {
    say "=== Verificação do Xcode Command Line Tools ==="
    
    local xcode_path=""
    local needs_reinstall=false
    
    # Verificar se está instalado
    if xcode-select -p >/dev/null 2>&1; then
        xcode_path=$(xcode-select -p)
        ok "Xcode Command Line Tools encontrado: $xcode_path"
        
        # Verificar se o make funciona
        if ! command -v make >/dev/null 2>&1; then
            err "comando 'make' não encontrado!"
            needs_reinstall=true
        elif ! make --version >/dev/null 2>&1; then
            err "'make' não funciona corretamente!"
            needs_reinstall=true
        else
            local make_version=$(make --version 2>&1 | head -1)
            ok "make funcionando: $make_version"
        fi
        
        # Verificar se o gcc funciona
        if ! command -v gcc >/dev/null 2>&1; then
            warn "comando 'gcc' não encontrado!"
            needs_reinstall=true
        fi
        
    else
        err "Xcode Command Line Tools NÃO instalado!"
        needs_reinstall=true
    fi
    
    # Reinstalar se necessário
    if [ "$needs_reinstall" = true ]; then
        echo
        warn "⚠️  Xcode Command Line Tools precisa ser instalado/corrigido!"
        echo
        info "Isso causará erros como:"
        info "  • 'usr/bin/make -C' error"
        info "  • 'command not found: gcc'"
        info "  • Falha na compilação dos BaseTools"
        echo
        
        read -p "Deseja corrigir automaticamente? (s/N): " answer
        case "$answer" in
            [Ss]*)
                say "=== Corrigindo Xcode Command Line Tools ==="
                
                # Remover instalação corrompida
                if [ -d "/Library/Developer/CommandLineTools" ]; then
                    info "Removendo instalação corrompida..."
                    sudo rm -rf /Library/Developer/CommandLineTools
                fi
                
                # Resetar xcode-select
                info "Resetando xcode-select..."
                sudo xcode-select --reset 2>/dev/null || true
                
                # Instalar novamente
                info "Instalando Xcode Command Line Tools..."
                xcode-select --install
                
                echo
                warn "⚠️  IMPORTANTE:"
                info "1. Uma janela vai abrir para instalar o Xcode Command Line Tools"
                info "2. Clique em 'Instalar' e aguarde a instalação completa"
                info "3. Após a instalação, pressione Enter aqui para continuar"
                echo
                read -p "Pressione Enter após completar a instalação..." dummy
                
                # Verificar se funcionou
                if xcode-select -p >/dev/null 2>&1 && command -v make >/dev/null 2>&1; then
                    # Aceitar licença
                    info "Aceitando licença do Xcode..."
                    sudo xcodebuild -license accept 2>/dev/null || true
                    
                    ok "✅ Xcode Command Line Tools instalado com sucesso!"
                    
                    # Mostrar versões
                    local make_ver=$(make --version 2>&1 | head -1)
                    local gcc_ver=$(gcc --version 2>&1 | head -1)
                    info "make: $make_ver"
                    info "gcc: $gcc_ver"
                else
                    err "Instalação falhou. Tente manualmente:"
                    info "  sudo rm -rf /Library/Developer/CommandLineTools"
                    info "  xcode-select --install"
                    exit 1
                fi
                ;;
            *)
                err "Xcode Command Line Tools é obrigatório para compilar Clover"
                echo
                info "Corrija manualmente:"
                info "  1. sudo rm -rf /Library/Developer/CommandLineTools"
                info "  2. xcode-select --install"
                info "  3. Execute este script novamente"
                exit 1
                ;;
        esac
    else
        ok "Xcode Command Line Tools verificado e funcionando!"
    fi
}

# Install development tools
install_dev_tools() {
    say "=== Installing Development Tools ==="
    
    # Verificar e corrigir Xcode primeiro
    verify_and_fix_xcode
    
    # Git
    if ! command -v git >/dev/null 2>&1; then
        brew install git
    fi
    
    # Build tools
    local tools="cmake ninja nasm"
    for tool in $tools; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            brew install "$tool" || warn "Failed to install $tool"
        fi
    done
    
    ok "Development tools ready"
}

# Create Python symlinks
create_python_symlinks() {
    say "=== Creating Python Symlinks ==="
    
    if [ ! -e /usr/local/bin/python ] || [ ! -e /usr/local/bin/python3 ]; then
        say "Creating Python symlinks (requires sudo)..."
        sudo mkdir -p /usr/local/bin
        
        if [ ! -e /usr/local/bin/python ]; then
            sudo ln -sf "$PYTHON_PATH" /usr/local/bin/python
        fi
        
        if [ ! -e /usr/local/bin/python3 ]; then
            sudo ln -sf "$PYTHON_PATH" /usr/local/bin/python3
        fi
        
        ok "Python symlinks created"
    else
        ok "Python symlinks already exist"
    fi
}

# ============================================================================
# FIXED: Repository validation - checks for actual content
# ============================================================================
validate_repository_structure() {
    local repo_path="$1"
    
    # Check critical directories and files
    if [ ! -d "$repo_path/BaseTools" ]; then
        return 1
    fi
    
    if [ ! -f "$repo_path/buildme" ]; then
        return 1
    fi
    
    if [ ! -d "$repo_path/OpenCorePkg" ]; then
        return 1
    fi
    
    return 0
}

# Manage repository - FIXED VERSION
manage_repository() {
    say "=== Managing Clover Repository ==="
    
    mkdir -p "$WORKDIR"
    cd "$WORKDIR"
    
    local repo_was_deleted=false
    
    if [ -d "$REPO_DIR" ]; then
        warn "Repository exists: $REPO_DIR"
        
        # Validate repository structure
        if validate_repository_structure "$REPO_DIR"; then
            ok "Repository structure validated"
            echo "1) Delete and clone fresh"
            echo "2) Update existing"
            echo "3) Use as is"
        else
            err "Repository structure is incomplete or corrupted"
            echo "1) Delete and clone fresh"
            echo "2) Try to repair (git pull + submodules)"
            warn "Option 3 not available - repository invalid"
        fi
        
        read -p "Choice (1-3 or 1-2): " choice
        
        case "$choice" in
            1)
                rm -rf "$REPO_DIR"
                git clone --recurse-submodules "$CLOVER_REPO" "$REPO_DIR"
                cd "$REPO_DIR"
                repo_was_deleted=true
                ;;
            2)
                cd "$REPO_DIR"
                if [ -d ".git" ]; then
                    git pull --recurse-submodules || warn "Update failed"
                    git submodule update --init --recursive || warn "Submodule update failed"
                else
                    err "Not a git repository. Cloning fresh..."
                    cd "$WORKDIR"
                    rm -rf "$REPO_DIR"
                    git clone --recurse-submodules "$CLOVER_REPO" "$REPO_DIR"
                    cd "$REPO_DIR"
                    repo_was_deleted=true
                fi
                ;;
            3)
                if validate_repository_structure "$REPO_DIR"; then
                    cd "$REPO_DIR"
                    ok "Using existing repository"
                else
                    err "Repository invalid. Please choose option 1 or 2"
                    exit 1
                fi
                ;;
            *)
                err "Invalid choice"
                exit 1
                ;;
        esac
    else
        git clone --recurse-submodules "$CLOVER_REPO" "$REPO_DIR"
        cd "$REPO_DIR"
        repo_was_deleted=true
    fi
    
    # Final validation
    if ! validate_repository_structure "$REPO_DIR"; then
        err "Repository validation failed after setup"
        err "Critical files missing. Please run script again and choose option 1"
        exit 1
    fi
    
    # Check for binary restoration after repository recreation
    if [ "$repo_was_deleted" = true ]; then
        local safe_binaries="$HOME/src-binaries"
        local download_dir="$REPO_DIR/toolchain/tools/download"
        
        if [ -d "$safe_binaries" ]; then
            local saved_count
            saved_count=$(find "$safe_binaries" -name "*.tar.gz" -o -name "*.tar.xz" 2>/dev/null | wc -l | tr -d ' ')
            if [ "$saved_count" -gt 0 ]; then
                echo
                info "Repository was recreated. Found $saved_count saved binaries in src-binaries"
                read -p "Restore saved binaries to avoid downloads? (y/N): " choice
                case "$choice" in
                    [Yy]*)
                        mkdir -p "$download_dir"
                        cp "$safe_binaries"/*.tar.* "$download_dir/" 2>/dev/null
                        ok "Saved binaries restored to new repository"
                        ;;
                    *)
                        info "Will download fresh binaries during build"
                        ;;
                esac
            fi
        fi
    fi
    
    ok "Repository ready"
}

# Apply source fixes - ENHANCED VERSION from v12.3
apply_source_fixes() {
    say "=== Applying Source Code Fixes ==="
    
    # AcpiParser.h fix
    local acpi_h="OpenCorePkg/Library/OcAcpiLib/AcpiParser.h"
    if [ -f "$acpi_h" ]; then
        if grep -q "//  DEBUG (( \\\\" "$acpi_h"; then
            [ ! -f "${acpi_h}.backup" ] && cp "$acpi_h" "${acpi_h}.backup"
            sed ${SED_INPLACE_FLAG[@]} 's|//  DEBUG (( \\\\|/*  DEBUG (( |g' "$acpi_h"
            # Fix closing comment
            local i=1
            while [ $i -le 10 ] && grep -q "))" "$acpi_h" && ! grep -q ")) */" "$acpi_h"; do
                sed ${SED_INPLACE_FLAG[@]} '0,/))/s/))/) */' "$acpi_h"
                i=$((i + 1))
            done
            ok "AcpiParser.h fixed"
        fi
    fi
    
    # AcpiParser.c fix - COMPLETE VERSION
    local acpi_c="OpenCorePkg/Library/OcAcpiLib/AcpiParser.c"
    if [ -f "$acpi_c" ]; then
        # Make backup
        [ ! -f "${acpi_c}.backup" ] && cp "$acpi_c" "${acpi_c}.backup"
        
        # Check if needs fixing
        if grep -q "ScopeNameStart" "$acpi_c" && ! grep -q "Fixed by v14.0" "$acpi_c"; then
            info "Applying comprehensive AcpiParser.c fixes..."
            
            # Comment out variable declaration
            sed ${SED_INPLACE_FLAG[@]} 's/^  UINT8       \*ScopeNameStart;/  \/\/ UINT8       *ScopeNameStart; \/\/ Fixed by v14.0/' "$acpi_c"
            
            # Comment out all assignments to ScopeNameStart
            sed ${SED_INPLACE_FLAG[@]} '/ScopeNameStart.*=/s/^/\/\/ /' "$acpi_c"
            
            # Comment out all lines that use ScopeNameStart (but not assignments)
            sed ${SED_INPLACE_FLAG[@]} '/ScopeNameStart/s/^/\/\/ /' "$acpi_c"
            
            # Verify fix
            if grep -n "ScopeNameStart" "$acpi_c" | grep -v "^[[:space:]]*//" >/dev/null 2>&1; then
                warn "Some ScopeNameStart references may still be active"
                info "Manual verification recommended"
            else
                ok "AcpiParser.c - ALL ScopeNameStart references commented out"
            fi
        else
            ok "AcpiParser.c already fixed or no issues found"
        fi
    fi
    
    # Additional common compilation fixes
    local acpi_dump="OpenCorePkg/Library/OcAcpiLib/OcAcpiLib.c"
    if [ -f "$acpi_dump" ]; then
        # Fix potential unused variable warnings
        if grep -q "UINT.*Unused" "$acpi_dump" && ! grep -q "__attribute__((unused))" "$acpi_dump"; then
            [ ! -f "${acpi_dump}.backup" ] && cp "$acpi_dump" "${acpi_dump}.backup"
            sed ${SED_INPLACE_FLAG[@]} 's/UINT\([0-9]*\) \+\([^;]*Unused[^;]*\);/UINT\1 \2 __attribute__((unused));/g' "$acpi_dump"
            info "Applied unused variable attributes to OcAcpiLib.c"
        fi
    fi
}

# Configure toolchain
configure_toolchain() {
    say "=== Configuring Toolchain ==="
    
    local tools_def="BaseTools/Conf/tools_def.template"
    if [ -f "$tools_def" ]; then
        [ ! -f "${tools_def}.backup" ] && cp "$tools_def" "${tools_def}.backup"
        
        # Enhanced GCC flags with additional error suppressions
        local gcc_flags="-Wno-error=unused-but-set-variable -Wno-error=comment -Wno-error=deprecated-non-prototype -Wno-error=unused-variable -Wno-error=incompatible-pointer-types"
        
        for arch in IA32 X64 ARM AARCH64; do
            if grep -q "GCC151_${arch}_CC_FLAGS" "$tools_def"; then
                sed ${SED_INPLACE_FLAG[@]} "/GCC151_${arch}_CC_FLAGS/s/$/ $gcc_flags/" "$tools_def"
            fi
        done
        
        # XCODE fixes
        sed ${SED_INPLACE_FLAG[@]} -E 's/(XCODE[0-9]*_.*OBJECT_FILE_SUFFIX[[:space:]]*=[[:space:]]*)\.obj/\1.o/g' "$tools_def"
        sed ${SED_INPLACE_FLAG[@]} -E 's/(XCODE[0-9]*_.*STATIC_LIBRARY_SUFFIX[[:space:]]*=[[:space:]]*)\.lib/\1.a/g' "$tools_def"
        sed ${SED_INPLACE_FLAG[@]} -E 's/(XCODE[0-9]*_.*SLINK[[:space:]]*=[[:space:]]*).*libtool.*/\1libtool -static -o/g' "$tools_def"
        
        ok "Toolchain configured with enhanced error handling"
    fi
}

# Setup build environment
setup_build_environment() {
    say "=== Setting Up Build Environment ==="
    
    export WORKSPACE="$REPO_DIR"
    export EDK_TOOLS_PATH="$REPO_DIR/BaseTools"
    export MACOSX_DEPLOYMENT_TARGET="$DEPLOYMENT_TARGET"
    export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
    
    info "WORKSPACE: $WORKSPACE"
    info "Python: $PYTHON_CMD ($PYTHON_VERSION)"
    info "Deployment: $DEPLOYMENT_TARGET"
    
    ok "Environment configured"
}

# Compile BaseTools
compile_basetools() {
    say "=== Compiling BaseTools ==="
    
    cd BaseTools
    make clean || true
    if make; then
        ok "BaseTools compiled successfully"
    else
        err "BaseTools compilation failed"
        exit 1
    fi
    cd ..
    
    # Verify critical tools
    local tools="BaseTools/Source/C/bin/GenFw BaseTools/Source/C/bin/VfrCompile"
    for tool in $tools; do
        if [ ! -f "$tool" ]; then
            err "Missing: $tool"
            exit 1
        fi
    done
    
    ok "BaseTools verification passed"
}

# Configure Conf directory
configure_conf() {
    say "=== Configuring Conf Directory ==="
    
    mkdir -p Conf
    
    # Copy templates
    if [ -f "BaseTools/Conf/tools_def.template" ]; then
        cp "BaseTools/Conf/tools_def.template" "Conf/tools_def.txt"
    fi
    if [ -f "BaseTools/Conf/target.template" ]; then
        cp "BaseTools/Conf/target.template" "Conf/target.txt"
    fi
    if [ -f "BaseTools/Conf/build_rule.template" ]; then
        cp "BaseTools/Conf/build_rule.template" "Conf/build_rule.txt"
    fi
    
    # Apply XCODE fixes to active config
    if [ -f "Conf/tools_def.txt" ]; then
        sed ${SED_INPLACE_FLAG[@]} -E 's/(XCODE[0-9]*_.*OBJECT_FILE_SUFFIX[[:space:]]*=[[:space:]]*)\.obj/\1.o/g' "Conf/tools_def.txt"
        sed ${SED_INPLACE_FLAG[@]} -E 's/(XCODE[0-9]*_.*STATIC_LIBRARY_SUFFIX[[:space:]]*=[[:space:]]*)\.lib/\1.a/g' "Conf/tools_def.txt"
        sed ${SED_INPLACE_FLAG[@]} -E 's/(XCODE[0-9]*_.*SLINK[[:space:]]*=[[:space:]]*).*libtool.*/\1libtool -static -o/g' "Conf/tools_def.txt"
    fi
    
    ok "Conf directory configured"
}

# Patch buildme (includes stdin fix)
patch_buildme() {
    say "=== Patching buildme Script ==="
    
    if [ ! -f "buildme" ]; then
        err "buildme not found"
        exit 1
    fi
    
    [ ! -f "buildme.backup" ] && cp "buildme" "buildme.backup"
    
    # 1) Ensure terminal stdin for all reads (fixes EAGAIN)
    if ! head -n 2 buildme | grep -q 'exec </dev/tty'; then
        local bk=$(backup_copy "buildme"); info "Backup: $bk"
        awk 'NR==1{print; print "exec </dev/tty"; next}1' buildme > buildme.tmp && mv buildme.tmp buildme
        chmod +x buildme
        ok "Inserted 'exec </dev/tty' after shebang"
    else
        ok "buildme already has 'exec </dev/tty'"
    fi

    # 2) Simple sed-based patch
    sed ${SED_INPLACE_FLAG[@]} 's/make pkg > mpkg\.log/make pkg | tee mpkg.log/g' buildme || true
    
    # 3) Add environment setup before build commands
    local temp_file="buildme.tmp"
    {
        while IFS= read -r line; do
            if echo "$line" | grep -q "^build.*-t.*XCODE"; then
                echo "# Environment setup for v14.0"
                echo "export MACOSX_DEPLOYMENT_TARGET=\"$DEPLOYMENT_TARGET\""
                echo "export PATH=\"/usr/bin:/bin:/usr/sbin:/sbin:\$PATH\""
                echo ""
            fi
            echo "$line"
        done < buildme
    } > "$temp_file"
    
    mv "$temp_file" buildme
    chmod +x buildme
    
    ok "buildme patched"
}

# Conditional: remove fixed Python echo in xbuildme if Anaconda/conda present
anaconda_or_multi_python_present() {
    if command -v conda >/dev/null 2>&1; then return 0; fi
    if [ -d "/opt/anaconda3" ] || [ -d "$HOME/anaconda3" ] || [ -d "$HOME/opt/anaconda3" ]; then return 0; fi
    local c; c=$(which -a python3 2>/dev/null | sort -u | wc -l | tr -d ' ')
    [ "$c" -gt 1 ] && return 0 || return 1
}

patch_xbuildme_python_echo_if_needed() {
    say "=== Checking xbuildme Python echo duplication ==="
    if [ ! -f "xbuildme" ]; then
        info "xbuildme not found at repo root. Skipping."
        return 0
    fi
    if anaconda_or_multi_python_present; then
        local bk=$(backup_copy "xbuildme"); info "Backup: $bk"
        # Comment lines showing fixed version (Current Python version / Python 3.13.x)
        sed ${SED_INPLACE_FLAG[@]} '/Current Python version:/s/^/#/' xbuildme || true
        sed ${SED_INPLACE_FLAG[@]} '/Python 3\.13\./s/^/#/' xbuildme || true
        ok "xbuildme: commented fixed Python version echo (avoid duplicate/confusing output)"
    else
        ok "Single Python detected. Keeping xbuildme as-is."
    fi
}

# Generate report
generate_report() {
    say "=== SETUP COMPLETE! ==="
    echo
    ok "macOS: $MACOS_VERSION"
    ok "Python: $PYTHON_CMD ($PYTHON_VERSION)"
    ok "Deployment Target: $DEPLOYMENT_TARGET"
    ok "Repository: $REPO_DIR"
    
    # Show dependency status
    echo
    say "=== Dependency Status ==="
    
    # Check Xcode status
    if xcode-select -p >/dev/null 2>&1 && command -v make >/dev/null 2>&1; then
        ok "Xcode Command Line Tools: ✅ Instalado e funcionando"
    else
        warn "Xcode Command Line Tools: ❌ Problema detectado"
        info "Isso causará erro 'usr/bin/make -C'"
    fi
    
    # Check Anaconda status
    if check_anaconda >/dev/null 2>&1; then
        ok "Anaconda: ✅ Instalado e ativo"
    else
        warn "Anaconda: ❌ Não encontrado"
        info "Para melhor compatibilidade, instale Anaconda 3.9.x"
    fi
    
    # Check distutils status - CORRIGIDO
    if [ -n "$PYTHON_CMD" ] && check_distutils "$PYTHON_CMD" >/dev/null 2>&1; then
        ok "distutils.util: ✅ Funcionando ($PYTHON_CMD)"
    else
        warn "distutils.util: ❌ Não disponível ($PYTHON_CMD)"
        info "Isso pode causar erro 'No module named distutils.util'"
    fi
    
    # Show macOS Tahoe specific info
    local major=$(echo "$MACOS_VERSION" | cut -d. -f1)
    if [ "$major" -ge 26 ]; then
        warn "macOS Tahoe Beta detected - using stable Homebrew tools"
        local git_version=$(git --version 2>/dev/null | cut -d' ' -f3)
        info "Git version: $git_version (from $(which git))"
    fi
    
    ok "All fixes applied successfully!"
    echo
    
    # Show specific fixes applied
    local acpi_c="OpenCorePkg/Library/OcAcpiLib/AcpiParser.c"
    if [ -f "$acpi_c" ] && grep -q "Fixed by v14.0" "$acpi_c"; then
        ok "AcpiParser.c ScopeNameStart issue fixed"
    fi
    
    # Show repository validation
    if validate_repository_structure "$REPO_DIR"; then
        ok "Repository structure validated (BaseTools, buildme, OpenCorePkg present)"
    fi
    
    # Show binaries status
    local safe_binaries="$HOME/src-binaries"
    local download_dir="$REPO_DIR/toolchain/tools/download"
    
    if [ -d "$safe_binaries" ]; then
        local saved_count
        saved_count=$(find "$safe_binaries" -name "*.tar.gz" -o -name "*.tar.xz" 2>/dev/null | wc -l | tr -d ' ')
        if [ "$saved_count" -gt 0 ]; then
            ok "Saved binaries: $saved_count files in $safe_binaries"
        fi
    fi
    
    if [ -d "$download_dir" ]; then
        local current_count
        current_count=$(find "$download_dir" -name "*.tar.gz" -o -name "*.tar.xz" 2>/dev/null | wc -l | tr -d ' ')
        if [ "$current_count" -gt 0 ]; then
            ok "Current binaries: $current_count files in download folder"
        fi
    fi
    
    echo
    info "To build Clover:"
    info "  cd $REPO_DIR"
    info "  ./buildme"
    echo
    info "Recommended options:"
    info "  → Option 2: GCC151 (stable)"
    info "  → Option 9: Xcode (if available)"
    echo
    
    # Show dependency warnings if needed
    if ! check_anaconda >/dev/null 2>&1 || ! check_distutils "$PYTHON_CMD" >/dev/null 2>&1; then
        say "=== ⚠️  IMPORTANTE: Problemas de Dependências Detectados ==="
        echo
        if ! check_anaconda >/dev/null 2>&1; then
            warn "Anaconda não encontrado!"
            info "Para evitar erros de compilação, instale Anaconda 3.9.x:"
            info "  • Intel: https://repo.anaconda.com/archive/Anaconda3-2021.11-MacOSX-x86_64.pkg"
            info "  • ARM64: https://repo.anaconda.com/archive/Anaconda3-2022.05-MacOSX-arm64.pkg"
            echo
        fi
        if ! check_distutils "$PYTHON_CMD" >/dev/null 2>&1; then
            warn "distutils.util não disponível!"
            info "Isso causará o erro: 'No module named distutils.util'"
            info "Solução rápida: $PYTHON_CMD -m pip install setuptools"
            echo
        fi
        info "Execute este script novamente após instalar as dependências!"
        echo
    fi
    
    # Tahoe-specific recommendations
    if [ "$major" -ge 26 ]; then
        say "=== macOS Tahoe Beta Notes ==="
        info "This script has applied the following Tahoe fixes:"
        info "  • Prioritized stable Homebrew tools (git, bash, coreutils)"
        info "  • Enhanced repository validation"
        info "  • Improved error handling"
        echo
        info "If you encounter issues, try:"
        info "  1. brew upgrade git bash coreutils"
        info "  2. Delete repository and re-run this script"
        info "  3. Use saved binaries (option 3) to avoid re-downloads"
        echo
    fi
}

# Auto-save binaries after successful build
auto_save_binaries_after_build() {
    local safe_binaries="$HOME/src-binaries"
    local download_dir="$REPO_DIR/toolchain/tools/download"
    
    # Check if build was successful (CloverX64.efi exists)
    if [ -f "Build/Clover/RELEASE_GCC151/X64/CloverX64.efi" ] || [ -f "Build/Clover/RELEASE_XCODE"*"/X64/CloverX64.efi" ]; then
        if [ -d "$download_dir" ]; then
            local count
            count=$(find "$download_dir" -name "*.tar.gz" -o -name "*.tar.xz" 2>/dev/null | wc -l | tr -d ' ')
            if [ "$count" -gt 0 ]; then
                mkdir -p "$safe_binaries"
                cp "$download_dir"/*.tar.* "$safe_binaries/" 2>/dev/null
                ok "Build successful! Binaries auto-saved to src-binaries"
            fi
        fi
    fi
}

# Main execution
main() {
    say "=== $SCRIPT_NAME v$SCRIPT_VERSION ==="
    say "macOS Tahoe Beta Compatible - Full Git Repository Fix"
    echo
    
    # Setup environment first (Anaconda PATH)
    setup_environment
    
    # Setup Homebrew environment (critical for Tahoe)
    setup_homebrew_environment
    
    detect_macos
    install_homebrew
    
    # Verificar Xcode LOGO NO INÍCIO (antes de tudo)
    verify_and_fix_xcode
    
    configure_python
    create_python_symlinks
    install_dev_tools
    manage_repository
    manage_gnu_binaries
    setup_build_environment
    apply_source_fixes
    configure_toolchain
    compile_basetools
    configure_conf
    patch_buildme
    patch_xbuildme_python_echo_if_needed
    auto_save_binaries
    generate_report
    
    read -p "Run buildme now? (y/N): " answer
    case "$answer" in
        [Yy]*)
            say "Starting buildme..."
            ./buildme
            auto_save_binaries_after_build
            ;;
        *)
            say "Setup completed! Run './buildme' when ready."
            say "Tip: Run this script again to auto-restore saved binaries before buildme"
            ;;
    esac
}

# Verify macOS
if [ "$(uname)" != "Darwin" ]; then
    err "This script requires macOS"
    exit 1
fi

# Run main
main "$@"
# Updated: Tue Oct 14 07:08:34 -03 2025
