# install_wuzapi_clone

# 📥 PASSO 1: BAIXAR E EXECUTAR O SCRIPT
## 1. Baixar o script diretamente do GitHub
```curl -O https://raw.githubusercontent.com/AlecioLopes/install_wuzapi_clone/refs/heads/main/install_wuzapi.sh```

## 2. Tornar o script executável
```chmod +x install_wuzapi.sh```

## 3. Executar o script de instalação
```./install_wuzapi.sh```

# 🚀 PASSO 2: INICIAR O WUZAPI
Após a instalação, você tem duas opções:
## Opção A: Com monitoramento (RECOMENDADO)

```cd ~/wuzapi```
```./monitor_wuzapi.sh``` com monitoramento

Opção B: Execução manual

```cd ~/wuzapi```
```./wuzapi -logtype=console -color=true```

# 🔍 VERIFICANDO SE ESTÁ FUNCIONANDO:

## Verificar se o processo está rodando
```ps aux | grep wuzapi```

## Verificar porta 8080
```netstat -tuln | grep 8080```

## Verificar logs
```cat wuzapi_monitor.log```

# Se precisar alterar configurações:
```cd ~/wuzapi```
```nano .env```

# 🔄 PARA REINICIAR OU PARAR:

## Parar o WuzAPI
```pkill wuzapi```

## Parar o monitoramento
```pkill -f monitor_wuzapi```

## Reiniciar tudo
```cd ~/wuzapi```
```pkill wuzapi```
```./monitor_wuzapi.sh```

# ⏰ INICIAR AUTOMATICAMENTE COM O TERMUX:

Para iniciar automaticamente quando o Termux abrir:

- Crie o diretório de boot (se não existir):
```mkdir -p ~/.termux/boot```

- Crie um script de inicialização:
```echo '#!/data/data/com.termux/files/usr/bin/bash```
```cd ~/wuzapi```
```./monitor_wuzapi.sh' > ~/.termux/boot/start-wuzapi.sh```

```chmod +x ~/.termux/boot/start-wuzapi.sh```
