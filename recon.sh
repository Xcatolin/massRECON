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

                          
## Localizando alvo e identificando endereço IP ##
echo -e "\e[36m[*]\e[39m Insira a URL alvo:"
echo -e '\e[36m* http://alvo.com  OU  https://alvo.com *\e[39m'
read alvop


## Separando a URL em 3 variáveis: com protocolo, sem protocolo e apenas o domínio ##
## Cada variável tem seu uso específico, com ou sem o protocolo incluso na URL e o domínio separado ##
dominio=$(echo $alvop | awk -F[/:] '{print $4}')
alvo=$(echo $alvop | cut -f3 -d"/")
echo ''
host $alvo | grep "has address" | cut -d ' ' -f4 > ip
ip=$(cat ip)

## Criando diretório com o respectivo nome para armazenar os arquivos ##
mkdir $alvo

## Enumerando subdomínios e armazenando em um arquivo com o respectivo nome ##
echo -e "\e[36m[*]\e[39m Enumerando subdomínios e armazenando no arquivo subs.txt..."

while read p; do

   if host $p.$dominio | grep "has address">>$alvo/subs.txt ; then echo ''>ip ; fi

done < dns.txt


## Removendo arquivo criado ##
rm ip


## Contando quantos subdomínios foram encontrados e printando na tela ##
wc -l $alvo/subs.txt | cut -d ' ' -f1>>numerosub
nsub=$(cat numerosub)
echo -e '\e[32m[+]\e[39m Foram encontrados' $nsub 'subdomínios!'
echo ' '


## Removendo arquivo criado ##
rm numerosub


## Separando os endereços IP dos subdomínios para o PortScan ##
cat $alvo/subs.txt | cut -d ' ' -f4>>$alvo/ips.txt


## Efetuando PortScan em massa utilizando todos os endereços IP da lista, filtrando os resultados e armazenando em um arquivo com o respectivo nome ##
echo -e "\e[36m[*]\e[39m Varrendo portas e armazenando no arquivo ports.txt..."
nmap -sS --open -iL $alvo/ips.txt | grep 'Nmap scan report for\|/tcp'>>$alvo/ports.txt


## Utilizando a URL junto ao protocolo para enumerar diretórios, filtrando os encontrados, armazenando em um arquivo ##
echo ''
echo -e "\e[36m[*]\e[39m Enumerando diretórios e armazenando no arquivo dirs.txt..."
dirb $alvop wordlist.txt | grep "CODE:200" >>$alvo/dirs.txt


## Contando quantos diretórios foram encontrados e printando na tela ##
wc -l $alvo/dirs.txt | cut -d ' ' -f1>>numerodir
ndir=$(cat numerodir)
echo -e '\e[32m[+]\e[39m Foram encontrados' $ndir 'diretórios!'
echo ' '


## Removendo arquivo criado ##
rm numerodir


## Separando subdomínios para a utilização do cURL ##
cat $alvo/subs.txt | cut -d ' ' -f1>>$alvo/curl.txt


## Utilizando a URL para verificar se o método OPTIONS está habilitado ##
echo -e "\e[36m[*]\e[39m Testando método OPTIONS..."

while read c; do

   if curl -v -X OPTIONS --silent https://$c 2>&1 | grep 'Host:\|allow' ; then echo ''>curl ; fi
   	
done < $alvo/curl.txt


## Removendo arquivo criado ##
rm curl


## Imprimindo na tela onde fica salvo todo o resultado do teste ##
echo ''
echo -e '\e[36m* O resultado de todos os testes está armazenado no diretório '$alvo'! *\e[39m'



### VERSÃO ANTIGA DO PORTSCAN ###
## Utilizando o IP para varrer portas ##
#echo -e "\e[36m[*]\e[39m Varrendo portas..."
#echo " "
#portas="21  22  23  25  53  66  79  80  107  110  111  118  119  137  138  139  143  150  161  194  209  217  389  407  443  445  465  515  522  531  568  569  587  666  700  701  992  993  995  1024  1414  1417  1418  1419  1420  1424  1434  1503  1547  1720  1731  1812  1813  2300  2301  2302  2303  2304  2305  2306  2307  2308  2309  2310  2311  2400  2611  2612  3000  3128  3306  3389  3568  3569  4000  4099  4661  4662  4665  5190  5500  5631  5632  5670  5800  5900  6003  6112  6257  6346  6500  6667  6699  6700  6880  6891  6892  6893  6894  6895  6896  6897  6898  6899  6900  6901  7000  7002  7013  7500  7640  7642  7648  7649  7777  7778  7779  7780  7781  8000  8080  9000  9004  9005  9008  9012  9013  12000  12053  12083  12080  12120  12122  24150  26000  26214  27015  27500  27660  27661  27662  27900  27910  47624  56800"
#echo -e "\e[32m[+]\e[39m Portas encontradas: " && nc -v -w2 $ip $portas 2>&1 | grep succeeded | cut -d ' ' -f4
