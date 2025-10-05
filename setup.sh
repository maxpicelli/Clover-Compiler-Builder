#!/bin/bash
set -euo pipefail

# ============================================================================
# Clover Compiler Builder - Setup Automático
# Este script clona o repositório e cria o app automaticamente
# ============================================================================

# Cores para output
say() { echo -e "\033[36m$*\033[0m"; }
ok() { echo -e "\033[32m✔ $*\033[0m"; }
warn() { echo -e "\033[33m⚠ $*\033[0m"; }
err() { echo -e "\033[31m✘ $*\033[0m"; }
info() { echo -e "\033[94mℹ $*\033[0m"; }

# Banner
echo ""
say "════════════════════════════════════════════════════════"
say "   🍀 Clover Compiler Builder - Setup Automático"
say "════════════════════════════════════════════════════════"
echo ""

# Verificar se git está instalado
if ! command -v git >/dev/null 2>&1; then
    err "Git não está instalado!"
    info "Instale com: brew install git"
    exit 1
fi

# Definir diretório de destino
INSTALL_DIR="$HOME/CloverCompilerBuilder"
REPO_URL="https://github.com/maxpicelli/Clover-Compiler-Builder.git"

# Perguntar onde instalar
echo "Onde deseja instalar o Clover Compiler Builder?"
echo "Padrão: $INSTALL_DIR"
echo ""
read -p "Pressione Enter para usar o padrão ou digite outro caminho: " custom_dir

if [ -n "$custom_dir" ]; then
    INSTALL_DIR="$custom_dir"
fi

# Expandir ~ para home
INSTALL_DIR="${INSTALL_DIR/#\~/$HOME}"

say "Instalando em: $INSTALL_DIR"
echo ""

# Verificar se o diretório já existe
if [ -d "$INSTALL_DIR" ]; then
    warn "Diretório já existe: $INSTALL_DIR"
    read -p "Deseja remover e reinstalar? (s/N): " answer
    case "$answer" in
        [Ss]*)
            rm -rf "$INSTALL_DIR"
            ok "Diretório removido"
            ;;
        *)
            err "Instalação cancelada"
            exit 1
            ;;
    esac
fi

# Clonar repositório
say "Clonando repositório do GitHub..."
if git clone "$REPO_URL" "$INSTALL_DIR"; then
    ok "Repositório clonado com sucesso!"
else
    err "Falha ao clonar repositório"
    exit 1
fi

echo ""

# Entrar no diretório
cd "$INSTALL_DIR"

# Verificar se os arquivos necessários existem
if [ ! -f "Criar Clover Builder - make_app" ]; then
    err "Arquivo 'Criar Clover Builder - make_app' não encontrado!"
    exit 1
fi

if [ ! -f "CloverCompilerBuilder.sh" ]; then
    err "Arquivo 'CloverCompilerBuilder.sh' não encontrado!"
    exit 1
fi

# Tornar scripts executáveis
say "Configurando permissões..."
chmod +x "Criar Clover Builder - make_app"
chmod +x "CloverCompilerBuilder.sh"
ok "Permissões configuradas"

echo ""

# Criar o app
say "Criando aplicativo CloverBuilderv14.app..."
if ./"Criar Clover Builder - make_app"; then
    ok "Aplicativo criado com sucesso!"
else
    err "Falha ao criar aplicativo"
    exit 1
fi

echo ""

# Verificar se o app foi criado
if [ -d "CloverBuilderv14.app" ]; then
    ok "CloverBuilderv14.app criado em:"
    info "  $INSTALL_DIR/CloverBuilderv14.app"
    
    # Remover quarentena
    say "Removendo atributos de quarentena..."
    xattr -cr "CloverBuilderv14.app" 2>/dev/null || true
    ok "Atributos removidos"
    
    echo ""
    say "════════════════════════════════════════════════════════"
    ok "INSTALAÇÃO CONCLUÍDA COM SUCESSO! 🎉"
    say "════════════════════════════════════════════════════════"
    echo ""
    
    info "Para usar o Clover Builder:"
    info "  1. Dê duplo clique em CloverBuilderv14.app"
    info "  2. Ou execute no Terminal: open '$INSTALL_DIR/CloverBuilderv14.app'"
    echo ""
    
    info "Arquivos instalados em:"
    info "  $INSTALL_DIR"
    echo ""
    
    # Perguntar se deseja abrir a pasta
    read -p "Deseja abrir a pasta agora? (S/n): " open_answer
    case "$open_answer" in
        [Nn]*)
            say "Ok! Você pode acessar em: $INSTALL_DIR"
            ;;
        *)
            say "Abrindo pasta no Finder..."
            open "$INSTALL_DIR"
            ok "Pasta aberta!"
            ;;
    esac
    
    echo ""
    
    # Perguntar se deseja executar o app
    read -p "Deseja executar o Clover Builder agora? (s/N): " run_answer
    case "$run_answer" in
        [Ss]*)
            say "Iniciando Clover Builder..."
            open "CloverBuilderv14.app"
            ok "Aplicativo iniciado!"
            ;;
        *)
            say "Pronto! Execute quando quiser."
            ;;
    esac
    
else
    err "Aplicativo não foi criado"
    exit 1
fi

echo ""
say "════════════════════════════════════════════════════════"
say "   Obrigado por usar o Clover Compiler Builder! 🍀"
say "════════════════════════════════════════════════════════"
echo ""

