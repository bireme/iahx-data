#!/bin/bash

# ------------------------------------------------------------------------- #
# cron_weekly3.sh - Escalador de execucao de processamento de iAHx
# ------------------------------------------------------------------------- #
#    Corrente :	Nenhum especifico
#     Chamada :	$PATH_EXEC/cron_weekly3.sh [-h|-V|--changelog] [-d N] [-e] [-i|-f] [-x] <ID_INDEX>
#     Exemplo :	$PATH_EXEC/cron_weekly3.sh -e bioetica
#		$PATH_EXEC/cron_weekly3.sh regional
# Objetivo(s) :	Atualizar o indice informado de IAHx
#  IMPORTANTE : Deve ser executado com o user 'tomcat'

# ------------------------------------------------------------------------- #
#  Centro Latino-Americano e do Caribe de Informação em Ciências da Saúde
#     é um centro especialidado da Organização Pan-Americana da Saúde,
#           escritório regional da Organização Mundial da Saúde
#                       BIREME / OPS / OMS (P)2012-14
# ------------------------------------------------------------------------- #
# Historico
# versao data, Responsavel
#       - Descricao
cat > /dev/null <<HISTORICO
vrs:  1.00 20120803, FJLopes, VAAntonio
        - Edicao original
vrs:  2.00 20121109, FJLopes
	- Aceita identificador de indice e diretorio de operacao
vrs:  2.01 20121126, FJLopes
	- Depuracao de erros menores
vrs:  2.02 20130521, FJLopes
	- Garantia de parametro para chamada geral normalizado
vrs:  2.03 20140805, FJLope
	- Preparo para formacao de pacote de distribuicao
vrs:  3.00 20140828, FJLopes
	- Mecanismo antireentrancia
HISTORICO

# Carrega o ambiente operacional esperado (eh chamada por CRON, devemos simular o login)
source /usr/local/bireme/misc/ambiente

# Incorpora biblioteca especifica de iAHx
source	$PATH_EXEC/inc/iAHx2.inc
# Conta com as funcoes:
#	rdANYTHING      PARM1	1	Retorna o ID do indice, por qualquer item
#	rdINDEX         PARM1	2	Retorna o nome do indice
#	rdINSTANCIA     PARM1	3	Retorna o nome da instancia
#	rdDIRETORIO     PARM1	4	Retorna o diretorio de processamento
#	rdINDEXFILE     PARM1	5	Retorna o caminho relativo do indice
#	rdINDEXROOT     PARM1	6	Retorna o caminho da raiz dos indices
#	rdTESTE         PARM1	7	Retorna o nome do servidor de teste
#	rdHOMOLOG       PARM1	9	Retorna o nome do servidor de homologacao de dados
#	rdPRODUCAO      PARM1	10	Retorna o nome do servidor de producao
#	rdINBOX         PARM1	12	Retorna o diretorio de dados no INBOX
#	rdLILDBIWEB     PARM1	13	Retorna o caminho para bases externas em LilDBI-Web
#	rdSERVER        PARM1	11	Obtem o numero do iahx-server para o indice
#	rdPORT          PARM1		Obtem o numero do iahx-server para o indice (real)
#	rdSTATUS        PARM1	14	Status da instancia (Ativo / Desativo /?)
#	rdPROCESSA      PARM1	15	Obtem situacao do processamento
#	rdTYPE          PARM1	26	Retorna o tipo de processamento (MANUAL / PROGRAMADO)
#	rdPERIOD        PARM1	27	Periodicidade de processamento
#	rdALL           PARM1	1/3	Retorna pares ID Instancia
#	rdTODAS         PARM1	3	Retorna com a lista de instancias no arquivo de PARM1
#	rdPORTAL        PARM1	28	Nome do portal
#	rdURLOK         PARM1	29	URL publicamente disponivel (P / H / PH / -)
#	rdURL           PARM1	30	URL (parte fixa)
#	rdHOMAPPL       PARM1	8	Retorna o nome do servidor de homologacao de aplicacao
#	rdVERSION       PARM1	33	Versão do iAHx
#	rdLANG          PARM1	32	Obtem lista de idiomas da interface
#	rdOBSERVATION   PARM1	34	Observacoes sobre a Instancia
#	rdTIMEHOMOL     PARM1		Ultima atualizacao em homologacao
#	rdTIMEPROD      PARM1		Ultima atualizacao em producao

# Incorpora a biblioteca de armadilha de sinais
source $PATH_EXEC/inc/armadilhar.inc
# Conta com as funcoes:
#	clean_term	PARM1		Trata interrupcao por SIGTERM
#	clean_hup	PARM1		Trata interrupcao por SIGHUP
#	clean_int	PARM1		Trata interrupcao por SIGINT
#	clean_kill	PARM1		Trata interrupcao por SIGKILL
#	clean_up	PARM1		Trata interrupcao por outros sinais
#	clean_exit	PARM1		Trata interrupcao por SIGEXIT
#	leF		PARM1		Le nivel corrente do flag
#	contaF		PARM1		Sobe um nivel de execucao
#	descontaF	PARM1		Desce um nivel de execucao
#	resetF		PARM1		Limpa nivel de execucao

# Incorpora biblioteca de controle basico de processamento
source	$PATH_EXEC/inc/infoini.inc
# Conta com as funcoes:
#	isNumber	PARM1	Retorna FALSE se PARM1 nao for numerico

# Garante condicoes minimas de processamento
[ -d "$HOME/logs" ] || mkdir -p $HOME/logs
[ -d "logs" ]       || mkdir -p logs

# Set default values:
N_DEB=0;		# DEBUG level
DEBUG="0";		# Marcador de DEBUG
NOXMT=0;		# Send data flag
OPC_XMT="";		# Send data option
NOERRO=0;		# Stop on error flag
OPC_ERRO="";		# Stop on error option
NOINCR=0;		# Incremental processing flag
OPC_FULL="";		# Incremental processing option
NODATA=0;		# Ignore data flag
OPC_DATA="";		# Ignore data option

# -------------------------------------------------------------------------- #
# Mensagem de ajuda e tratamento de opcoes do processamento

#        1         2         3         4         5         6         7         8
#2345678901234567890123456789012345678901234567890123456789012345678901234567890
AJUDA_USO="
Syntax: $TREXE [-h|-V|--changelog] [-e] [-i] <PARM1>

OPIONS:
 --changelog        Exibe o historico de alteracoes e para a execucao
 -d, --debug NIVEL  Define DEBUG level (positive numeric value [0..255])
 -e, --no-error     Ignore errors
 -f, -F, --full     Execute full process
 -h, --help         Show this help text and stop execution
 -i, --no-input     Ignore data-in
 -V, --version      Show currente version
 -x, --no-xmt       Send file ignore

PARAMETERS:
 PARM1  Unic identifier of index to be processed
"

# -------------------------------------------------------------------------- #
# Tratamento das opcoes de linha de comando (qdo houver alguma)
while test -n "$1"
do
        case "$1" in

		-e | --no-error)
			NOERRO=1
			OPC_ERRO="-e"
			;;

		-f | -F | --full | --FULL)
			NOINCR=1
			OPC_FULL="-f"
			;;

		-i | --no-input)
			NODATA=1
			OPC_DATA="-i"
			;;

                -x | --no-xmt)
                        NOXMT=1
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
                        [ $? -ne 0 ] && echo -e "\n$TREXE: The argument of the DEBUG option must exist and be numeric.\n$AJUDA_USO" && exit 2
                        DEBUG=$1
			N_DEB=$(expr $(($DEBUG & 6)) / 2)
                        ;;

                --changelog)
                        TOTLN=$(wc -l $0 | awk '{ print $1 }')
                        INILN=$(grep -n "<SPICEDHAM" $0 | tail -1 | cut -d ":" -f "1")
                        LINHAI=$(expr $TOTLN - $INILN)
                        LINHAF=$(expr $LINHAI - 2)
                        echo -e -n "\n$TREXE "
                        grep '^vrs: ' $PRGDR/$TREXE | tail -1
                        echo -n "==> "
                        tail -$LINHAI $0 | head -$LINHAF
                        echo
                        exit
                        ;;

                *)
                        if [ $(expr index $1 "-") -ne 1 ]; then
                                if test -z "$PARM1"; then PARM1=$1; shift; continue; fi
                                if test -z "$PARM2"; then PARM2=$1; shift; continue; fi
                                if test -z "$PARM3"; then PARM3=$1; shift; continue; fi
                        else
                                echo "Not valid option! ($1)"
                        fi
                        ;;
        esac
        # Argumento tratado, desloca os parametros e trata o proximo
        shift
done
# Para DEBUG assume valor DEFAULT antecipadamente
isNumber $DEBUG
[ $? -ne 0 ]         && DEBUG="0"
[ "$DEBUG" -ne "0" ] && PARMD="-d $DEBUG"
# -------------------------------------------------------------------------- #
# Avalia nivel de depuracao
[ $(($DEBUG & $_BIT3_)) -ne 0 ] && set -v
[ $(($DEBUG & $_BIT4_)) -ne 0 ] && set -x

# -------------------------------------------------------------------------- #
echo                                  >> logs/cron-weekly.log
echo "-*- ${_ANO_}-${_MES_}-${_DIA_}" >> logs/cron-weekly.log
echo "[CRON-INI]"                     >> logs/cron-weekly.log

# Garante existencia da tabela de configuracao (sai com codigo de erro 3 - Configuration Error)
[ ! -s "$PATH_EXEC/tabs/iAHx.tab" ] && echo -e "${DTISO} - Table iAHx.tab is missing $0 $LCORI\n[CRON-FIM]" >> logs/cron-weekly.log && exit 3

# Garante existencia de parametro obrigatorio (sai com erro codigo 2 - Syntax Error)
[ -z $PARM1 ] && echo -e "${DTISO} - PARM1 is missing $0 $*\n[CRON-FIM]" >> logs/cron-weekly.log && exit 2

IDIDX=$(rdANYTHING $PARM1)
[ $N_DEB -ne 0 ] && echo "${DTISO} -    PARM1: $IDIDX" >> logs/cron-weekly.log

# Garante existencia do indice indicado na tabela de configuracao (sai com codigo de erro 4 - Configuration Failure)
# alem de tomar nome oficial do indice para o SOLR
INDEX=$(rdINDEX $IDIDX)
[ $N_DEB -ne 0 ] && echo "${DTISO} -    INDEX: $INDEX" >> logs/cron-weekly.log
[ -z "$INDEX" ]            && echo -e "${DTISO} - PARM1 ($PARM1) is not a valid index $0 $LCORI\n[CRON-FIM]" >> logs/cron-weekly.log && exit 4
[ "$INDEX" = "NM_INDICE" ] && echo -e "${DTISO} - PARM1 ($PARM1) is not a valid index $0 $LCORI\n[CRON-FIM]" >> logs/cron-weekly.log && exit 4

# Determina se deve forcar processamento FULL
PERIO=$(rdPERIOD $IDIDX)
case "$PERIO" in

	6 | mensal)
		# Periodicidade mensal - no automatico deve ser sempre full
		OPC_FULL="-f"
		NOINCR=1
		;;

	5 | quinzenal)
		# Periodicidadfe quinzenal - no automatico primeira quinzena deve ser full
		[ $_DIA_ -lt 16 ] && OPC_FULL="-f" && NOINCR=1
		;;

	4 | semanal)
		# Periodicidade semanal - no automatico a primeira semana do mes deve ser full
		[ $_DIA_ -lt 8 ] && OPC_FULL="-f" && NOINCR=1
		;;

	3)
		# Duas vezes por semana - no automatico uma vez na semana deve ser full
		if [ $_DIA_ -lt 8 ]; then
			[ $_DOW_ -lt 4 ] && OPC_FULL="-f" && NOINCR=1
		fi
		;;

	2)	# Dias alternados - no automatico dia 1 a 7 qdo for segunda-feira ou terca-feira deve ser full
		if [ $_DIA_ -lt 8 ]; then
			[ $_DOW_ -lt 3 ] && OPC_FULL="-f" && NOINCR=1
		fi
		;;

	1 | diario)
		# Diario - no automatico dia 1 a 7 qdo for segunda-feira deve ser full
		if [ $_DIA_ -lt 8 ]; then
			[ $_DOW_ -lt 2 ] && OPC_FULL="-f" && NOINCR=1
		fi
		;;

	*)
		;;

esac

# Destinos de e-mail
TO=$IAHx_ADMIN
#CC=vinicius.andrade@bireme.org <== nao mais recebe avisos

# Destinatarios especificos
[ "$PARM1" = "xxx" ] && TO="john.doe@domainname.ttt.zz"

# Toma o nome da instancia para transferencia de dados
INSTA=$(rdINSTANCIA $IDIDX)

# Toma o caminho relativo do diretorio de trabalho
[ $N_DEB -ne 0 ] && echo "${DTISO} - CURR DIR: $(pwd)" >> logs/cron-weekly.log
DIRET=$(rdDIRETORIO $IDIDX)
[ $N_DEB -ne 0 ] && echo "${DTISO} - WORK DIR: $DIRET" >> logs/cron-weekly.log
[ ! -d "$PATH_PROC/$DIRET" ] && echo -e "${DTISO} - Directory not found (or cannot be reached) \"$0 $LCORI\"\n[CRON-FIM]" >> logs/cron-weekly.log && exit 5

# -------------------------------------------------------------------------- #
# Controle de antireentrancia
F_FLAG="$PATH_PROC/$DIRET/$INSTA.flg"
leF $F_FLAG;		# Carrega valor atual da profundidade de execucao

[ $N_DEB -gt 0 ] && echo "[CRONW]  0.00.00.00 -Flags file: $F_FLAG content: $FLAG"

# Verifica se o valor autoriza a execucao
if [ $FLAG -gt 0 ]; then
        echo
        echo "[CRON-ERR]  0.00.00.00 -Unauthorized execution. Is already running."
        echo
	# Envia e-mail sinalizando que não rodou
        exit 128
fi

# Conta mais uma execucao
contaF $F_FLAG
[ $N_DEB -gt 0 ] && echo "[CRONW]  0.00.00.00 -Flag file: $F_FLAG content: $FLAG"

# Liga armadilha de interrupcao de execucao
trap "clean_up   $F_FLAG" 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33
trap "clean_exit $F_FLAG" 0
trap "clean_hup  $F_FLAG" SIGHUP
trap "clean_int  $F_FLAG" SIGINT
trap "clean_kill $F_FLAG" SIGKILL
trap "clean_term $F_FLAG" SIGTERM

# Diretorio de processamento
# ----- #
# DEBUG #
[ $(($DEBUG & $_BIT0_)) -eq 1 ] && read LIDO
[ "$LIDO" = "pare" ] && echo "==> execucao interrompida manualmente pelo operador" && exit
[ "$LIDO" = "stop" ] && echo "==> execution stopped manually by the operator." && exit
# ----- #
# -------------------------------------------------------------------------- #

cd $PATH_PROC/$DIRET
[ -d "logs" ] || mkdir -p logs

[ $N_DEB -gt 0 ] && echo "Here's a dump because N_DEB is not 0 ($N_DEB)"
# Informacao para depuracao
if [ $N_DEB -ne 0 ]; then
	# ------------------------------------------------------------------------- #
	# Painel de depuracao
	# ------------------------------------------------------------------------- #
	#     12345678901234567890123456789012345678901234567890123456789012345678901234567890
	echo "=============================================================================" >> logs/cron-weekly.log
	echo "         TO : $TO"                                                             >> logs/cron-weekly.log
	echo "         CC : $CC"                                                             >> logs/cron-weekly.log
	echo "       DATA : $DTISO"                                                          >> logs/cron-weekly.log
	echo "   TRANSFER : $TRANSFER"                                                       >> logs/cron-weekly.log
	echo "   HOSTNAME : $HOSTNAME"                                                       >> logs/cron-weekly.log
	echo "  PATH_EXEC : $PATH_EXEC"                                                      >> logs/cron-weekly.log
	echo "  PATH_PROC : $PATH_PROC"                                                      >> logs/cron-weekly.log
	echo "  PATH_IAHX : $PATH_IAHX"                                                      >> logs/cron-weekly.log
	echo " PATH_INPUT : $PATH_INPUT"                                                     >> logs/cron-weekly.log
	echo " INDEX_ROOT : $INDEX_ROOT"                                                     >> logs/cron-weekly.log
	echo "  JAVA_HOME : $JAVA_HOME"                                                      >> logs/cron-weekly.log
	echo "       CRON : $CRON"                                                           >> logs/cron-weekly.log
	echo "    current : $(pwd)"                                                          >> logs/cron-weekly.log
	echo "       PATH : $PATH"                                                           >> logs/cron-weekly.log
	echo "=============================================================================" >> logs/cron-weekly.log
	echo "  Id Indice : $IDIDX"                                                          >> logs/cron-weekly.log
	echo "     Indice : $INDEX"                                                          >> logs/cron-weekly.log
	echo "  Instancia : $INSTA"                                                          >> logs/cron-weekly.log
	echo "  Diretorio : $DIRET"                                                          >> logs/cron-weekly.log
        echo "DEBUG level : $DEBUG"                                                          >> logs/cron-weekly.log
	echo "      PARMD : $PARMD"                                                          >> logs/cron-weekly.log
        echo "      NOXMT : $NOXMT"                                                          >> logs/cron-weekly.log
        echo "    OPC_XMT : $OPC_XMT"                                                        >> logs/cron-weekly.log
        echo "     NOERRO : $NOERRO"                                                         >> logs/cron-weekly.log
        echo "   OPC_ERRO : $OPC_ERRO"                                                       >> logs/cron-weekly.log
        echo "     NOINCR : $NOINCR"                                                         >> logs/cron-weekly.log
        echo "   OPC_FULL : $OPC_FULL"                                                       >> logs/cron-weekly.log
	echo "    OPC_XMT : $OPC_XMT"                                                        >> logs/cron-weekly.log
	echo "   OPC_FULL : $OPC_FULL"                                                       >> logs/cron-weekly.log
	echo "   OPC_ERRO : $OPC_ERRO"                                                       >> logs/cron-weekly.log
	echo "      NOXMT : $NOXMT"                                                          >> logs/cron-weekly.log
	echo "     NOINCR : $NOINCR"                                                         >> logs/cron-weekly.log
	echo "     NOERRO : $NOERRO"                                                         >> logs/cron-weekly.log
	echo "=============================================================================" >> logs/cron-weekly.log
	echo "Present shells"                                                                >> logs/cron-weekly.log
	ls -l *.sh                                                                           >> logs/cron-weekly.log
	echo "=============================================================================" >> logs/cron-weekly.log
fi

# ------------------------------------------------------------------------- #
# Entrada de processamento
#(update-index.sh comum a todos)
echo       "$DTISO # $PATH_EXEC/update-index.sh $PARMD $OPC_FULL $OPC_XMT $IDIDX" >> logs/cron-weekly.log
echo "-*- ${_ANO_}-${_MES_}-${_DIA_}"                                             >> logs/cron-weekly.log
echo "[CRON-INI] ==> Process of $INSTA in $(date '+%Y%m%d %H:%M:%S')"             >> logs/cron-weekly.log
##echo
##cat logs/cron-weekly.log
echo $PATH_EXEC/update-index.sh $PARMD $OPC_ERRO $OPC_FULL $OPC_XMT $IDIDX
     $PATH_EXEC/update-index.sh $PARMD $OPC_ERRO $OPC_FULL $OPC_XMT $IDIDX  &> logs/out-update.$DTISO.txt

if [ "$?" -eq "0" ]; then
	ASSUNTO="Atualized in $HOSTNAME: $INSTA"
	  TEXTO="$PATH_EXEC/messages/$INSTA.txt"
	  ANEXO="logs/cron-weekly.txt"
else
	ASSUNTO="ERROR: bvs-$INSTA"
	  TEXTO="$PATH_EXEC/messages/iAHx-error.txt"
	  ANEXO="logs/out-update.$DTISO.txt"
fi
[ $(($DEBUG & $_BIT2_)) -ne 0 ] && echo "ASSUNTO=$ASSUNTO" >> logs/cron-weekly.log
[ $(($DEBUG & $_BIT2_)) -ne 0 ] && echo "  TEXTO=$TEXTO"   >> logs/cron-weekly.log
[ $(($DEBUG & $_BIT2_)) -ne 0 ] && echo "  ANEXO=$ANEXO"   >> logs/cron-weekly.log

# Sinaliza final de processamento e seu efeito
echo "java -jar $PATH_EXEC/EnviadorDeEmail.jar -to \"$TO\" -cc \"$CC\" -subject \"$ASSUNTO\" -messagefile \"$TEXTO\" -attach \"$ANEXO\"" >> logs/cron-weekly.log

echo "[CRON-FIM] ==> Process of $INSTA in $(date '+%Y%m%d %H:%M:%S')" >> logs/cron-weekly.log

# Recorta o LOG para o processamento do dia corrente
TOTAL=$(wc -l logs/cron-weekly.log | awk {' print $1 '})
LINHA=$(grep -n "${_ANO_}-${_MES_}-${_DIA_}" logs/cron-weekly.log | tail -1 | cut -d ":" -f "1")
QTDLN=$(expr $TOTAL - $LINHA + 1)
tail -n $QTDLN logs/cron-weekly.log > logs/cron-weekly.txt

## efetiva envio do e-mail
#java -jar $PATH_EXEC/EnviadorDeEmail.jar -to "$TO" -cc "$CC" -subject "$ASSUNTO" -messagefile "$TEXTO" -attach "$ANEXO" >> logs/cron-weekly.log
#java -jar $PATH_EXEC/EnviadorDeEmail.jar -to "$TO"           -subject "$ASSUNTO" -messagefile "$TEXTO" -attach "$ANEXO" >> logs/cron-weekly.log

## -------------------------------------------------------------------------- #
## Repoe nivel do flag de antireentrancia
#descontaF $F_FLAG
#[ $N_DEB -gt 0 ] && echo "[CRONW]  0.00.00.00 -Arquivo de flag: $F_FLAG contendo: $FLAG (valor esperado neste momento ZERO)"
## -------------------------------------------------------------------------- #

# Limpa area de trabalho
[ -f "logs/cron-weekly.txt" ] && rm -f logs/cron-weekly.txt
source	$PATH_EXEC/inc/infofim.inc
# -------------------------------------------------------------------------- #
# Especificos da aplicacao
unset	IDIDX   INDEX   INSTA   DIRET
# -------------------------------------------------------------------------- #
cat > /dev/null <<COMMENT
     Entrada:   PARM1 identificacao do indice processar
                Opcoes de execucao
                 --changelog            Mostra historico de alteracoes
                 -d N, --debug N        Nivel de depuracao
                 -e, --no-error         Ignora detecao de erros
                 -f, -F, --FULL         rocessamento nao incremental
                 -h, --help             Mostra o help
                 -i, --no-input         Ignora dados na caixa de entrada
                 -V, --versao           Mostra a versao
		 -x, --no-xmt		Nao envia resultados
       Saida:   Arq. log com parametrizacao de execucao em log da instancia
    Corrente:	Sem diretorio definido deve ser chamado com FULLPATH (ou seja $PATH_EXEC)
     Chamada:   /bases/iahx/exec/cron_weekly3.sh [-h|-V|--changelog] [-d N] [-e] [-f|-i] [-x] <ID_INDEX>
     Exemplo:   /bases/iahx/exec/cron_weekly3.sh -e bioetica
		/bases/iahx/exec/cron_weekly3.sh regional
 Objetivo(s):   Atualizar o indice informado de IAHx
 Comentarios:   Avalia se esta na primeira semana no mes e comanda uma atualizacao FULL, senao pode ser
		incremental e evita chamada simultanea de processamentos (por crontab)
 Observacoes:   DEBUG eh uma variavel mapeada por bit
                _BIT0_  Aguarda tecla <ENTER>
                _BIT1_  Mostra mensagens de debug
                _BIT2_  Modo verboso
                _BIT3_  Modo debug de linha -v
                _BIT4_  Modo debug de linha -x
                _BIT7_  Execucao FAKE
		Na variavel PARMD se mantem a opcao de DEBUG a ser utilizada nas chamadas subsequentes
       Notas:   Deve ser executado com o usuario 'tomcat'
Dependencias:   Tabela iAHx.tab deve estar presente em $PATH_EXEC/tabs
		COLUNA	NOME			COMENTARIOS
		 1	ID_INDICE		ID do indice			(Identificador unico do indice para processamento)
		 2	NM_INDICE		nome do indice conforme o SOLR	(nome oficial do indice)
		 3	NM_INSTANCIA		nome interno da instancia
		 4	DIR_PROCESSAMENTO	diretorio de processamento	(caminho relativo a $PATH_PROC)
		 5	DIR_INDICE		caminho do indice		(caminho ralativo)
		 6	RAIZ_INDICES		caminho comum dos indices	(caminho absoluto)
		 7	SRV_TESTE		HOSTNAME do servidor de teste de palicacao
		 8	SRV_HOMOLOG APP		HOSTNAME do servidor de homologacao de aplicacao
		 9	SRV_HOMOLOG DATA	HOSTNAME do servidor de homologacao de dados
		10	SRV_PRODUCAO		HOSTNAME do servidor de producao
		11	IAHX_SERVER		numero do IAHx-server utilizado (Teste/Homolog/Prod)
		12	DIR_INBOX		nome do diretorio dos dados de entrada
		13	NM_LILDBI		qualificacao total das bases de dados LILDBI-Web, separadas pelo sinal '^'
		14	SITUACAO		estado do indice		(HOMOLOGACAO / ATIVO / INATIVO / ...)
		15	PROCESSA		liberado para processar		(em operacao)
		16-25	RESERVA_DE_OFI						(USO DE OPERACAO DE FONTE DE INFORMACAO)
		26	TIPOPROC		escalacao do processamento	(manual / automatica)
		27	PERIODICIDADE		intervalo entre processamento	(0/pedido 1/diario 2/alternado 3/bisemanal 4/semanal 5/quinzenal 6/mensal)
		28	NM_PORTAL		nome oficial do portal
		29	URL_DISPONIVEL		URL de aplicacao funcional	(P / H / PH / -)
		30	URL			Universal Resource Locator
		31	PARAMETRO_URL		complemento de URL para acesso web
		32	IDIOMAS			versoes idiomaticas de interface
		33	VERSAO_APP		versao do OPAC
		34	OBSERVACAO		informações relevantes diversas
		35	WIKI_EXPRESSAO		URL do wiki com a expressao de selecao de registros
		36	LST_FISIDX		lista de FIs indexadas neste indice
			-Periodicidades:
				0 - a pedido
				1 - diario
				2 - dias alternados
				3 - 2 vezes na semana
				4 - semanal
				5 - quinzenal
				6 - mensal
			-URL funcionais
				P - Producao
				H - Homologacao
				- - none
		Variaveis de ambiente que devem estar previamente ajustadas:
                geral         TRANSFER - Usuario para troca de arquivos entre servidores
                geral           _BIT0_ - 00000001b
                geral           _BIT1_ - 00000010b
                geral           _BIT2_ - 00000100b
                geral           _BIT3_ - 00001000b
                geral           _BIT4_ - 00010000b
                geral           _BIT5_ - 00100000b
                geral           _BIT6_ - 01000000b
                geral           _BIT7_ - 10000000b
                iAHx             ADMIN - e-mail ofi@bireme.br
                iAHx         PATH_IAHX - caminho para os executaveis do pcte
		iAHx	     ROOT_IAHX - topo da arvore de processamento
                iAHx         PATH_PROC - caminho para a area de processamento
		iAHx         PATH_EXEC - caminho para os executaveis de processamento
                iAHx        PATH_INPUT - caminho para os dados de entrada
                iAHx        INDEX_ROOT - Raiz dos indices de busca
                iAHx            STiAHx - Hostname do servidor de teste
                iAHx            SHiAHx - Hostname do servidor de homologacao
                iAHx            SPiAHx - Hostname do servidor de producao
                ISIS         ISIS - WXISI      - Path para pacote
                ISIS     ISIS1660 - WXIS1660   - Path para pacote
                ISIS        ISISG - WXISG      - Path para pacote
                ISIS         LIND - WXISL      - Path para pacote
                ISIS      LIND512 - WXISL512   - Path para pacote
                ISIS       LINDG4 - WXISLG4    - Path para pacote
                ISIS    LIND512G4 - WXISL512G4 - Path para pacote
                ISIS          FFI - WXISF      - Path para pacote
                ISIS      FFI1660 - WXISF1660  - Path para pacote
                ISIS       FFI512 - WXISF512   - Path para pacote
                ISIS        FFIG4 - WXISFG4    - Path para pacote
                ISIS       FFI4G4 - WXISF4G4   - Path para pacote
                ISIS       FFI256 - WXISF256   - Path para pacote
                ISIS     FFI512G4 - WXISF512G4 - Path para pacote
COMMENT
exit
cat > /dev/null <<SPICEDHAM
CHANGELOG
20131202 Addressing of INBOX via iAHx.tab table
20140226 Directory mapping adjustment
20140805 Change of variable names of environment
20140819 Adaptation to deliverable package
20140828 Antireentrancis mechanism implementation
         Protection against double execution of full processing
SPICEDHAM

