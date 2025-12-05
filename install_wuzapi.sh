#!/data/data/com.termux/files/usr/bin/bash

# Cores para output
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Funções para exibição
print_header() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                INSTALADOR WUZAPI TERMUX                  ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() {
    echo -e "\n${GREEN}▶ ${WHITE}$1${NC}"
    echo -e "${YELLOW}────────────────────────────────────────────${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Função para gerar chaves aleatórias
generate_key() {
    length=$1
    tr -dc 'A-Za-z0-9!@#$%^&*()_+-=' < /dev/urandom | head -c $length 2>/dev/null
    if [ $? -ne 0 ]; then
        # Fallback se /dev/urandom falhar
        date +%s | sha256sum | base64 | head -c $length
    fi
}

# Função para verificar e instalar dependências
check_dependencies() {
    print_step "VERIFICANDO DEPENDÊNCIAS"
    
    # Verificar se o Termux está atualizado
    if ! pkg update -y > /dev/null 2>&1; then
        print_error "Falha ao atualizar repositórios"
        return 1
    fi
    
    print_success "Repositórios atualizados"
    return 0
}

# Função para instalar pacotes
install_packages() {
    print_step "INSTALANDO PACOTES NECESSÁRIOS"
    
    # Lista de pacotes
    packages=("golang" "git" "nano" "openssl-tool")
    
    for pkg in "${packages[@]}"; do
        print_info "Instalando $pkg..."
        if pkg install -y "$pkg" > /dev/null 2>&1; then
            print_success "$pkg instalado com sucesso"
        else
            print_error "Falha ao instalar $pkg"
            return 1
        fi
    done
    
    return 0
}

# Função para configurar ambiente
setup_environment() {
    print_step "CONFIGURANDO AMBIENTE"
    
    # Configurar armazenamento
    print_info "Configurando armazenamento..."
    termux-setup-storage <<< "y"
    
    # Configurar variável de ambiente Go
    export GO111MODULE=on
    echo 'export GO111MODULE=on' >> ~/.bashrc
    echo 'export PATH=$PATH:~/go/bin' >> ~/.bashrc
    
    print_success "Ambiente configurado"
    return 0
}

# Função para clonar e configurar o projeto
setup_project() {
    print_step "CONFIGURANDO PROJETO WUZAPI"
    
    # Clonar repositório
    print_info "Clonando repositório..."
    if [ -d "wuzapi" ]; then
        print_info "Diretório wuzapi já existe. Atualizando..."
        cd wuzapi
        git pull origin main
    else
        git clone https://github.com/asternic/wuzapi.git
        cd wuzapi
    fi
    
    # Instalar dependências Go
    print_info "Instalando dependências Go..."
    go get -u go.mau.fi/whatsmeow@latest
    go mod tidy
    
    # Compilar
    print_info "Compilando projeto..."
    go build .
    
    if [ $? -eq 0 ]; then
        print_success "Projeto compilado com sucesso"
    else
        print_error "Falha ao compilar projeto"
        return 1
    fi
    
    return 0
}

# Função para configurar arquivo .env
setup_env_file() {
    print_step "CONFIGURANDO ARQUIVO .ENV"
    
    # Gerar chaves aleatórias
    print_info "Gerando chaves de segurança..."
    ENCRYPTION_KEY=$(generate_key 32)
    HMAC_KEY=$(generate_key 32)
    
    # Criar diretório de mídia
    print_info "Criando diretório de mídia..."
    mkdir -p /storage/emulated/0/WuzAPI/media
    
    # Criar arquivo .env
    cat > .env << EOF
# Configuração WuzAPI - Gerado automaticamente
WUZAPI_ADMIN_TOKEN=graffbot
WUZAPI_GLOBAL_ENCRYPTION_KEY=${ENCRYPTION_KEY}
WUZAPI_GLOBAL_HMAC_KEY=${HMAC_KEY}
TZ=America/Sao_Paulo
WEBHOOK_FORMAT=json
SESSION_DEVICE_NAME=BotZAP_Termux
WUZAPI_PORT=8080
MEDIA_DIR=/storage/emulated/0/WuzAPI/media
SQLITE_BUSY_TIMEOUT=20000
SQLITE_JOURNAL_MODE=WAL
SQLITE_SYNCHRONOUS=NORMAL
SQLITE_CACHE_SIZE=20000
LOG_LEVEL=info
EOF
    
    print_success "Arquivo .env configurado"
    print_info "Chave de Encriptação: ${ENCRYPTION_KEY}"
    print_info "Chave HMAC: ${HMAC_KEY}"
    return 0
}

# Função para criar script de monitoramento e reinício
create_monitor_script() {
    print_step "CRIANDO SISTEMA DE MONITORAMENTO"
    
    # Criar script de monitoramento
    cat > monitor_wuzapi.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

# Cores
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

LOG_FILE="wuzapi_monitor.log"
PROCESS_NAME="wuzapi"
RESTART_DELAY=5
MAX_RESTARTS=10
RESTART_COUNT=0

# Função de log
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    echo -e "$2$1${NC}"
}

# Função para matar processos antigos
kill_existing() {
    pkill -f "$PROCESS_NAME" 2>/dev/null
    sleep 2
}

# Loop principal de monitoramento
while [ $RESTART_COUNT -lt $MAX_RESTARTS ]; do
    log_message "Iniciando WuzAPI..." "$GREEN"
    
    # Executar em background
    ./wuzapi -logtype=console -color=true &
    PID=$!
    
    log_message "PID do processo: $PID" "$YELLOW"
    
    # Monitorar processo
    while ps -p $PID > /dev/null; do
        sleep 10
    done
    
    log_message "WuzAPI parou inesperadamente" "$RED"
    
    # Matar qualquer processo residual
    kill_existing
    
    # Incrementar contador
    RESTART_COUNT=$((RESTART_COUNT + 1))
    
    if [ $RESTART_COUNT -lt $MAX_RESTARTS ]; then
        log_message "Reiniciando em $RESTART_DELAY segundos... (Tentativa $RESTART_COUNT/$MAX_RESTARTS)" "$YELLOW"
        sleep $RESTART_DELAY
    else
        log_message "Número máximo de reinícios atingido. Encerrando." "$RED"
        exit 1
    fi
done
EOF
    
    # Tornar executável
    chmod +x monitor_wuzapi.sh
    
    # Criar serviço no Termux boot (se desejado)
    cat > ~/.termux/boot/start-wuzapi.sh 2>/dev/null << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
cd ~/wuzapi
./monitor_wuzapi.sh
EOF
    
    chmod +x ~/.termux/boot/start-wuzapi.sh 2>/dev/null || true
    
    print_success "Script de monitoramento criado"
    return 0
}

# Função principal
main() {
    clear
    print_header
    
    # Executar todos os passos
    steps=(
        "check_dependencies"
        "install_packages" 
        "setup_environment"
        "setup_project"
        "setup_env_file"
        "create_monitor_script"
    )
    
    for step in "${steps[@]}"; do
        if ! $step; then
            print_error "Instalação interrompida no passo: $step"
            print_info "Execute manualmente o comando que falhou"
            exit 1
        fi
    done
    
    # Resumo final
    echo -e "\n${GREEN}══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}                 INSTALAÇÃO CONCLUÍDA!                    ${NC}"
    echo -e "${GREEN}══════════════════════════════════════════════════════════${NC}"
    echo -e "\n${WHITE}Informações importantes:${NC}"
    echo -e "${YELLOW}• Diretório:${NC} ~/wuzapi"
    echo -e "${YELLOW}• Porta:${NC} 8080"
    echo -e "${YELLOW}• Token Admin:${NC} graffbot"
    echo -e "${YELLOW}• Timezone:${NC} America/Sao_Paulo"
    echo -e "\n${WHITE}Comandos disponíveis:${NC}"
    echo -e "${CYAN}cd ~/wuzapi${NC}                   # Entrar no diretório"
    echo -e "${CYAN}./wuzapi -logtype=console -color=true${NC}  # Executar manualmente"
    echo -e "${CYAN}./monitor_wuzapi.sh${NC}           # Executar com monitoramento"
    echo -e "${CYAN}nano .env${NC}                     # Editar configurações"
    echo -e "\n${WHITE}Para iniciar com monitoramento:${NC}"
    echo -e "${GREEN}cd ~/wuzapi && ./monitor_wuzapi.sh${NC}"
    echo -e "\n${YELLOW}Atenção: O WhatsApp Web precisa estar acessível!${NC}"
}

# Executar instalação
main
