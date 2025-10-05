# 🍀 Clover Builder v14

Um app bundle para macOS que facilita a compilação do Clover Bootloader através de uma interface simples e intuitiva.

## 🚀 Instalação Rápida (Recomendado)

Execute este comando no Terminal para instalar automaticamente:

```bash
curl -fsSL https://raw.githubusercontent.com/maxpicelli/Clover-Compiler-Builder/main/setup.sh | bash
```

**O que este comando faz:**
- ✅ Clona o repositório do GitHub
- ✅ Cria o aplicativo CloverBuilderv14.app automaticamente
- ✅ Configura todas as permissões necessárias
- ✅ Abre a pasta onde foi instalado
- ✅ Opcionalmente inicia o app

**OU** clone manualmente:

```bash
git clone https://github.com/maxpicelli/Clover-Compiler-Builder.git
cd Clover-Compiler-Builder
chmod +x setup.sh
./setup.sh
```

---

## 📋 Descrição

O Clover Builder v14 é um aplicativo macOS que automatiza o processo de compilação do Clover Bootloader. Ele abre o Terminal automaticamente e executa o script de build, tornando o processo mais acessível e organizado.

## 🎯 Características

- ✅ Interface nativa do macOS (.app bundle)
- ✅ Ícone personalizado
- ✅ Abertura automática do Terminal
- ✅ Script de build integrado
- ✅ Fácil de usar - basta dar duplo clique

## 📦 Estrutura de Arquivos

```
pasta-do-projeto/
├── make_app.sh              # Script para criar o app bundle
├── CloverCompilerBuilder.sh # Script principal de compilação
├── icone.icns              # Ícone do aplicativo (ou icone.icon)
└── CloverBuilderv14.app    # App bundle gerado (após executar make_app.sh)
```

## 🚀 Como Usar

### Primeira vez (Criar o App)

1. **Certifique-se de ter os arquivos necessários na mesma pasta:**
   - `make_app.sh`
   - `CloverCompilerBuilder.sh`
   - `icone.icns` (ou `icone.icon`)

2. **Abra o Terminal e navegue até a pasta do projeto:**
   ```bash
   cd /caminho/para/sua/pasta
   ```

3. **Torne o script executável:**
   ```bash
   chmod +x make_app.sh
   ```

4. **Execute o script para criar o app:**
   ```bash
   ./make_app.sh
   ```

5. **Pronto!** O app `CloverBuilderv14.app` será criado na mesma pasta.

### Uso Normal

Após criar o app, simplesmente:

1. **Dê duplo clique** no `CloverBuilderv14.app`
2. O Terminal será aberto automaticamente
3. O script de build do Clover será executado

## 🔧 Requisitos

- macOS (qualquer versão moderna)
- Terminal
- Xcode Command Line Tools (para compilação do Clover)
- Permissões de execução nos scripts

## 📝 O que o make_app.sh faz?

O script `make_app.sh` automatiza a criação do app bundle:

1. Detecta automaticamente a pasta onde está localizado
2. Cria a estrutura de pastas do app bundle (.app/Contents/MacOS e Resources)
3. Gera o arquivo `Info.plist` com as configurações do app
4. Cria um launcher que abre o Terminal e executa o script
5. Copia o script de build (`CloverCompilerBuilder.sh`) para dentro do app
6. Copia e configura o ícone personalizado
7. Define as permissões corretas de execução
8. Remove atributos estendidos que poderiam causar problemas
9. Atualiza o cache do Finder para exibir o ícone

## 🎨 Personalizando o Ícone

O app aceita ícones nos formatos:
- `.icns` (formato nativo do macOS) - **recomendado**
- `.icon` (será convertido automaticamente para .icns)

Para criar um ícone .icns a partir de uma imagem:
```bash
sips -s format icns sua-imagem.png --out icone.icns
```

## 🔒 Segurança

O script remove automaticamente atributos de quarentena (`xattr -cr`) para evitar avisos de segurança do macOS. O app não é assinado digitalmente, mas como é criado localmente, o macOS permite sua execução.

Se aparecer um aviso de segurança na primeira execução:
1. Clique com o botão direito no app
2. Selecione "Abrir"
3. Confirme "Abrir" novamente

## 🐛 Solução de Problemas

### O ícone não aparece
```bash
killall Finder
```

### Símbolo de proibido no app
Execute:
```bash
xattr -cr CloverBuilderv14.app
```

### Script não executa
Verifique as permissões:
```bash
chmod 755 CloverBuilderv14.app/Contents/MacOS/run
chmod 755 CloverBuilderv14.app/Contents/Resources/builder.sh
```

### Erro "CloverCompilerBuilder.sh não encontrado"
Certifique-se de que o arquivo `CloverCompilerBuilder.sh` está na mesma pasta que o `make_app.sh` antes de criar o app.

## 📂 Portabilidade

O script `make_app.sh` é totalmente portátil! Você pode:
- Copiar a pasta inteira para qualquer lugar
- Executar o script em qualquer diretório
- Não precisa editar caminhos hardcoded

O script detecta automaticamente sua localização usando:
```bash
BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
```

## 🔄 Atualizando o App

Para atualizar o app após modificar o script de build:

1. Delete o app antigo (ou apenas sobrescreva)
2. Execute novamente o `make_app.sh`
3. O novo app será criado com as alterações

## 📄 Licença

Este é um script utilitário para criar um app bundle. Verifique a licença do Clover Bootloader separadamente.

## 🤝 Contribuindo

Sinta-se à vontade para modificar e adaptar o script às suas necessidades!

## 📞 Suporte

Se encontrar problemas:
1. Verifique se todos os arquivos necessários estão presentes
2. Confirme as permissões de execução
3. Verifique a seção "Solução de Problemas" acima
4. Execute o script manualmente no Terminal para ver mensagens de erro

---

**Versão:** 14  
**Última atualização:** Outubro 2025  
**Compatibilidade:** macOS 10.13+

🍀 Happy Building!