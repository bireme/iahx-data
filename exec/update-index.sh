#!/bin/bash

# -------------------------------------------------------------------------- #
# update-index.sh - Efetua a atualizacao do indice de busca
# -------------------------------------------------------------------------- #
#    Corrente :	/bases/iahx/proc/INSTANCIA/main/
#     Chamada :	update-index.sh [-h|-V|--changelog] [-d N] [-c] [-e] [-i] [-f] [-p] [-x] <ID_INDEX>
#     Exemplo :	update-index.sh -f bioetica
#		update-index.sh -c -p cancer
# Objetivo(s) :	Atualizar/Gerar o indice informado de IAHx
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
vrs:  0.00 20100000, VAAntonio
	- Edicao original
vrs:  1.00 20120828, FJLopes
	- Inclusao de controles diversos de execucao
vrs:  2.00 20121204, FJLopes
	- Alteracao para uso como rotina comum a qualquer instancia
vrs:  2.01 20140829, FJLopes
	- Preparo para formacao de pacote de distribuicao
HISTORICO

# ========================================================================== #
#                                BIBLIOTECAS                                 #
# ========================================================================== #
# Incorpora biblioteca especifica de iAHx
source	$PATH_EXEC/inc/iAHx2.inc
# Conta com as funcoes:
#  rdANYTHING	PARM1	1	Retorna o ID do indice, por qualquer item
#  rdINDEX	PARM1	2	Retorna o nome do indice
#  rdINSTANCIA	PARM1	3	Retorna o nome da instancia
#  rdDIRETORIO	PARM1	4	Retorna o diretorio de processamento
#  rdINDEXFILE	PARM1	5	Retorna o caminho relativo do indice
#  rdINDEXROOT	PARM1	6	Retorna o caminho da raiz dos indices
#  rdTESTE	PARM1	7	Retorna o nome do servidor de teste
#  rdHOMOLOG	PARM1	9	Retorna o nome do servidor de homologacao de dados
#  rdPRODUCAO	PARM1	10	Retorna o nome do servidor de producao
#  rdINBOX	PARM1	12	Retorna o diretorio de dados no INBOX
#  rdLILDBIWEB	PARM1	13	Retorna o caminho para bases externas em LilDBI-Web
#  rdSERVER	PARM1	11	Obtem o numero do iahx-server para o indice
#  rdPORT	PARM1		Obtem o numero do iahx-server para o indice (real)
#  rdSTATUS	PARM1	14	Status da instancia (Ativo / Desativo /?)
#  rdPROCESSA	PARM1	15	Obtem situacao do processamento
#  rdTYPE	PARM1	26	Retorna o tipo de processamento (MANUAL / PROGRAMADO)
#  rdPERIOD	PARM1	27	Periodicidade de processamento
#  rdALL	PARM1	1/3	Retorna pares ID Instancia
#  rdTODAS	PARM1	3	Retorna com a lista de instancias no arquivo de PARM1
#  rdPORTAL	PARM1	28	Nome do portal
#  rdURLOK	PARM1	29	URL publicamente disponivel (P / H / PH / -)
#  rdURL	PARM1	30	URL (parte fixa)
#  rdHOMAPPL	PARM1	8	Retorna o nome do servidor de homologacao de aplicacao
#  rdVERSION	PARM1	33	Versão do iAHx
#  rdLANG	PARM1	32	Obtem lista de idiomas da interface
#  rdOBSERVACAO	PARM1	34	Observacoes sobre a Instancia
#  rdTIMEHOMOL	PARM1		Ultima atualizacao em homologacao
#  rdTIMEPROD	PARM1		Ultima atualizacao em producao

# Incorpora a biblioteca de armadilha de sinais
source $PATH_EXEC/inc/armadilhar.inc
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

# Incorpora biblioteca de controle basico de processamento
source  $PATH_EXEC/inc/infoini.inc
# Conta com as funcoes:
#  isNumber	PARM1	Retorna FALSE se PARM1 nao for numerico

# Garante condicoes minimas de processamento
[ -d "$HOME/logs" ] || mkdir -p $HOME/logs
[ -d "logs" ]       || mkdir -p logs

# Incorpora carregador de defaults padrao
source	$PATH_EXEC/inc/lddefault.dummy.inc
# Adota valores DEFAULT adicionais cabiveis
NOPROD="0";		# Nao enviar para producao
OPC_PROD="";

# -------------------------------------------------------------------------- #
# Mensagem de ajuda e tratamento de opcoes do processamento

#        1         2         3         4         5         6         7         8
#2345678901234567890123456789012345678901234567890123456789012345678901234567890
AJUDA_USO="
Uso: $TREXE [OPCOES] <PARM1>
OPCOES:
 -c, --no-commit    Nao ativa novo indice transferido
 --changelog        Exibe o historico de alteracoes e para a execucao
 -d, --debug NIVEL  Define nivel de depuracao com valor numerico positivo
 -e, --no-erro      Ignora deteccao de erros
 -f, -F, --no-incr  Efetua processamento FULL e nao incremental
 -h, --help         Exibe este texto de ajuda e para a execucao
 -i, --no-input     Ignora dados de entrada
 -p, -P, --no-prod  Nao inclui producao como destino
 -V, --version      Exibe a versao corrente e para a execucao
 -x, --no-xmt       Nao envia dados para o(s) destino(s)

PARAMETROS:
 PARM1  Identificador do indice a processar
"

# -------------------------------------------------------------------------- #
# Tratamento das opcoes de linha de comando (qdo houver alguma)
while test -n "$1"
do
	case "$1" in

		-c | --no-commit)
			NOCOMM="1"
			OPC_COMM="-c"
		;;

		-e | --no-erro)
			NOERRO="1"
			OPC_ERRO="-e"
		;;

		-f | -F | --no-incr)
			NOINCR="1"
			OPC_FULL="-f"
		;;

		-i | --no-input)
			NODATA="1"
			OPC_DATA="-i"
			;;

		-p | -P | --no-prod)
			NOPROD="1"
			OPC_PROD="-p"
		;;

		-x | --no-xmt)
			NOXMT="1"
			OPC_XMT="-x"
		;;

		-h | --help)
			echo "$AJUDA_USO"
			exit 0
		;;

		-V | --version)
			echo -e -n "\n$TREXE "
			grep '^vrs: ' $PRGDR/$TREXE | tail -1
			echo
			exit 0
		;;

		-d | --debug)
			shift
			isNumber $1
			[ $? -ne 0 ] && echo -e "\nSyntax Error\n$TREXE: O argumento da opcao DEBUG deve existir e ser numerico.\n$AJUDA_USO" && exit 2
			DEBUG=$1
			N_DEB=$(expr $(($DEBUG & 6)) / 2)
			FAKE=$(expr $(($DEBUG & _BIT7_)) / 128)
		;;

		--changelog)
			TOTLN=$(wc -l $0 | awk '{ print $1 }')
			INILN=$(grep -n "<SPICEDHAM" $0 | tail -1 | cut -d ":" -f "1")
			LINHAI=$(expr $TOTLN - $INILN)
			LINHAF=$(expr $LINHAI - 2)
			echo -e -n "\n$TREXE - "
			grep '^vrs: ' $PRGDR/$TREXE | tail -1
			echo -n "==> "
			tail -$LINHAI $0 | head -$LINHAF
			echo
			exit 0
		;;

		*)
			if [ $(expr index "$1" "-") -ne 1 ]; then
				if test -z "$PARM1"; then PARM1=$1; shift; continue; fi
				if test -z "$PARM2"; then PARM2=$1; shift; continue; fi
				if test -z "$PARM3"; then PARM3=$1; shift; continue; fi
			else
				echo "Opcao nao valida! ($1)"
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
# Avalia nivel de depuracao e monta parametro para expansao de comando
[ $(($DEBUG & $_BIT3_)) -ne 0  ] && set -v
[ $(($DEBUG & $_BIT4_)) -ne 0  ] && set -x

# ========================================================================== #

#     1234567890123456789012345
echo "[upidx]  1         - UPDATE INDEX"
# -------------------------------------------------------------------------- #
# Garante que a instancia esta definida (sai com codigo de erro 2 - Syntax Error)
if [ -z "$PARM1" ]; then
	#     1234567890123456789012345
	echo "[upidx]  1.01      - Erro na chamada falta o parametro 1"
	echo
	echo "Syntax error:- Missing PARM1"
	echo "$AJUDA_USO"
	exit 2
fi

# -------------------------------------------------------------------------- #
# Garante existencia da tabela de configuracao (sai com codigo de erro 3 - Configuration Error)
#					     1234567890123456789012345
[ $N_DEB -ne 0 ]                    && echo "[upidx]  0.00.04   - Testa se ha tabela de configuracao"
[ ! -s "$PATH_EXEC/tabs/iAHx.tab" ] && echo "[upidx]  1.01      - Tabela iAHx nao encontrada" && exit 3

unset	IDIDX	INDEX
# Garante existencia do indice indicado na tabela de configuracao (sai com codigo de erro 4 - Configuration Failure)
# alem de tomar nome oficial do indice para o SOLR
#					 1234567890123456789012345
[ $N_DEB -ne 0 ] && echo "[upidx]  0.00.05   - Testa se o indice eh valido"
IDIDX=$(rdANYTHING $PARM1)
[ $? -eq 0 ]     && INDEX=$(rdINDEX $IDIDX)
[ -z "$INDEX" ]  && echo "[upidx]  1.01      - PARM1 nao indica um indice valido" && exit 4

# -------------------------------------------------------------------------- #
# Toma os dados de configuracao para o indice indicado
[ $N_DEB -ne 0 ] && echo "[upidx]  0.00.06   - Carrega todas as configuracoes do indice apontado"
INSTA=$(rdINSTANCIA $PARM1)
DIRET=$(rdDIRETORIO $PARM1)

# -------------------------------------------------------------------------- #
# Controle de antireentrancia
F_FLAG="$PATH_PROC/$DIRET/$INSTA.flg"
leF $F_FLAG;		# Carrega valor atual da profundidade de execucao

[ $N_DEB -gt 0 ] && echo "[CRONW]  0.00.00.00 -Arquivo de flag: $F_FLAG contendo: $FLAG"

## Verifica se o valor autoriza a execucao
#if [ $FLAG -gt 0 ]; then
#	echo
#	echo "[CRON-ERR]  0.00.00.00 -Execucao não autorizada por pre-existencia"
#	echo
#	# Envia e-mail sinalizando que não rodou
#	exit 128
#fi

# Conta mais uma execucao
contaF $F_FLAG
[ $N_DEB -gt 0 ] && echo "[CRONW]  0.00.00.00 -Arquivo de flag: $F_FLAG contendo: $FLAG"

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
# ----- #
# -------------------------------------------------------------------------- #

# -------------------------------------------------------------------------- #
source $PATH_EXEC/inc/dbg_displ.inc
# -------------------------------------------------------------------------- #
# Verifica se o diretorio de execucao eh o correto

[ $N_DEB -ne 0 ]              && echo "[upidx]  0.00.07   - Verifica se o diretorio corrente esta correto"
[[ ! "$CURRD" = *"$DIRET"* ]] && echo "[upidx]  1.01      - Diretorio corrente nao eh apropriado" && exit 5

# -------------------------------------------------------------------------- #
cat > /dev/null <<COMMENT

Duas formas de buscar a substring contida em $DIRET na string contida em $CURRD:

1: Soh funciona em BASH
DIROK="FALSE"
if [[ $CURRD = *$DIRET* ]]; then
	DIROK="TRUE"
fi

2: Funciona em SH tambem
case "$CURRD" in
	*${DIRET}*) RETORNO="TRUE"  ;;
		 *) RETORNO="FALSE" ;;
esac

COMMENT

# -------------------------------------------------------------------------- #
# Servico de indexacao local da instancia
echo "[upidx]  2         - Inicia o processamento semanal de indexacao"

#					 1234567890123456789012345
[ $N_DEB -ne 0 ] && echo "[upidx]  0.00.08   - ./index-weekly.sh $PARMD $OPC_ERRO $OPC_FULL $OPC_DATA $PARM1"
./index-weekly.sh $PARMD $OPC_ERRO $OPC_FULL $OPC_DATA $PARM1
RSP=$?; [ "$NOERRO" = "1" ] && RSP=0
source checkerror $RSP "step 1 - index weekly"

if [ $NOCOMM -ne 1 ]; then
# -------------------------------------------------------------------------- #
# Commit

	echo "[upidx]  3         - Commita o procedimento"
	#					 1234567890123456789012345
	[ $N_DEB -ne 0 ] && echo "[upidx]  0.00.09   - $PATH_IAHX/commit.sh \"$PARMD\" \"$PARM1\""
	commit.sh $PARMD $IDIDX
	RSP=$?; [ "$NOERRO" = "1" ] && RSP=0
	source checkerror $RSP "step 2 - commit"


# -------------------------------------------------------------------------- #
# Optimize
	echo "[upidx]  4         - Efetua otimizacao"
	#					 1234567890123456789012345
	[ $N_DEB -ne 0 ] && echo "[upidx]  0.00.10   - $PATH_IAHX/optimize.sh \"$PARMD\" \"$PARM1\""
	optimize.sh $PARMD $PARM1
	RSP=$?; [ "$NOERRO" = "1" ] && RSP=0
	source checkerror $RSP "step 3 - optimize"

fi

# -------------------------------------------------------------------------- #
# Atualiza indice na homologacao
#
[ $N_DEB -ne 0 ] && echo "[upidx]  0.00.11   - Avalia se efetua envio"
if [ "$NOXMT" -ne "1" ]; then
	echo
	echo "[upidx]  5         - Envia dados para a homologacao"
	echo "[upidx]  5.01      - enviaDados.sh -H \"$PARMD\" \"$OPC_ERRO\" \"$OPC_COMM\" \"$IDIDX\""
	enviaDados.sh -H $PARMD $OPC_ERRO $OPC_COMM $IDIDX
	RSP=$?; [ "$NOERRO" = "1" ] && RSP=0
	source checkerror $RSP "step 4 - rsync to homolog"
else
	echo "[upidx]  5         - Envio de dados bloqueado na chamada de $TREXE"
fi

# -------------------------------------------------------------------------- #
# Efetua envio para producao conforme opcao de chamada
#					 1234567890123456789012345
[ $N_DEB -ne 0 ] && echo "[upidx]  0.00.12   - Avalia se envia para a producao"
if [ "$NOXMT" -eq 0 -a "$NOPROD" -eq 0 ]; then
	echo
	echo "[TIME-STAMP] $(date '+%Y%m%d %H:%M:%S') [:MID:] $TREXE $*"
	echo
	echo "[upidx]  6         - Envia dados para a producao"
        echo "[upidx]  6.01      - enviaDados.sh \"$PARMD\" \"$OPC_ERRO\" \"$IDIDX\""
	enviaDados.sh $PARMD $OPC_ERRO $IDIDX
	RSP=$?; [ "$NOERRO" = "1" ] && RSP=0
	source checkerror $RSP "step 4 - rsync to production"
else
	echo "[upidx]  6         - Transferencia a producao bloqueada na chamada de $TREXE"
fi

source	$PATH_EXEC/inc/infofim.inc
# -------------------------------------------------------------------------- #
cat > /dev/null <<COMMENT
     Entrada :	PARM1 com o identificador do indice a processar
		Opcoes de execucao
		 -c, --no-commit	Nao assumir o novo indice
		 --changelog		Mostra historico de alteracoes
		 -d, --debug NIVEL	Define o nivel de depuracao
		 -e, --no-erro		Ignora deteccao de erros
		 -f, -F, --no-incr	Efetuar processamento FULL
		 -h, --help		Mostra o help
		 -i, --no-input		Ignora dados de entrada
		 -p, -P, --no-prod	Nao incluir producao como destino
		 -V, --version		Mostra a versao
		 -x, --no-xmt		Nao envia para o(s) destino(s)
       Saida :	Indice atualizado (opcional) e ativado (opcional) na homologacao
		Indice transferido para a producao (opcional)
		Codigos de retorno:
		   0 - Ok operation
		   1 - Non specific error
		   2 - Syntax Error
		   3 - Configuration error (iAHx.tab not found)
		   4 - Configuration failure (INDEX_ID unrecognized)
		   5 - Wrong working directory ou Data directory empty
		   6 - No connectivity
		   7 - Failed to send data (transmission)
		   8 - Failed to send data (remote MD5)
		   9 - Failed to send data (comparison)
		  10 - Failed to send data (directory creation)
		  11 - Failed to send data (remote copy)
		  12 - Failed to send data (remote rename)
		 128 - Concurrent execution
    Corrente :	/bases/iahx/proc/INSTANCIA/main/
     Chamada :	update-index.sh [-h|-V|--changelog] [-d N] [-c] [-e] [-i] [-f] [-p] [-x] <ID_INDEX>
     Exemplo :	update-index.sh -f bioetica &> logs/out-$(date '+%Y%m%d%H%M%S').txt &
		update-index.sh -c -f ptelessaude
 Objetivo(s) :	1- Atualizar indice de busca
		2- Transferir indice atualizado para homologacao
		3- Ativar o indice na homologacao
		4- Transferir indice atualizado para producao
 Comentarios :	Remonta opcoes de chamada para expansao de comando
			   PARMD	Opcao que define o nivel de depuracao
		NOXMT	 OPC_XMT	Opcao que impede envio de dados
		NOERRO	OPC_ERRO	Opcao que impede deteccao de erros
		NOINCR	OPC_FULL	Opcao de solicita indexacao FULL
		NOPROD	OPC_PROD	Opcao que impede envio para a producao
		NOCOMM	OPC_COMM	Opcao que impede realizar o commit em homolog
		NODATA	OPC_DATA	Opcao que ignora dados de entrada
 Observacoes :	DEBUG eh uma variavel mapeada por bit conforme
			_BIT0_	Aguarda tecla <ENTER>
			_BIT1_	Mostra mensagens de DEBUG
			_BIT2_	Modo verboso
			_BIT3_	Modo debug de linhas -v
			_BIT4_	Modo debug de linha -x
			_BIT7_	Operacao em modo FAKE
		Na variavel PARMD se mantem a opcao de DEBUG a ser utilizada nas chamadas subsequentes
       Notas :	Deve ser executado como usuario 'tomcat'
 Dependencia :	Tabela iAHx.tab deve estar presente em $PATH_EXEC/tabs, com o seguinte layout de campos minimo:
		COLUNA	NOME			COMENTARIOS
		 1	ID_INDICE		ID do indice			(Identificador unico do indice para processamento)
		 2	NM_INDICE		nome do indice conforme o SOLR	(nome oficial do indice)
		 3	NM_INSTANCIA		nome interno da instancia	
		 4	DIR_PROCESSAMENTO	diretorio de processamento      (caminho relativo a $PATH_PROC)
		 5	DIR_INDICE		caminho do indice		(caminho ralativo)
		 6	RAIZ_INDICES		caminho comum dos indices	(caminho absoluto)
		 7	SRV_TESTE		HOSTNAME do servidor de teste de palicacao
		 8	SRV_HOMOLOG APP		HOSTNAME do servidor de homologacao de aplicacao
		 9	SRV_HOMOLOG DATA	HOSTNAME do servidor de homologacao de dados)
		10	SRV_PRODUCAO		HOSTNAME do servidor de producao
		11	IAHX_SERVER		numero do IAHx-server utilizado	(Teste/Homolog/Prod)
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
		iAHx         ROOT_IAHX - topo da arvore de processamento
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
20120604 Implementacao de funcoes acessorias
20120809 Adequacao a servidor generico
20121204 Alteracoes em parametrizacao para operar como rotina generica residente em area comum
         Acrescentados mecanismos de garantia de condicoes de execucao
	 Testada a transferencia para a producao
20140227 Ajuste no mapeamento de diretorios
20140829 Adaptacao para uso com pacote de distribuicao e controle antireentrancia
SPICEDHAM

