#!/bin/bash

# -------------------------------------------------------------------------- #
# enviaDados.sh - Efetua a transferencia do indice para servidor de producao
# -------------------------------------------------------------------------- #
#    Corrente :	/bases/iahx/proc/INSTANCIA/main/
#     Chamada :	enviaDados.sh [-h|-V|--changelog] [-d N] [-H|-t] [-x] <ID_INDEX>
#     Exemplo :	enviaDados.sh -H bioetica
#		enviaDados.sh regional
# Objetivo(s) :	Tranferir indice atualizado para servidor destino
#  IMPORTANTE :	Deve ser executado com o user 'tomcat'
# -------------------------------------------------------------------------- #
#  Centro Latino-Americano e do Caribe de Informação em Ciências da Saúde
#     é um centro especialidado da Organização Pan-Americana da Saúde,
#           escritório regional da Organização Mundial da Saúde
#                      BIREME / OPS / OMS (P)2012-14
# -------------------------------------------------------------------------- #
# Historico
# versao data, Responsavel
#       - Descricao
cat > /dev/null <<HISTORICO
vrs:  0.00 20140704, FJLopes
	- Edicao original
vrs:  0.01 20140804, FJLopes
	- capacita a enviar para servidores de homologacao e de teste
vrs:  1.00 20140901, FJLopes
	- mecanismo de controle antireentrancia
HISTORICO

# ========================================================================== #
#                                BIBLIOTECAS                                 #
# ========================================================================== #
# Incorpora biblioteca especifica de iAHx na versao 2
source	$PATH_EXEC/inc/iAHx2.inc
# Conta com as funcoes:
#  rdANYTHING		PARM1		Retorna o ID do indice, por qualquer item
#  rdINDEX		PARM1		Retorna o nome do indice
#  rdINSTANCIA		PARM1		Retorna o nome da instancia
#  rdDIRETORIO		PARM1		Retorna o diretorio de processamento
#  rdINDEXFILE		PARM1		Retorna caminho relativo dos dados
#  rdINDEXROOT		PARM1		Retorna o caminho da raiz do indice
#  rdTESTE		PARM1		Retorna o nome do servidor de teste
#  rdHOMOLOG		PARM1		Retorna o nome do servidor de homologacao
#  rdPRODUCAO		PARM1		Retorna o nome do servidor de producao
#  rdINBOX		PARM1		Retorna o diretorio de dados no INBOX
#  rdLILDBIWEB		PARM1		Retorna o caminho para bases externas em LilDBI-Web
#  rdPORT		PARM1		Obtem numero do iahx-server configurado para o indice
#  rdSERVER		PARM1		Obtem numero di iahx-server solicitado para o indice
#  rdSTATUS		PARM1		Status da instancia (Ativo / Desativo /?)
#  rdPROCESSA		PARM1		Obtem estado do processamento run/notrun
#  rdINFO		PARM1		Retorna informacoes do indice/instancia
#  rdTYPE		PARM1		Retorna tipo de processaamento (MANUAL / PROGREAMADO)
#  rdPERIOD		PARM1		Periodicidade de processamento
#  rdALL		PARM1		Retorna pares ID Instancia
#  rdTODAS		PARM1		Retorna com a lista de instancias no arquivo de PARM1
#  rdPORTAL		PARM1		Nome do portal
#  rdURLOK		PARM1		URL disponivel (sim / nao / ?)
#  rdURL		PARM1		URL (parte fixa)
#  rdHOMAPPL		PARM1		Retorna o nome do servidor de homologacao de aplicacao
#  rdVERSION		PARM1		Versão do iAHx
#  rdLANG		PARM1		Obtem lista de idiomas da interface
#  rdOBSERVATION	PARM1		Observacoes sobre a Instancia
#  rdCONSULTA		PARM1		Indice consultado
#  rdTIMEHOMOL		PARM1		Ultima atualizacao em homologacao
#  rdTIMEPROD		PARM1		Ultima atualizacao em producao
#  rdBASES		PARM1 PARM2	Bases participantes do indice

# Incorpora a biblioteca de armadilha de sinais
source	$PATH_EXEC/inc/armadilhar.inc
# Conta com as funcoes:
#  clean_term	PARM1	Trata interrupcao por SIGTERM
#  clean_hup	PARM1	Trata interrupcao por SIGHUP
#  clean_int	PARM1	Trata interrupcao por SIGINT
#  clean_kill	PARM1	Trata interrupcao por outros sinais
#  clean_exit	PARM1	Trata interrupcao por SIGEXIT
#  leF		PARM1	Le nivel corrente do flag
#  contaF	PARM1	Sobe um nivel de execucao
#  descontaF	PARM1	Desce um nivel de execucao
#  resetF	PARM1	Limpa nivel de execucao

# Incorpora biblioteca de controle basico de execucao
source	$PATH_EXEC/inc/infoini.inc
#  isNumber	PARM1	Retorna FALSE se PARM1 nao for numerico
#  rdconfig	PARM1	Item de configuracao a aser lido
# Estabelece as variaveis:
#  CURRD	Diretorio corrente no momento da carga
#  HINIC	Tempo inicial em segundos desde 01/01/1970
#  HRINI	Hora de inicio no formato YYYYMMDD hh:mm:ss
#  _DIA_	Dia calendario no formato DD
#  _MES_	Mes calendario no formato MM
#  _ANO_	Ano calendario no formato YYYY
#  TREXE	Demoninacao do programa em execucao
#  PRGDR	Path para o programa em execucao
#  LCORI	Linha de comando original da chamada
#  DTFJL	Data calendario no formato YYYYMMDD

# ========================================================================== #
# FUNCOES LOCAIS

lmpresid(){
# Funcao de limpeza do diretorio do indice a transferir
# PARM1 - Caminho a ser limpo ($RAIZ/$DIRET/$SUFF)
#         Arquivo $DIRET/antes.txt com a listagem original do diretorio a limpar

# Lista arquivos resultantes no diretorio destino
ls $1 > $PATH_PROC/$DIRET/depois.txt

echo "Limpa a area de trabalho"
diff $PATH_PROC/$DIRET/antes.txt $PATH_PROC/$DIRET/depois.txt | grep ">" | tr -d ">" > $PATH_PROC/$DIRET/APAGAR.rol
for i in $(< $PATH_PROC/$DIRET/APAGAR.rol)
do
	echo "Eliminando o temporario: $i"
	rm -f $i
done
}
# ========================================================================== #

#        1         2         3         4         5         6         7         8
#2345678901234567890123456789012345678901234567890123456789012345678901234567890
AJUDA_USO="
Efetua a transferencia de dados para servidor remoto
Uso: $TREXE [OPCOES] <PARM1>
OPCOES:
 -h, --help             Exibe este texto de ajuda e para a execucao
 -V, --version          Exibe a versao corrente e para a execucao
 -d, --debug NIVEL      Define nivel de depuracao com valor numerico positivo
 --changelog            Exibe o historico de alteracoes e para a execucao
 -H, --homolog          Envia para servidor de homologacao (DADOS)
 -t, --test             Envia para servidor de teste       (APLIC)
 -x, -X                 Nao envia dados para destino

PARAMETROS:
 PARM1  Identificador do indice a processar
"
# -------------------------------------------------------------------------- #
# Assume valores DEFAULT
source	$PATH_EXEC/inc/lddefault.dummy.inc
# Valores adicionais
FLG_TESTE=0;	# Envio para TESTE
FLG_HOMOL=0;	# Envio para HOMOLOGACAO
FLG_PRODU=1;	# Envio para PRODUCAO

# Tratamento das opcoes de linha de comando (qdo houver alguma)
while test -n "$1"
do
	case "$1" in

		-t | --test)
			if [ $FLG_HOMOL -eq 1 ]; then
				echo "Erro da chamada, as opcoes -t e -h sao mutuamente exclusivas"
				exit 5
			else
				FLG_TESTE=1
				FLG_PRODU=0
			fi
			;;

		-H | --homolog)
			if [ $FLG_TESTE -eq 1 ]; then
				echo "Erro da chamada, as opcoes -t e -h sao mutuamente exclusivas"
				exit 5
			else
				FLG_HOMOL=1
				FLG_PRODU=0
			fi
			;;

		-x | -X)
			NOXMT="1"
			OPC_XMT="-x"
			;;

		-h | --help)
			echo "$AJUDA_USO"
			exit
			;;

		-V | --version)
			echo -e -n "\n$TREXE "
			grep '^vrs: ' $PRGDR/$TREXE | tail -1
			echo
			exit
			;;

		-d | --debug)
			shift
			isNumber $1
			[ $? -ne 0 ] && echo -e "\n$TREXE: O argumento da opção DEBUG deve existir e ser numericoi.\n$AJUDA_USO" && exit 2
			DEBUG=$1
			N_DEB=$(expr $(($DEBUG & 6)) / 2)
			FAKE=$(expr $(($DEBUG & _BIT7_)) / 128)
			;;

		--changelog)
			TOTLN=$(wc -l $0 | awk '{ print $1 }')
			INILN=$(grep -n "<SPICEDHAM" $0 | tail -1 | cut -d ":" -f "1")
			LINHAI=$(expr $TOTLN - INILN)
			LINHAF=$(expr $LINHAI - 2)
			echo -e -n "\n$TREXE - "
			grep '^vrs: ' $PRGDR/$TREXE | tail -1
			echo -n "==> "
			tail -$LINHAI $0 | head -$LINHAF
			echo
			exit
			;;

		*)
			if [ $(expr index "$1" "-") -ne 1 ]; then
				if test -z "$PARM1"; then PARM1=$1; shift; continue; fi
				if test -z "$PARM2"; then PARM2=$1; shift; continue; fi
			else
				echo "Opcao nao valida! ($1)"
			fi
			;;
	esac
	shift
done

# Para DEBUG assume valor DEFAULT antecipadamente
isNumber $DEBUG
[ $? -ne 0 ] && DEBUG=0

# -------------------------------------------------------------------------- #
# Avalia nivel de depuracao e monta parametro para expansao de comando

[ $(($DEBUG & $_BIT3_)) -ne 0  ] && set -v
[ $(($DEBUG & $_BIT4_)) -ne 0  ] && set -x

# ========================================================================== #

#     1234567890123456789012345
echo "[upDATA]  1         - UPDATE DATA"

# -------------------------------------------------------------------------- #
# Garante que a instancia esta definida (sai com codigo de erro 2 - Syntax Error)
if [ -z "$PARM1" ]; then
	echo "[upDATA]  1.01      - Erro na chamada falta o parametro 1"
	echo
	echo "Syntax error:- Missing PARM1"
	echo "$AJUDA_USO"
	exit 2
fi

# -------------------------------------------------------------------------- #
# Garante existencia da tabela de configuracao (sai com codigo de erro 3 - Configuration Error)
#                                            1234567890123456789012345
[ $N_DEB -ne 0 ]                    && echo "[upDATA]  0.00.01   - Testa se ha tabela de configuracao"
[ ! -s "$PATH_EXEC/tabs/iAHx.tab" ] && echo "[upDATA]  1.01      - Tabela iAHx nao encontrada" && exit 3

unset   IDIDX   INDEX
# Garante existencia do indice indicado na tabela de configuracao (sai com codigo de erro 4 - Configuration Failure)
# alem de tomar nome oficial do indice para o SOLR
#                                        1234567890123456789012345
[ $N_DEB -ne 0 ]                && echo "[upDATA]  0.00.02   - Testa se o indice eh valido"
IDIDX=$(rdANYTHING $PARM1)
[ $? -eq 0 ]                    && INDEX=$(rdINDEX $IDIDX)
[ -z "$INDEX" ]                 && echo "[upDATA]  1.01      - PARM1 nao indica um indice valido" && exit 4

# Toma dados de configuracao armazenados na tabela iAHx.tab
echo "[upDATA]  1.02      - Toma a configuracao para a transferencia"
[ $N_DEB -ne 0 ] && echo "[upDATA]  0.00.03   - Le nome da instancia"
INSTA=$(rdINSTANCIA $IDIDX);	# Nome da instancia
[ $N_DEB -ne 0 ] && echo "[upDATA]  0.00.04   - Le diretorio de execucao"
DIRET=$(rdDIRETORIO $IDIDX);	# Diretorio de execucao
[ $N_DEB -ne 0 ] && echo "[upDATA]  0.00.04   - Le diretorio dos dados"
DATAD=$(rdINDEXFILE $IDIDX);	# Caminho relativo dos dados
[ $N_DEB -ne 0 ] && echo "[upDATA]  0.00.05   - Le diretorio raiz dos indices"
R_IDX=$(rdINDEXROOT $IDIDX);	# Raiz dos indices
[ $N_DEB -ne 0 ] && echo "[upDATA]  0.00.06   - Le o nome do servidor de teste"
TESTE=$(rdTESTE $IDIDX);	# Servidor de tewte
[ $N_DEB -ne 0 ] && echo "[upDATA]  0.00.07   - Le o nome do servidor de homologacao"
HOMOL=$(rdHOMOLOG $IDIDX);	# Servidor de homologacao
[ $N_DEB -ne 0 ] && echo "[upDATA]  0.00.08   - Le o nome do servidor de producao"
PRODU=$(rdPRODUCAO $IDIDX);	# Servidor de producao

# Verifica se a transferencia nao eh 'simulada'
if [ "$NOXMT" -eq "1" -o "$FAKE" -eq "1" ]; then
	exit 0
fi

# Testa se tem servico a fazer mesmo
if [ "$FLG_HOMOL" -eq "1" -a "$HOMOL" = "." ]; then
	# Nao necessita transferir, homologacao eh no processamento
	exit 0
fi

if [ "$FLG_PRODU" -eq "1" -a "$PRODU" = "." ]; then
	# Nao necessita transferir, producao eh no processamento
	exit 0
fi

# Se tem informacao de port efetua o parse senao assume o default (22)
PORTA=${PORTsshn}
[ $FLG_PRODU -eq 1 ] && PORTA=${PORTsshp}

[ $N_DEB -ne 0 ] && echo "[upDATA]  0.00.09   - Porta ssh a ser usada nesta transferencia: $PORTA"

# Determina o destino do envio com base nas variaveis HOMOL e TESTE
[ $FLG_HOMOL -eq 0 -a $FLG_TESTE -eq 0 ] && DESTINO=$PRODU
[ $FLG_HOMOL -eq 1 -a $FLG_TESTE -eq 0 ] && DESTINO=$HOMOL
[ $FLG_HOMOL -eq 0 -a $FLG_TESTE -eq 1 ] && DESTINO=$TESTE

[ $N_DEB -ne 0 ] && echo "[upDATA]  0.00.11   - Servidor destino da transferencia: $DESTINO"

# Default
SUFX=3;		# Qtde de signos no sufixo. Opcao -a ou --suffix-length= do split
NAKO=20G;	# Tamanho maximo dos blocos a transferir. Opcao -b ou --bytes= do split
RETR=2;		# qtde de retentativas

#TO=ofi@bireme.org
TO=$ADMIN
unset CC
unset TEXTO
unset ANEXO

# Decorrentes
# Determina o FILLER para a mascara de nome de arquivo (que é a qtde de caracteres que o split agrega ao nome do arquivo)
FILL=$(expr substr '??????????' 1 $SUFX)
SUFF=data/index				# Sufixo do diretorio dos dados tirado do arquivo de configuracao (valor constante)

# Exibicao de variaveis para efeito de depuracao]
if [ "$DEBUG" -gt "1" ]; then
	echo "==============================="
	echo "$PRGDR/$TREXE $LCORI"
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
	echo "DEBUG level = $DEBUG"
	echo "      IDIDX = $IDIDX"
	echo "      INDEX = $INDEX"
	echo "   dir HOME = $DIRET"
	echo "   dir DATA = $DATAD"
	echo "      INSTA = $INSTA"
	[ ${#R_IDX} -gt 0 ] && echo "      R_IDX = $R_IDX"
	[ ${#TESTE} -gt 0 ] && echo "      HOMOL = $TESTE"
	[ ${#HOMOL} -gt 0 ] && echo "      HOMOL = $HOMOL"
	[ ${#PRODU} -gt 0 ] && echo "      PRODU = $PRODU"
	[ ${#CURRD} -gt 0 ] && echo "current dir = $CURRD"
	[ ${#NOXMT} -gt 0 ] && echo "      NOXMT = $NOXMT"
	echo
	echo "DESTINO = $DESTINO"
	echo "  DTISO = $DTISO"
	echo "  PORTA = $PORTA"
	echo "   SUFF = $SUFF"
	echo "   SUFX = $SUFX"
	echo "   NAKO = $NAKO"
	echo "   RETR = $RETR"
	echo "==============================="
	echo
fi

# -------------------------------------------------------------------------- #
# Verifica se o diretorio de execucao eh o correto


[ $N_DEB -ne 0 ]              && echo "[upDATA]  0.00.12   - Verifica se o diretorio corrente esta correto"
[[ ! "$CURRD" = *"$DIRET"* ]] && echo "[upDATA]  1.01      - Diretorio corrente nao eh apropriado" && exit 5

# Correcao de enderecamento especial para iahlinks
# "$DIRET" = "iahlinks/main" ] && DIRET="iahlinks"

# Elimina listas residuais de arquivos a transferir ou transferidos
[ -f antes.txt ]  && rm -f antes.txt
[ -f depois.txt ] && rm -f depois.txt

# Garante existencia do destino (alem de confirmar a conectividade)
# procedimento identico para qualquer servidor, desde que nao o de processamento
echo "[upDATA]  1.02      - Garante conectividade com o destino"
[ $N_DEB -ne 0 ] && echo ssh -p $PORTA ${TRANSFER}@${DESTINO} "[ -d $R_IDX/$DATAD/$SUFF.now ] || mkdir -p $R_IDX/$DATAD/$SUFF.now"
ssh -p $PORTA ${TRANSFER}@${DESTINO} "[ -d $R_IDX/$DATAD/$SUFF.now ] || mkdir -p $R_IDX/$DATAD/$SUFF.now"
if [ -z $(ssh -p $PORTA ${TRANSFER}@${DESTINO} "[ -d $R_IDX/$DATAD/$SUFF.now ] && echo 0") ]; then
	# Problemas no paraiso
	echo "[upDATA]  1.03      - ERROR: Sem conectividade neste momento"
	#ASSUNTO=":ERR: Transferencia TAMBORE - sem conectividade"
	#TEXTO="Problema detectado com conectividade para TAMBORE"
	#java -jar $PATH_EXEC/EnviadorDeEmail.jar -to  "$TO"  -cc  "$CC"  -subject  "$ASSUNTO"  -messagefile  "$TEXTO"
	exit 6
fi

# Garante que o grupo pode trabalhar os arquivos
chmod -R g+w $R_IDX/$DATAD/$SUFF/
# Se for para producao faz o processo completo, senao faz so rsync 'seco'
echo "[upDATA]  1.03      - Entra em procedimento de transferencia"
if [ "$FLG_TESTE" = "1" -o "$FLG_HOMOL" = "1" ]; then
	[ $N_DEB -ne 0 ] && echo "[upDATA]  0.00.13   - Destino nao eh o servidor de producao, transfere por rsync"
        # time rsync -aPvOz --delete $R_IDX/$DATAD/$SUFF ${TRANSFER}@${DESTINO}:$R_IDX/$DATAD/$(dirname $SUFF)/
          time rsync -aPvO  --delete $R_IDX/$DATAD/$SUFF ${TRANSFER}@${DESTINO}:$R_IDX/$DATAD/$(dirname $SUFF)/
	RSP=$?; [ "$NOERRO" = "1" ] && RSP=0
	if [ "$RSP" -ne "0" ]; then
		#### email de ERRO no envio para homologacao
		#ASSUNTO=":ERR: Transferencia HOMOLOGACAO - TX PCT"
		#TEXTO="Problema detectado ao transmitir indice para a homologacao"
		#java -jar $PATH_EXEC/EnviadorDeEmail.jar -to  "$TO"  -cc  "$CC"  -subject  "$ASSUNTO"  -messagefile  "$TEXTO"
	fi
	source checkerror $RSP "Problem sending data to homolog - ${INDEX}"
	# Ativa o indice na homologacao
	commit2homolog.sh $IDIDX
else
	# Conta se tem mais de 13 arquivos no diretorio (13 é conta de mentiroso, mas é um indice otimizado)
	if [ $(ls -1 $R_IDX/$DATAD/$SUFF | wc -l) -gt 13 ]; then
		[ $N_DEB -ne 0 ] && echo "[upDATA]  0.00.13   - Indice NAO otimizado, faremos um RSYNC"
		time rsync -aPvOz -e "ssh -p $PORTA" --delete $R_IDX/$DATAD/$SUFF/ ${TRANSFER}@${DESTINO}:$R_IDX/$DATAD/$SUFF.now/
		echo "----"
	else
		[ $N_DEB -ne 0 ] && echo "[upDATA]  0.00.13   - Indice OTIMIZADO, faremos aos pedacos"
		# Lista arquivos originais do diretorio fonte
		ls $R_IDX/$DATAD/$SUFF > antes.txt
		cd $R_IDX/$DATAD/$SUFF/
		# Limpa destino pois estamos transferindo full ou seja indice otimizado
		echo "[upDATA]  1.04      - Limpa destino para copia integral"
		ssh -p $PORTA ${TRANSFER}@${DESTINO} "rm -rf $R_IDX/$DATAD/$SUFF.now && mkdir -p $R_IDX/$DATAD/$SUFF.now"
		for FILE in $(ls)
		do
			echo Homogeniza tamanho de $FILE
			split -a $SUFX -b $NAKO $FILE $FILE
			PCT=$FILE$FILL
			for DAVZ in $PCT
			do
				SUCCESS=1
				RETRDAVZ=$RETR
				# Manda arquivo
				echo "Envio primario de $PARM1 parte $DAVZ"
				time rsync -aPvOz -e "ssh -p $PORTA" $R_IDX/$DATAD/$SUFF/$DAVZ ${TRANSFER}@${DESTINO}:$R_IDX/$DATAD/$SUFF.now
				# Testa o envio
				echo "Teste primario do envio (captura remota)"
				time ssh -p $PORTA ${TRANSFER}@${DESTINO} md5sum $R_IDX/$DATAD/$SUFF.now/$DAVZ | sed 's/\.now//g' > ${DAVZ}.md5
				echo "Teste primario do envio (conferencia local)"
				time md5sum -c ${DAVZ}.md5
				if [ "$?" -ne "0" ] ; then
					# Aqui vao as retentativas
					while [ "$RETRDAVZ" -gt "0" ]
					do
						echo "Teste $RETRDAVZ de $PARM1 parte $DAVZ"
						#### email de ATENCAO tive de fazer retry (Retry # = $RETR - RETRDAVZ + 1)
						#ASSUNTO=":WARNING: Transferencia TAMBORE - retry"
						#TEXTO="Necessario retransmitir $DAVZ no conjunto $PCT para $DESTINO"
						#java -jar $PATH_EXEC/EnviadorDeEmail.jar -to  "$TO"  -cc  "$CC"  -subject  "$ASSUNTO"  -messagefile  "$TEXTO"
						time rsync -aPvOz -e "ssh -p $PORTA" $R_IDX/$DATAD/data/index/$DAVZ ${TRANSFER}@${DESTINO}:$R_IDX/$DATAD/data/index.now
						echo "----"
						echo "Teste $RETRDAVZ do envio (conferencia remota)"
						time ssh -p $PORTA ${TRANSFER}@${DESTINO} md5sum $R_IDX/$DATAD/data/index.now/$DAVZ | sed 's/\.now//g' > ${DAVZ}.md5
						echo "----"
						echo "Teste $RETRDAVZ do envio (conferencia local)"
						time md5sum -c ${DAVZ}.md5
						[ "$?" -eq "0" ] && RETRDAVZ=0
						echo "----"
						RETRDAVZ=$(expr $RETRDAVZ - 1)
					done
				else
					RETRDAVZ=-1
				fi
				[ "$RETRDAVZ" -lt "0" ] && SUCCESS=0
				# Limpa area de trabalho (apaga transferido e verificador)
				rm -f ${DAVZ} ${DAVZ}.md5
				[ "$SUCCESS" -ne "0" ] && break
				[ $N_DEB -ne 0 ] && echo "Mais um pedaco Ok"
			done
			if [ "$SUCCESS" -eq "0" ]; then
				# Correu tudo bem com os parciais
				echo "Envio de $FILE realizado com sucesso"
			else
				# Detectou falha (DAVZ tem o nome do arquivo que não funcionou, $PCT a lista do conjunto de arquivos, e FILE o target-file)
				echo "Envio de $FILE mal sucedido ao enviar $DAVZ no conjunto $PCT"
				echo "ERROR: Transferencia falhou em $(date '+%Y%m%d %H:%M:%S')"
				#### email de ERRO no envio
				#ASSUNTO=":ERR: Transferencia TAMBORE - TX PCT"
				#TEXTO="Problema detectado ao transmitir $DAVZ no conjunto $PCT para $DESTINO"
				#java -jar $PATH_EXEC/EnviadorDeEmail.jar -to  "$TO"  -cc  "$CC"  -subject  "$ASSUNTO"  -messagefile  "$TEXTO"
				unset PCT
				[ $N_DEB -ne 0 ] && echo "1- lmpresid $R_IDX/$DATAD/$SUFF"
				lmpresid $R_IDX/$DATAD/$SUFF
				exit 7
			fi
			[ $N_DEB -ne 0 ] && echo "Mais um arquivo foi Ok"
			unset PCT
		done

		# Limpa se necessario (espera-se que nao haja residuos)
		[ $N_DEB -ne 0 ] && echo "2- lmpresid $R_IDX/$DATAD/$SUFF"
		lmpresid $R_IDX/$DATAD/$SUFF
		# ----
		# Sinaliza que o objeto de transferencia pode ser reconstruido no destino (melhorar a mensagem incluindo hora de inicio e fim)
		echo "Envia flag para o remoto"
		echo "$DATAD/$SUFF|$SUFX|Transferencia concluida em $(date '+%Y%m%d %H:%M:%S')" > $PARM1.flg
		time rsync -aPvOz -e "ssh -p $PORTA" $PARM1.flg ${TRANSFER}@${DESTINO}:$R_IDX
		echo "----"
		cat $PARM1.flg
		echo "Iniciando a reconstrucao dos arquivos..."
		[ -f "$PARM1.flg" ] && mv $PARM1.flg $PATH_PROC/$DIRET/logs/$DTISO.$PARM1.flg
		ssh -p $PORTA ${TRANSFER}@${DESTINO} "$PATH_IAHX/toca.sh $PARM1.flg"
		[ "$?" -eq "0" ] && ssh -p $PORTA ${TRANSFER}@${DESTINO} "rm -f $R_IDX/$PARM1.flg"
		cd -

	fi
	# Promove a verificacao MD5 dos dados presentes no diretorio intermediario do destino
	echo "Iniciando a geracao de MD5 dos dados remotos, esta operacao eh demorada. Aguarde..."
	time ssh -p $PORTA ${TRANSFER}@${DESTINO} md5sum $R_IDX/$DATAD/$SUFF.now/* | sed 's/\.now//g' > $PARM1.md5
	[ "$?" -ne "0" ] && echo "Algum problema ocorreu na geracao remota do MD5 de verificacao global." && exit 8
	echo "----"
	echo "Iniciando a comparacao de MD5 com dados locais, esta operacao eh demorada. Aguarde..."
	time md5sum -c $PARM1.md5
	if [ "$?" -ne "0" ]; then
		# Ocorreu problema na confrontacao :-(
		#### email de ERRO no bloco global
		#ASSUNTO=":ERR: Transferencia TAMBORE - md5 X md5"
		#TEXTO="Problema detectado ao confrontar MD5 ($DESTINO) contra MD5 ($HOSTNAME)"
		#java -jar $PATH_EXEC/EnviadorDeEmail.jar -to  "$TO"  -cc  "$CC"  -subject  "$ASSUNTO"  -messagefile  "$TEXTO"
		exit 9
	fi
	echo "----"
	
	# Hora de colocar as coisas nos lugares certos
	
	# Cria destino
	[ $N_DEB -ne 0 ] && echo "Cria diretorio temporario no destino (.niu)"
	ssh -p $PORTA ${TRANSFER}@${DESTINO} "[ -d $R_IDX/$DATAD/$SUFF.niu ] &&   rm -rf $R_IDX/$DATAD/$SUFF.niu"
	#ssh -p $PORTA ${TRANSFER}@${DESTINO} "[ -d $R_IDX/$DATAD/$SUFF.niu ] || mkdir -p $R_IDX/$DATAD/$SUFF.niu"
	## Avalia se criou ok o diretorio temporario
	#if [ "$?" -ne "0"]; then
	#	### email de ERRO de criacao
	#	ASSUNTO=":ERR: Transferencia TAMBORE - criate"
	#	  TEXTO="Problema detectado ao criar diretorio .niu em $DESTINO"
	#	java -jar $PATH_EXEC/EnviadorDeEmail.jar -to  "$TO"  -cc  "$CC"  -subject  "$ASSUNTO"  -messagefile  "$TEXTO"
	#	exit 10
	#fi
	
	# Completa destino
	[ $N_DEB -ne 0 ] && echo "Copia conteudo de .now para o temporario"
	#scp -p -P $PORTA ${TRANSFER}@${DESTINO}:$R_IDX/$DATAD/$SUFF.now/* ${TRANSFER}@${DESTINO}:$R_IDX/$DATAD/$SUFF.niu
	time scp -rp -P $PORTA ${TRANSFER}@${DESTINO}:$R_IDX/$DATAD/$SUFF.now   ${TRANSFER}@${DESTINO}:$R_IDX/$DATAD/$SUFF.niu
	if [ "$?" -ne "0" ]; then
		### email de ERRO de copia
		#ASSUNTO=":ERR: Transferencia TAMBORE - copy"
		#  TEXTO="Problema detectado ao copiar dados do diretorio .now para .niu em $DESTINO"
		#java -jar $PATH_EXEC/EnviadorDeEmail.jar -to  "$TO"  -subject  "$ASSUNTO"  -messagefile  "$TEXTO"
	       exit 11
	fi
	echo "----"
	
	# Finaliza destino
	echo "Finaliza destino (rename)"
	ssh -p $PORTA ${TRANSFER}@${DESTINO} "[ -d $R_IDX/$DATAD/$SUFF.new ] && rm -rf $R_IDX/$DATAD/$SUFF.new"
	ssh -p $PORTA ${TRANSFER}@${DESTINO} mv $R_IDX/$DATAD/$SUFF.niu $R_IDX/$DATAD/$SUFF.new
	if [ "$?" -ne "0" ]; then
		ssh -p $PORTA ${TRANSFER}@${DESTINO} "[ -d $R_IDX/$DATAD/$SUFF.niu ] &&   rm -rf $R_IDX/$DATAD/$SUFF.niu"
		### EMAIL de ERRO de rename
		#ASSUNTO=":ERR: Transferencia TAMBORE - rename"
		#  TEXTO="Problema detectado ao renomoear diretorio .niu para .new em $DESTINO"
		#java -jar $PATH_EXEC/EnviadorDeEmail.jar -to  "$TO"  -cc  "$CC"  -subject  "$ASSUNTO"  -messagefile  "$TEXTO"
		exit 12
	fi
	
	# Sinaliza termino de operacao (com sucesso)
	echo "Cria e envia flag para o remoto"
	echo "$DATAD/$SUFF|$SUFX|Virada liberada em $(date '+%Y%m%d %H:%M:%S')" > vira.$PARM1.flg
	time rsync -aPvOz -e "ssh -p $PORTA" vira.$PARM1.flg ${TRANSFER}@${DESTINO}:$R_IDX
	[ "$?" -ne "0" ] && exit
	echo "----"
	cat vira.$PARM1.flg
	[ -f "vira.$PARM1.flg" ] && mv vira.$PARM1.flg logs/$DTISO.vira.$PARM1.flg

fi

# Termo da tarefa
echo "Tarefa de transferencia concluida"

# -------------------------------------------------------------------------- #
source	$PATH_EXEC/inc/clean_wrk.envdata.inc
source	$PATH_EXEC/inc/infofim.inc
# -------------------------------------------------------------------------- #
cat > /dev/null <<COMMENT
     Entrada :	PARM1 com o identificador do indice a transferir
               Opcoes de execucao
                 -h, --help            Mostra o help
                 -V, --versao          Mostra a versao
                 -d, --debug NIVEL     Define o nivel de depuracao
                 --changelog           Mostra historico de alteracoes
                 -x, -X                Nao envia para o destino
		  -t, --test		Envia para servidor de teste APLIC
		  -H, --homolog		Envia para a homologacao     DADOS
       Saida : Indice transferido para servidor destino (producao)
               Codigos de retorno:
                       0 - Ok operation
                       1 - Non specific error
                       2 - Syntax Error
                       3 - Configuration Error (iAHx.tab not found)
                       4 - Contiguration Failure (INDEX_ID unrecognized)
                       5 - Wrong working directory ou Data directory empty
                       6 - No connectivity
			7 - Failed to send data (transmission)
			8 - Failed to send data (remote MD5)
			9 - Failed to send data (comparison)
			10- Failed to send data (directory creation)
			11- Failed to send data (remote copy)
			12- Failed to send data (remote rename)
			128-Concurrent execution
    Corrente : /bases/iahx/proc/[INSTANCIA]/main/
     Chamada : enviaDados.sh [-h|-V|--changelog] [-H|-t] [-x] [-d N] <ID_INDEX>
     Exemplo : /bases/iahx/proc/bin/enviaDados.sh -x cancer -d 6 &> logs/out-$(date '+%Y%m%d%H%M%S').txt &
 Objetivo(s) : 1- Transferir indice atualizado para servidor destino (producao)
 Comentarios : 
 Observacoes : DEBUG eh uma variavel mapeada por bit conforme
			_BIT0_	Aguarda tecla <ENTER>
			_BIT1_	Mostra mensagens de DEBUG
			_BIT2_	Modo verboso
			_BIT3_	Modo debug de linhas -v
			_BIT4_	Modo debug de linhas -x
			_BIT7_	Operacao em modo FAKE
       Notas : Quando o nome do servidor de homologacao for omitido
               (valendo ".") a transferencia e o commit nao devem
               ser efetuados
 Dependencia : tabs/iAHx2.tab contendo a tabela de indices, conforme o layout
               ID do indice               (Identificador unico do indice)
               nome de do indice          (nome oficial do indice)
               nome da instancia          (usado nas transferencias)
               diretorio de processamento (caminho relativo)
               diretorio comum de indices (caminho absoluto)
		nome do teste		   (nome de rede para acesso)
               nome da homologacao        (nome de rede para acesso)
               nome da producao           (nome de rede para acesso)
COMMENT
exit
cat > /dev/null <<SPICEDHAM
CHANGELOG
20140707 Enderecamento de INBOX via tabela iAHx.tab
20140708 Versao ativada para operacao, substituindo updateData.sh com as restricoes inerentes ao envio para homologacao que noa eh suportada aqui
20140804 Adaptacao para variaveis utilizadas no pacote de processamento exportavel
20140819 Correcao de bugs menores
20140820 Reparado o mecanismo de limpeza de area de trabalho e da area do indice
20140923 Ajuste para uso no pacote de distribuicao
SPICEDHAM

