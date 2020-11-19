#!/bin/bash


echo -n $'\E[96m'                          
echo $'  _____  ______ _____ ____  _   _ '
echo $' |  __ \|  ____/ ____/ __ \| \ | |'
echo $' | |__) | |__ | |   | |  | |  \| |'
echo $' |  _  /|  __|| |   | |  | | . ` |'
echo $' | | \ \| |___| |___| |__| | |\  |'
echo $' |_|  \_\______\_____\____/|_| \_|'
                              
echo -e "				   ┌┐ ┬ ┬  ╔═╗╔═╗╔═╗╔╦╗╔═╗╦  ╦ ╔╗╔"
echo -e "				───├┴┐└┬┘  ╚═╗║  ╠═╣ ║ ║ ║║  ║ ║║║"
echo -e "				   └─┘ ┴   ╚═╝╚═╝╩ ╩ ╩ ╚═╝╩═╝╩ ╝╚╝\e[39m"


## Definindo que a variável alvop seja passada via argumento ## 
alvop=$1


## Checando se o alvo foi passado via argumento, e caso contrário, printar exemplo de uso ##
if [ $# -eq 0 ]
  then
    clear && echo -e "\e[31m[X]\e[39m Error: No target defined!"
    echo -e '\e[36m* Usage: ./recon.sh https://target.com *\e[39m'
  else


## Separando a URL em 3 variáveis: com protocolo, sem protocolo e apenas o domínio ##
## Cada variável tem seu uso específico, com ou sem o protocolo incluso na URL e o domínio separado ##
dominio=$(echo $alvop | awk -F[/:] '{print $4}')
alvo=$(echo $alvop | cut -f3 -d"/")
echo ''
host $alvo | grep "has address" | cut -d ' ' -f4 > ip
ip=$(cat ip)


## Verificando se o diretório para armazenar os resultados existe, e criando o mesmo caso não exista ##
DIR="/home/resultados-massRECON"
if [ -d "$DIR" ]; then
  echo ""
else
        cd /home/ && mkdir resultados-massRECON
fi


## Verificando se o diretório com nome do alvo já existe, e criando o mesmo caso não exista ##
DIR="/home/resultados-massRECON/$alvo"
if [ -d "$DIR" ]; then
  echo ""
else
        cd /home/resultados-massRECON && mkdir $alvo
fi


## Voltando para o diretório do script ##
cd /usr/share/massRECON


## Enumerando subdomínios e armazenando em um arquivo com o respectivo nome ##
echo -e "\e[36m[*]\e[39m Enumerando subdomínios e armazenando no arquivo subs.txt..."

while read p; do

   if host $p.$dominio | grep "has address">/home/resultados-massRECON/$alvo/subs.txt ; then echo ''>ip ; fi

done < dns.txt


## Utilizando o amass para enumerar mais subdomínios ##
amass enum -d $alvo | grep "$alvo">>/home/resultados-massRECON/$alvo/subs.txt


## Utilizando o crt.sh para enumerar mais subdomínios ##
curl -s https://crt.sh/?q=%.$alvo > /tmp/curl.out
cat /tmp/curl.out | grep $alvo | grep TD | sed -e 's/<//g' | sed -e 's/>//g' | sed -e 's/TD//g' | sed -e 's/\///g' | sed -e 's/ //g' | sed -n '1!p' | sort -u > /home/resultados-massRECON/$alvo/subs.txt


## Utilizando o sort para remover duplicados e o httprobe para separar quais estão online ##
sort -u /home/resultados-massRECON/$alvo/subs.txt>>/home/resultados-massRECON/$alvo/uniqsubs.txt
cd /usr/share/httprobe && cat /home/resultados-massRECON/$alvo/uniqsubs.txt | ./httprobe >>/home/resultados-massRECON/$alvo/livesubs.txt
rm /home/resultados-massRECON/$alvo/subs.txt
rm /home/resultados-massRECON/$alvo/uniqsubs.txt


## Utilizando o EyeWitness para printar os subdomínios que estão online ##
cd /usr/share/eyewitness/Python && ./EyeWitness.py --web -f /home/resultados-massRECON/$alvo/livesubs.txt -d /home/resultados-massRECON/$alvo/eyewitness


## Voltando para o diretório do script ##
cd /usr/share/massRECON/


## Retirando os protocolos dos subdomínios para separar os endereços IP ##
cat /home/resultados-massRECON/$alvo/livesubs.txt | cut -d '/' -f3>>/home/resultados-massRECON/$alvo/ipsubs.txt


## Utilizando um laço para enumerar os endereços IP dos subdomínios enumerados ##
for sub in $(cat /home/resultados-massRECON/$alvo/ipsubs.txt):
do
	echo $sub | host $sub | grep "has address" | cut -d ' ' -f4>>/home/resultados-massRECON/$alvo/ips.txt
done
rm /home/resultados-massRECON/$alvo/ipsubs.txt


## Removendo arquivo criado ##
rm ip


## Removendo os endereços repetidos para o portscan ##
uniq -u /home/resultados-massRECON/$alvo/ips.txt>>/home/resultados-massRECON/$alvo/uniqips.txt
rm /home/resultados-massRECON/$alvo/ips.txt


## Escaneando portas utilizando todos os endereços IP da lista, filtrando os resultados e armazenando em um arquivo com o respectivo nome ##
echo -e "\e[36m[*]\e[39m Varrendo portas e armazenando no arquivo ports.txt..."
nmap -sS --open -iL /home/resultados-massRECON/$alvo/ips.txt | grep 'Nmap scan report for\|/tcp'>>/home/resultados-massRECON/$alvo/ports.txt


## Imprimindo na tela onde fica salvo todo o resultado do teste ##
echo ''
echo -e '\e[36m* O resultado de todos os testes está armazenado no diretório '/home/resultados-massRECON/$alvo'! *\e[39m'
fi
