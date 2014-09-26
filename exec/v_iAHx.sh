#!/bin/bash

# ------------------------------------------------------------------------- #
# v_iAHx.sh - Verifica resultados de iAHx-server em homologacao e producao
# ------------------------------------------------------------------------- #
#      Entrada:	Arquivo de URL de teste (testar.rol)
#		PARM1  nome do arquivo (e caminho) com lista de URL a testar
#		Opcoes de execucao
#		 --changelog		Mostra historico de alteracoes
#		 -c, --config NOMEARQU	Nome do arquivo com as configuracoes
#		 -o, --output NOMEARQU	Nome do arquivo com as instancias aprovadas
#		 -d N, --debug N	Nivel de depuracao
#		 -h, --help		Mostra o help
#		 -s, --server		Hostname do servidor de producao
#		 -V, --versao		Mostra a versao
#	 Saida:	Arquivo com a lista de instancias aprovadas se houver PARM1
#     Corrente:	qualquer
#      Chamada:	v_iAHx.sh <TESTAR.lst> [-h|-V|--changelog] [-d N] [-s <servername>] [-c <config_file>] [-o <output_file>]
#      Exemplo:	v_iAHx.sh transfere.lst
#  Objetivo(s):	Testar resultados totais das instancdias
#  Comentarios:	testar.rol deve estar em um dos seguintes diretorios:
#			corrente
#			$HOME/bin
#			$PATH_PROC/tabs
#			$PATH_PROC/bin
#			$PATH_IAHX
#		v_iAHx.cfg deve estar no mesmo diretorio deste arquivo
#  Observacoes:	DEBUG eh uma variavel mapeada por bit conforme
		_BIT0_=1;	# Aguarda tecla <ENTER>
		_BIT1_=2;	# Mostra mensagens de DEBUG
		_BIT2_=4;	# Modo verboso
		_BIT3_=8;	# Modo debug de linha -v
		_BIT4_=16;	# Modo debug de linha -x
		_BIT5_=32;	# .
		_BIT6_=64;	# .
		_BIT7_=128;	# Opera em modo FAKE
#	 Notas:	Deve ser executado como usuario 'tomcat'
# Dependencias:	Variaveis de ambiente que devem estar previamente ajustadas:
#		    TRANSFER	username para troca de dados entre servidores
#		   PATH_IAHX	caminho para os executaveis do pcte
#		   PATH_PROC	caminho para a area de processamento
#		  PATH_INPUT	caminho para os dados de entrada
#		  INDEX_ROOT	Raiz dos indices de busca
#		SRV_PRODUCAO	hostname do servidor de producao
# -------------------------------------------------------------------------- #
#  Centro Latino-Americano e do Caribe de Informação em Ciências da Saúde
#     É um centro especialidado da Organização Pan-Americana da Saúde,
#           escritório regional da Organização Mundial da Saúde
#                        BIREME / OPS / OMS (P)2013
# -------------------------------------------------------------------------- #
# Historico
# versao data, Responsavel
#	- Descricao
cat > /dev/null <<HISTORICO
vrs:  0.01 20120319, FJLopes
	- Edicao Original
vrs:  0.02 20120402, FJLopes
	- Arquivo de saida conforme parametro 1 ou seu default
vrs:  1.00 20120411, FJLopes
	- Limpeza de area de trabalho
vrs:  1.01 20120529, FJLopes
	- Protecao contra falta de retorno no teste
vrs:  2.00 20131008, FJLopes
	- Configuracao e lista de teste flexiveis
HISTORICO

# ========================================================================= #
# PegaValor - Obtem valor de uma clausula
# PARM $1 - Item de configuracao a ser lido
# Obs: O arquivo a ser lido eh o contido na variavel CONFIG
#
PegaValor () {
        if [ -f "$CONFIG" ]; then
                grep "^$1" $CONFIG > /dev/null
                RETORNO=$?
                if [ $RETORNO -eq 0 ]; then
                        RETORNO=$(grep $1 $CONFIG | tail -n "1" | cut -d "|" -f "2")
                        echo $RETORNO
                else
                        false
                fi
        else
                false
        fi
        return
}
#

# ========================================================================== #
# isNumber - Determina se o parametro eh numerico
# PARM $1  - String a verificar se eh numerica ou nao
# Obs.:   `-eq` soh opera bem com numeros portanto se nao for numero da erro
#
isNumber() {
	[ "$1" -eq "$1" ] 2> /dev/null
	return $?
}
#
		
# ========================================================================= #

source	$PATH_EXEC/inc/infoini.inc
source	$PATH_EXEC/inc/lddefault.viAHx.inc
source	$PATH_EXEC/inc/mhelp_opc.viAHx.inc

# ------------------------------------------------------------------------- #
# Suporte a depuracao

if [ "$DEBUG" -gt 1 ]; then
	echo "= DISPLAY DE VALORES INTERNOS ="
	echo "==============================="

	test -n "$PARM1" && echo "PARM1 = $PARM1"
	test -n "$PARM2" && echo "PARM2 = $PARM2"
	test -n "$PARM3" && echo "PARM3 = $PARM3"
	test -n "$PARM4" && echo "PARM4 = $PARM4"
	test -n "$PARM5" && echo "PARM5 = $PARM5"
	test -n "$PARM6" && echo "PARM6 = $PARM6"
	test -n "$PARM7" && echo "PARM7 = $PARM7"
	test -n "$PARM8" && echo "PARM8 = $PARM8"
	test -n "$PARM9" && echo "PARM9 = $PARM9"
	echo
	test -n "$CONFIG"       && echo "      CONFIG = $CONFIG"
	test -n "$QUERY_STRING" && echo "QUERY_STRING = $QUERY_STRING"
	test -n "$SERVER"       && echo "    Producao = $SERVER"

	echo "==============================="
fi

[ $(($DEBUG & $_BIT6_)) -ne 0 ] && exit 0

# ------------------------------------------------------------------------- #
echo "[TIME-STAMP] $HRINI [:INI:] $TREXE $LCORI"

#     12345678901234567890
echo "[tiAHx]  1         - Garante condicoes de execucao"
if [ "$USER" != "tomcat" ]; then
	echo "*** FAIL *** User not authorized. Must be \"tomcat\". Is: $USER *** EXIT CODE (1) ***"
	exit 1
fi

[ -d $HOME/log ] || mkdir -p $HOME/log && echo "[tiAHx]  0         - Diretorio de logs nao existia e foi criado."

echo "[tiAHx]  2         - Efetua preparos nos arquivos de entrada e saida"

[ -f "trf.rol" ] && rm -f trf.rol
[ -f  "$$.err" ] && rm -f $$.err

# Ordem de busca pelo arquivo com a lista de teste (testar.rol):
#	1 diretorio Local (mais prioritario)
#	2 $PATH_PROC/tabs
#	3 $PATH_PROC/bin
#	4 $PATH_IAHX
#	5 $TABS           (desabilitado)
#
# [ -s "$TABS/testar.rol" ]         && _PATH_="$TABS"
[ -s "$PATH_IAHX/testar.rol" ]      && _PATH_="$PATH_IAHX"
[ -s "$PATH_EXEC/testar.rol" ]      && _PATH_="$PATH_EXEC"
[ -s "$PATH_EXEC/tabs/testar.rol" ] && _PATH_="$PATH_EXEC/tabs"
[ -s "./testar.rol" ]               && _PATH_="."

cat $_PATH_/$PARM2 | tr " " "_" > $$.rol

# Se o modo verboso estiver ativado mostra a lista de instancias a testar
if [ "$DEBUG" -gt 1 ]; then
	echo "###############"
	cat $$.rol
	echo "###############"
fi
if [ "$DEBUG" -eq 1 ]; then
	echo -n "Tecle algo para continuar: "
	read Debug
fi

echo "[tiAHx]  3         - Opera cada item da lista de teste"
echo -e "Instancia;Homolog;Producao;diferenca" > $$.log
for i in $(seq $(wc -l $$.rol | awk '{ print $1 }'))
do

	# Efetua o parser do conteudo do arquivo de URLs a testar
	INSTANCIA=$(head -$i $$.rol | tail -1 | cut -d "|" -f "2")
	TEMPORARIO=$(head -$i $$.rol | tail -1 | cut -d "|" -f "1")
	URLHOMOL=$(echo $TEMPORARIO | tr -d "_")
	URLPRODU="$SERVER:"$(echo $URLHOMOL | cut -d ":" -f "2")
	if [ "$DEBUG" -gt 3 ]; then
		echo ===================================
		echo TEMPORARIO: $TEMPORARIO
		echo   URLHOMOL: $URLHOMOL
		echo   PRODUCAO: $SERVER
		echo ===================================
	fi
	echo "[tiAHx]  3.$(printf %2d $i)      - Trata $INSTANCIA"

	# Toma o retorno XML da homologacao
	wget -O homologa "$URLHOMOL/select/?q=*:*&rows=0" 2> /dev/null
	# Toma o retorno XML da producao
	wget -O producao "$URLPRODU/select/?q=*:*&rows=0" 2> /dev/null
	
	# Toma a qtde de resultados da homologacao
	homo=$(cat homologa | sed 's/></></g' | tr "" "\012" | grep "response\" numFound=\"" | cut -d '"' -f "4")
	# Toma a qtde de resultados da homologacao
	prod=$(cat producao | sed 's/></></g' | tr "" "\012" | grep "response\" numFound=\"" | cut -d '"' -f "4")
	[ -z $homo ] && homo=0
	[ -z $prod ] && prod=0
	if [ "$DEBUG" -gt 3 ]; then
		echo "#############################"
		echo "Qtde em homo : $homo"
		echo "Qtde em prod : $prod"
		echo "#############################"
	fi
	
	echo -e "$INSTANCIA;$homo;$prod;$(expr $homo - $prod)" >> $$.log
	# Avalia o resultado
	if [ $homo -ge $prod ]; then
		# Determina conteudo para a lista de transferencia
		SIGLA=$(echo "$URLHOMOL" | cut -d "/" -f "2" | cut -d "-" -f "1")
		if [ "$SIGLA" = "bvs" ]; then
			SIGLA=$(echo "$URLHOMOL" | cut -d "/" -f "2" | cut -d "-" -f "2")
		fi

#		# Trata excecoes para resultado positivo
#		if [ ! "$SIGLA" = "iahlinks" ]; then
			echo $SIGLA >> $PARM1
#		fi
	else
		echo -n "Erro em: "                                                    >> $$.err
		echo -n $INSTANCIA | tr "_" " "                                        >> $$.err
		echo -n " ("                                                           >> $$.err
		echo -n $(echo -n "$URLHOMOL" | cut -d "/" -f "2" | cut -d "-" -f "1") >> $$.err
		echo ")"                                                               >> $$.err
	fi
done

echo
echo "-------------------------------------------------------------------------------"
echo

if [ -f "$$.log" ]; then
	cat $$.log | tr "_" " "
	mv $$.log $PATH_EXEC/logs/$(date '+%Y%m%d_%H%M%S').iAHx.csv
fi

echo
echo "-------------------------------------------------------------------------------"
echo

[ -f "$$.err" ] && cat $$.err
echo

# ------------------------------------------------------------------------- #
# Limpa area de trabalho
[ -f "$$.rol" ] && rm -f $$.rol
[ -f "$$.log" ] && rm -f $$.log
[ -f "$$.err" ] && rm -f $$.err
[ -f "homologa" ] && rm -f homologa
[ -f "producao" ] && rm -f producao

# ------------------------------------------------------------------------- #
#unset CIPAR
# Contabiliza tempo de processamento e gera relato da ultima execucao

HRFIM=$(date '+%Y.%m.%d %H:%M:%S')
HFINI=$(date '+%s')
TPROC=$(expr $HFINI - $HINIC)

# Determina componentes de caminho
LGDTC=$(pwd)
LGRAIZ=/$(echo "$LGDTC" | cut -d/ -f2)
LGPRD=$(expr "$LGDTC" : '/[^/]*/\([^/]*\)')

source $PATH_EXEC/inc/infofim.inc
# ------------------------------------------------------------------------- #
cat > /dev/null <<SPICEDHAM
CHANGELOG
20120402 Trocado o arquivo de redirecao para sigla de trf.rol para \$PARM1
         Adicao da opcao changelog, alteracao do texto de help
         acrescentando os valores default dos parametros e numero de versao
         para 0.02
20120411 Completado o ciclo de limpeza da area de trabalho para eliminar
         os arquivos 'homologa' e 'producao'
20120529 Incluido tratamento para retorno 'vazio' de qtde de resultados
20131008 Flexibilizada a localizacao do arquivo lista de teste, liberando
         o programa para execucao em qualquer diretorio
	 Expressão de busca pode estar no arquivo cfg, na ausencia assume
	 busca padrao *:*
SPICEDHAM

