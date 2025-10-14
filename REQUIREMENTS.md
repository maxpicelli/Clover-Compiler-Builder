# 🔧 Clover Compiler Builder - Requisitos Detalhados

## 📋 Lista Completa de Requisitos

### 🖥️ **Sistema Operacional**

#### ✅ **OBRIGATÓRIO**
- **macOS**: Versão 10.13 (High Sierra) ou superior
- **Arquitetura**: 
  - Intel (x86_64)
  - Apple Silicon (ARM64/M1/M2/M3/M4)
- **Espaço em disco**: Mínimo 5GB livres
- **RAM**: Mínimo 4GB (8GB recomendado)

#### 🔍 **Como Verificar sua Arquitetura**
```bash
uname -m
```
- **Resultado `arm64`**: Mac Apple Silicon
- **Resultado `x86_64`**: Mac Intel

#### 📊 **Versões macOS Testadas**
| Versão | Status | Notas |
|--------|--------|-------|
| macOS 14 (Sonoma) | ✅ Totalmente compatível | Versão estável |
| macOS 15 (Sequoia) | ✅ Totalmente compatível | Versão estável |
| macOS 26 (Tahoe Beta) | ✅ Totalmente compatível | **Suporte especial** |

---

### 🐍 **Python - REQUISITO PRINCIPAL**

#### ⭐ **RECOMENDAÇÃO OFICIAL: Python Anaconda 3.9.x**

**Por que Anaconda 3.9.x é essencial?**
- ✅ **Compatibilidade máxima** com scripts de compilação do Clover
- ✅ **Ambiente Python completo** e estável
- ✅ **Evita conflitos** com outras versões do Python
- ✅ **Inclui distutils.util** nativamente (problema crítico resolvido)
- ✅ **Testado e aprovado** para builds do Clover Bootloader
- ✅ **Gerenciamento de dependências** automático

#### 📥 **Downloads Oficiais por Arquitetura**

##### 🚀 **VERSÕES MAIS RECENTES (RECOMENDADAS)**

| Arquitetura | Versão Anaconda | Python | Tamanho | Download |
|-------------|-----------------|--------|---------|----------|
| **Apple Silicon (ARM64)** ⭐ | v3-2025.06 | 3.13 | ~1.2GB | [Anaconda3-2025.06-0-MacOSX-arm64.pkg](https://repo.anaconda.com/archive/Anaconda3-2025.06-0-MacOSX-arm64.pkg) |
| **Intel (x86_64)** ⭐ | v3-2025.06 | 3.13 | ~1.2GB | [Anaconda3-2025.06-0-MacOSX-x86_64.pkg](https://repo.anaconda.com/archive/Anaconda3-2025.06-0-MacOSX-x86_64.pkg) |

##### 📚 **VERSÕES ESTÁVEIS (ALTERNATIVAS)**

| Arquitetura | Versão Anaconda | Python | Tamanho | Download |
|-------------|-----------------|--------|---------|----------|
| **Apple Silicon (ARM64)** | v3-2022.05 | 3.9.13 | ~1.1GB | [Anaconda3-2022.05-MacOSX-arm64.pkg](https://repo.anaconda.com/archive/Anaconda3-2022.05-MacOSX-arm64.pkg) |
| **Intel (x86_64)** | v3-2021.11 | 3.9.6 | ~1.1GB | [Anaconda3-2021.11-MacOSX-x86_64.pkg](https://repo.anaconda.com/archive/Anaconda3-2021.11-MacOSX-x86_64.pkg) |

#### 🔧 **Instalação do Anaconda**

1. **Download**: Use os links acima para sua arquitetura
2. **Execução**: Dê duplo clique no arquivo `.pkg` baixado
3. **Instalação**: Siga o assistente de instalação
4. **Configuração**: O script detecta automaticamente

#### 🔍 **Verificação da Instalação**
```bash
# Verificar se Anaconda foi instalado
conda --version

# Verificar Python
python3 --version

# Verificar distutils (crítico!)
python3 -c "import distutils.util; print('✅ distutils.util OK')"
```

#### ⚠️ **Problemas Comuns com Python**

##### ❌ **Erro: "No module named distutils.util"**
**Causa**: Python 3.12+ não inclui distutils nativamente  
**Solução**: Instalar Anaconda 3.9.x ou setuptools

```bash
# Solução rápida
python3 -m pip install setuptools

# Solução definitiva
# Instalar Anaconda 3.9.x (recomendado)
```

##### ❌ **Múltiplas versões do Python**
**Causa**: Conflito entre Python do sistema e Anaconda  
**Solução**: O script prioriza Anaconda automaticamente

---

### 🛠️ **Ferramentas de Desenvolvimento**

#### ✅ **OBRIGATÓRIAS**

##### 1. **Xcode Command Line Tools**
```bash
# Instalação
xcode-select --install
```
**O que inclui:**
- `make` - Compilador de build
- `gcc` - Compilador C
- `git` básico - Controle de versão
- `clang` - Compilador Apple

**Verificação:**
```bash
# Verificar instalação
xcode-select -p

# Verificar make
make --version

# Verificar gcc
gcc --version
```

##### 2. **Git (Moderno)**
```bash
# Instalado automaticamente via Homebrew
brew install git
```
**Versão mínima**: 2.20+  
**Recomendado**: Última versão estável

#### 🔧 **INSTALADAS AUTOMATICAMENTE**

##### 3. **Homebrew**
```bash
# Instalado automaticamente pelo script
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
**Localizações típicas:**
- Apple Silicon: `/opt/homebrew`
- Intel: `/usr/local`

##### 4. **Ferramentas de Build**
```bash
# Instaladas automaticamente
brew install cmake ninja nasm coreutils
```

**Descrição das ferramentas:**
- **cmake**: Sistema de build cross-platform
- **ninja**: Build system pequeno e rápido
- **nasm**: Assembler para x86/x64
- **coreutils**: Utilitários GNU (compatibilidade)

---

### 🌐 **Conectividade**

#### ✅ **OBRIGATÓRIO**
- **Internet**: Conexão estável para downloads
- **GitHub**: Acesso a repositórios
- **Portas**: HTTPS (443) para downloads

**Downloads necessários:**
- Repositório CloverBootloader (~500MB)
- Binários de ferramentas (~200MB)
- Dependências Python (~100MB)

---

### 💾 **Armazenamento**

#### 📊 **Espaço Necessário**

| Componente | Tamanho | Descrição |
|------------|---------|-----------|
| **Anaconda** | ~1.2GB | Instalação completa |
| **Repositório Clover** | ~500MB | Código fonte |
| **Binários salvos** | ~200MB | Ferramentas compiladas |
| **Build temporário** | ~2GB | Durante compilação |
| **Cache Homebrew** | ~500MB | Dependências |
| **TOTAL** | **~4.5GB** | Espaço total necessário |

#### 📁 **Estrutura de Diretórios**
```
~/src/                          # Diretório principal
├── CloverBootloader/          # Repositório Clover
├── toolchain/tools/download/  # Binários baixados
└── ...

~/src-binaries/                # Backup de binários
├── *.tar.gz                   # Binários salvos
└── ...

~/.homebrew/                   # Cache Homebrew
└── ...
```

---

### 🔐 **Permissões**

#### ✅ **Permissões Necessárias**
- **Execução de scripts**: `chmod +x`
- **Escrita em diretórios**: `~/src`, `~/src-binaries`
- **Instalação de software**: Homebrew, Xcode Tools
- **Acesso ao Terminal**: Para execução de comandos

#### 🛡️ **Segurança**
- **Quarentena**: Removida automaticamente (`xattr -cr`)
- **Assinatura**: App não assinado (criado localmente)
- **Permissões**: Configuradas automaticamente

---

## 🚀 **Instalação Passo a Passo**

### 1️⃣ **Preparação do Sistema**
```bash
# Verificar arquitetura
uname -m

# Verificar versão do macOS
sw_vers -productVersion

# Verificar espaço disponível
df -h
```

### 2️⃣ **Instalação do Anaconda**
1. Baixar versão correta para sua arquitetura
2. Executar instalador `.pkg`
3. Seguir assistente de instalação
4. Verificar instalação: `conda --version`

### 3️⃣ **Instalação do Clover Builder**
```bash
# Opção 1: Instalação automática
curl -fsSL https://raw.githubusercontent.com/maxpicelli/Clover-Compiler-Builder/main/setup.sh | bash

# Opção 2: Instalação manual
git clone https://github.com/maxpicelli/Clover-Compiler-Builder.git
cd Clover-Compiler-Builder
chmod +x setup.sh
./setup.sh
```

### 4️⃣ **Verificação Final**
```bash
# Verificar Python
python3 -c "import distutils.util; print('✅ Python OK')"

# Verificar Xcode Tools
xcode-select -p

# Verificar Homebrew
brew --version
```

---

## ✅ **Checklist de Verificação**

### 🔍 **Antes de Executar o Script**

- [ ] **macOS**: Versão 10.13+ instalada
- [ ] **Arquitetura**: Identificada (Intel ou Apple Silicon)
- [ ] **Anaconda**: Versão 3.9.x instalada
- [ ] **Xcode Tools**: Instalados (`xcode-select -p`)
- [ ] **Internet**: Conexão estável disponível
- [ ] **Espaço**: Mínimo 5GB livres
- [ ] **Permissões**: Terminal com acesso completo

### 🔍 **Após Execução do Script**

- [ ] **Python**: `distutils.util` funcionando
- [ ] **Homebrew**: Instalado e funcionando
- [ ] **Repositório**: CloverBootloader clonado
- [ ] **Binários**: Detectados ou baixados
- [ ] **BaseTools**: Compilados com sucesso
- [ ] **App**: CloverBuilderv14.app criado

---

## 🆘 **Solução de Problemas**

### ❌ **Problemas Comuns**

#### **1. Anaconda não detectado**
```bash
# Adicionar ao PATH
echo 'export PATH="$HOME/anaconda3/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

#### **2. Xcode Tools corrompidos**
```bash
# Reinstalar
sudo rm -rf /Library/Developer/CommandLineTools
xcode-select --install
```

#### **3. Espaço insuficiente**
```bash
# Limpar cache
brew cleanup
rm -rf ~/src-binaries/*.tar.gz
```

#### **4. Permissões negadas**
```bash
# Corrigir permissões
chmod +x CloverCompilerBuilder.sh
chmod +x "Criar Clover Builder - make_app"
```

### ✅ **Verificações de Diagnóstico**
```bash
# Script de diagnóstico completo
./CloverCompilerBuilder.sh --diagnostic
```

---

## 📞 **Suporte**

### 🆘 **Em caso de problemas:**
1. Verificar este arquivo de requisitos
2. Executar script com `--verbose` para logs detalhados
3. Verificar logs de backup criados automaticamente
4. Consultar CHANGELOG.md para mudanças recentes

### 📝 **Informações para Suporte**
Ao reportar problemas, inclua:
- Versão do macOS: `sw_vers -productVersion`
- Arquitetura: `uname -m`
- Versão do Python: `python3 --version`
- Versão do Anaconda: `conda --version`
- Logs de erro completos

---

**Versão**: 14.3-fixed  
**Última atualização**: Outubro 2025  
**Status**: Estável e em produção  

🍀 **Happy Building!**
