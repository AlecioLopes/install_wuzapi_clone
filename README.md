# install_wuzapi_clone

📥 PASSO 1: BAIXAR E EXECUTAR O SCRIPT
## 1. Baixar o script diretamente do GitHub
```curl -O https://raw.githubusercontent.com/AlecioLopes/install_wuzapi_clone/refs/heads/main/install_wuzapi.sh```

# 2. Tornar o script executável
chmod +x install_wuzapi.sh

# 3. Executar o script de instalação
./install_wuzapi.sh

🚀 PASSO 2: INICIAR O WUZAPI
Após a instalação, você tem duas opções:
Opção A: Com monitoramento (RECOMENDADO)

cd ~/wuzapi
./monitor_wuzapi.sh

Opção B: Execução manual

cd ~/wuzapi
./wuzapi -logtype=console -color=true

🔍 VERIFICANDO SE ESTÁ FUNCIONANDO:

# Verificar se o processo está rodando
ps aux | grep wuzapi

# Verificar porta 8080
netstat -tuln | grep 8080

# Verificar logs
cat wuzapi_monitor.log
