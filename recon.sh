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
    clear && echo -e "\e[31m[X]\e[39m Erro: alvo não definido!"
    echo -e '\e[36m* Exemplo de uso: ./recon.sh https://alvo.com *\e[39m'
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


## Voltando para o diretório do script ##
cd /usr/share/massRECON


## Utilizando o EyeWitness para printar os subdomínios que estão online ##
eyewitness --web -f /home/resultados-massRECON/$alvo/livesubs.txt -d /home/resultados-massRECON/$alvo/eyewitness


## Utilizando um laço para enumerar os endereços IP dos subdomínios enumerados ##
for sub in $(cat /home/resultados-massRECON/$alvo/livesubs.txt);
do
resposta=$(echo $sub&&host $sub)
echo "$resposta" | grep "has address" | cut -d ' ' -f4 >>/home/resultados-massRECON/$alvo/ips.txt;
done


## Removendo arquivo criado ##
rm ip


## Separando os endereços IP dos subdomínios para o PortScan ##
cat /home/resultados-massRECON/$alvo/subs.txt | cut -d ' ' -f4>>/home/resultados-massRECON/$alvo/ips.txt


## Escaneando portas utilizando todos os endereços IP da lista, filtrando os resultados e armazenando em um arquivo com o respectivo nome ##
echo -e "\e[36m[*]\e[39m Varrendo portas e armazenando no arquivo ports.txt..."
nmap -sS --open -iL /home/resultados-massRECON/$alvo/ips.txt | grep 'Nmap scan report for\|/tcp'>>/home/resultados-massRECON/$alvo/ports.txt


## Removendo os endereços repetidos para o portscan ##
uniq -u /home/resultados-massRECON/$alvo/ips.txt>>/home/resultados-massRECON/$alvo/uniqips.txt


## Imprimindo na tela onde fica salvo todo o resultado do teste ##
echo ''
echo -e '\e[36m* O resultado de todos os testes está armazenado no diretório '/home/resultados-massRECON/$alvo'! *\e[39m'


fi






### VERSÃO ANTIGA DO PORTSCAN ###
## Utilizando o IP para varrer portas ##
#echo -e "\e[36m[*]\e[39m Varrendo portas..."
#echo " "
#portas="21  22  23  25  53  66  79  80  107  110  111  118  119  137  138  139  143  150  161  194  209  217  389  407  443  445  465  515  522  531  568  569  587  666  700  701  992  993  995  1024  1414  1417  1418  1419  1420  1424  1434  1503  1547  1720  1731  1812  1813  2300  2301  2302  2303  2304  2305  2306  2307  2308  2309  2310  2311  2400  2611  2612  3000  3128  3306  3389  3568  3569  4000  4099  4661  4662  4665  5190  5500  5631  5632  5670  5800  5900  6003  6112  6257  6346  6500  6667  6699  6700  6880  6891  6892  6893  6894  6895  6896  6897  6898  6899  6900  6901  7000  7002  7013  7500  7640  7642  7648  7649  7777  7778  7779  7780  7781  8000  8080  9000  9004  9005  9008  9012  9013  12000  12053  12083  12080  12120  12122  24150  26000  26214  27015  27500  27660  27661  27662  27900  27910  47624  56800"
#echo -e "\e[32m[+]\e[39m Portas encontradas: " && nc -v -w2 $ip $portas 2>&1 | grep succeeded | cut -d ' ' -f4


### FUNÇÃO ANTIGA PARA TESTAR MÉTODO OPTIONS ###

## Separando subdomínios para a utilização do cURL ##
#cat /home/resultados-massRECON/$alvo/subs.txt | cut -d ' ' -f1>>/home/resultados-massRECON/$alvo/curl.txt


## Utilizando a URL para verificar se o método OPTIONS está habilitado ##
#echo -e "\e[36m[*]\e[39m Testando método OPTIONS..."

#while read c; do

#   if curl -v -X OPTIONS --silent https://$c 2>&1 | grep 'Host:\|allow' ; then echo ''>curl ; fi
   	
#done < /home/resultados-massRECON/$alvo/curl.txt


## Removendo arquivo criado ##
#rm curl


### VERSÃO INUTILIZADA DE DIRSCAN ###
## Utilizando a URL junto ao protocolo para enumerar diretórios, filtrando os encontrados, armazenando em um arquivo ##
#echo ''
#echo -e "\e[36m[*]\e[39m Enumerando diretórios e armazenando no arquivo dirs.txt..."
#dirb $alvop wordlist.txt | grep "CODE:200" >>/home/resultados-massRECON/$alvo/dirs.txt


## Contando quantos diretórios foram encontrados e printando na tela ##
#wc -l /home/resultados-massRECON/$alvo/dirs.txt | cut -d ' ' -f1>>numerodir
#ndir=$(cat numerodir)
#echo -e '\e[32m[+]\e[39m Foram encontrados' $ndir 'diretórios!'
#echo ' '


## Removendo arquivo criado ##
#rm numerodir