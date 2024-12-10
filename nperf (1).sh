#!/bin/bash                                                            
# ====================================#
#
#  Nperf - data: 14/09/2023
#  
# ====================================#
#  
#  autor: Rafael Burger de Oliveira
#
# ====================================#
#  
#  Instalando Nperf
#
# ====================================#
#
# Requerimentos
# CPU 2vCPU
# Memory 4GB
# Storage 50GB
#
# ====================================#

# Criaçao de usuario
echo "Insira o nome de usuario:"
read user
useradd $user
echo "Insira a senha para o usuario $user: "
read senha

mkdir /home/$user

if [ "$senha" == "" ]
then
    echo "Insira uma senha válida..."
    echo "Senha para $user: "
    read senha
else
    echo "$user":"$senha" | chpasswd
fi

# Correçao de Repositorio
export PATH=$PATH:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
echo "PATH="/sbin:/usr/sbin:/bin:/usr/bin:/usr/local/bin:/usr/local/sbin:/usr/games:/usr/local/games"" >> /etc/environment

# Atualizando
apt update; apt upgrade -y
apt install -y vim nano wget net-tools sudo

# Configurando Firewall
apt-get install -y nftables
echo "
#!/usr/sbin/nft -f

flush ruleset                                                                    
                                                                                 
table inet firewall {
                                                                                 
    chain inbound_ipv4 {

        icmp type echo-request limit rate 5/second accept      
    }

    chain inbound_ipv6 {

        icmpv6 type { nd-neighbor-solicit, nd-router-advert, nd-neighbor-advert } accept                                                                         
        icmpv6 type echo-request limit rate 5/second accept
    }

    chain inbound {                                                              
        type filter hook input priority 0; policy drop;
        ct state vmap { established : accept, related : accept, invalid : drop } 
        iifname lo accept
        meta protocol vmap { ip : jump inbound_ipv4, ip6 : jump inbound_ipv6 }
        tcp dport { 80, 443, 8080, 8081, 8443, 22, 2210, 53 } accept
        udp dport { 53 } accept

    }                                                                            
                                                                                 
    chain forward {                                                                              
        type filter hook forward priority 0; policy drop;                        
    }                                                                            
                                                                                 
}
" > /etc/nftables.conf
systemctl start nftables
systemctl enable nftables

# https://wiki.nperf.com/en/nperf-server/installation
apt-get -y install lsb-release gnupg &&\
wget -qO- https://repo.nperf.com/apt/conf/nperf-server.gpg.key | gpg --dearmor > /usr/share/keyrings/nperf-archive-keyring.gpg &&\
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/nperf-archive-keyring.gpg] https://repo.nperf.com/apt $(lsb_release -sc) main non-free" >> /etc/apt/sources.list.d/nperf.list &&\
apt-get update &&\
apt-get -y install nperf-server

# Implementando IPV6
# sed -i 's/#BIND_IP="::"/BIND_IP="<Inserir IPV6>"/' /etc/nperf/nperf-server.conf

# Iniciando serviço
/etc/init.d/nperf-server start
systemctl enable nperf-server

# Checando site:
echo "Acesse primeiramente via IP e depois entre nesse site: https://server-check.nperf.com/"

# https://wiki.nperf.com/en/nperf-server/debian-ubuntu-auto-update
apt install cron-apt
echo 'autoremove -y' > /etc/cron-apt/action.d/9-autoremove &&\
echo 'dist-upgrade -y -o APT::Get::Show-Upgraded=true -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold' > /etc/cron-apt/action.d/5-install
printf '0 8 *\t* *\troot\ttest -f /var/run/reboot-required && /sbin/reboot\n' > /etc/cron.d/autoreboot
