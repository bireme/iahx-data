#!/bin/bash

# -------------------------------------------------------------------------- #
# 1-index.sh - Efetua a indexacao dos dados depositados em xml.index ou INBOX
# -------------------------------------------------------------------------- #
#    Corrente : /bases/iahx/proc/INSTANCIA/main/
#     Chamada : 1-index.sh [-h|-V|--changelog] [-d N] [-e] [-f] [-i] [-x] <ID_INDEX>
#     Exemplo : 1-index.sh -f bioetica
#               1-index.sh -e cancer
# Objetivo(s) : Atualizar/Gerar o indice informado de IAHx
#  IMPORTANTE : Deve ser executado com o user 'tomcat'
# -------------------------------------------------------------------------- #
#  Centro Latino-Americano e do Caribe de Informação em Ciências da Saúde
#     é um centro especialidado da Organização Pan-Americana da Saúde,
#           escritório regional da Organização Mundial da Saúde
#                      BIREME / OPS / OMS (P)2012-14
# -------------------------------------------------------------------------- #
# Historico
# versao data, Responsavel
#	- Descricao
cat > /dev/null <<HISTORICO
vrs:  0.00 20100000, VAA
	- Edicao original
vrs:  1.00 20130705, FJLopes
	- Otimizacao de tabela de configuracao
vrs:  1.01 20140313, FJLopes
	- Preparo para formacao de pacote de distribuicao
vrs:  1.02 20140829, FJLopes
	- mecanismo de controle antireentrancia
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
#  rdConfig	PARM1	Item de configuracao a ser lido
# Estabelece as variaveis:
#	CURRD	Diretorio corrente no momento da carga
#	HINIC	Tempo inicial em segundos desde 01/01/1970
#	HRINI	Hora de inicio no formato YYYYMMDD hh:mm:ss
#	_DIA_	Dia calendario no formato DD
#	_MES_	Mes calendario no formato MM
#	_ANO_	Ano calendario no formato YYYY
#	TREXE	Demoninacao do programa em execucao
#	PRGDR	Path para o programa em execucao
#	LCORI	Linha de comando original da chamada
#	DTFJL	Data calendario no formato YYYYMMDD

# Incorpora carregador de defaults padrao
source	$PATH_EXEC/inc/lddefault.dummy.inc
# Incorpora HELP e tratador de opcoes
source	$PATH_EXEC/inc/mhelp_opc.index.inc

# ========================================================================== #

#     1234567890123456789012345
echo "[INDEX]  1         - Inicia processamento de indexacao solr"
# -------------------------------------------------------------------------- #
# Garante que a instancia esta definida (sai com codigo de erro 2 - Syntax Error)
if [ -z "$PARM1" ]; then
	#     1234567890123456789012345
	echo "[INDEX]  1.01      - Erro na chamada falta o parametro 1"
	echo
	echo "Syntax error:- Missing PARM1"
	echo "$AJUDA_USO"
	exit 2
fi

# -------------------------------------------------------------------------- #
# Garante existencia da tabela de configuracao (sai com codigo de erro 3 - Configuration Error)
#                                            1234567890123456789012345
[ $N_DEB -ne 0 ]                    && echo "[INDEX]  0.00.04   - Testa se ha tabela de configuracao"
[ ! -s "$PATH_EXEC/tabs/iAHx.tab" ] && echo "[INDEX]  1.01      - Tabela iAHx nao encontrada" && exit 3

unset	IDIDX	INDEX
# Garante existencia do indice indicado na tabela de configuracao (sai com codigo de erro 4 - Configuration Failure)
# alem de tomar nome oficial do indice para o SOLR
#                                        1234567890123456789012345
[ $N_DEB -ne 0 ] && echo "[INDEX]  0.00.05   - Testa se o indice eh valido"
IDIDX=$(rdANYTHING $PARM1)
[ $? -eq 0 ]     && INDEX=$(rdINDEX $IDIDX)
[ -z "$INDEX" ]  && echo "[INDEX]  1.01      - PARM1 nao indica um indice valido" && exit 4

# Toma os dados de configuracao para o indice indicado
[ $N_DEB -ne 0 ] && echo "[INDEX]  0.00.06   - Carrega todas as configuracoes do indice apontado"
INSTA=$(rdINSTANCIA $IDIDX)
DIRET=$(rdDIRETORIO $IDIDX)
I_BOX=$(rdINBOX     $IDIDX)

# Se deve usar fonte de dados padrao ok, senao assume o INBOX
[ "$PATH_DATA" = "xml.index" ] || PATH_DATA="${PATH_INPUT}/${I_BOX}"

# -------------------------------------------------------------------------- #
# Controle de antireentrancia
F_FLAG="$PATH_PROC/$DIRET/$INSTA.flg"
leF $F_FLAG;            # Carrega valor atual da profundidade de execucao

[ $N_DEB -gt 0 ] && echo "[idxupd]  0.00.04    -Arquivo de flag: $F_FLAG contendo: $FLAG"

## Verifica se o valor autoriza a execucao
#if [ $FLAG -gt 0 ]; then
#        echo
#        echo "[idxupd]  0.00.05    -Execucao não autorizada por pre-existencia"
#        echo
#        # Envia e-mail sinalizando que não rodou
#        exit 128
#fi

# Conta mais uma execucao
contaF $F_FLAG
[ $N_DEB -gt 0 ] && echo "[idxupd]  0.00.06    -Arquivo de flag: $F_FLAG contendo: $FLAG"

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
source	$PATH_EXEC/inc/dbg_displ.inc
# -------------------------------------------------------------------------- #
# Verifica se o diretorio de execucao eh o correto

[ $N_DEB -ne 0 ]              && echo "[INDEX]  0.00.04   - Verifica se o diretorio corrente esta correto"
[[ ! "$CURRD" = *"$DIRET"* ]] && echo "[INDEX]  1.01      - Diretorio corrente nao eh apropriado" && exit 5

# --------------------------------------------------------------------------- #
# Servico de pre-processamento
#     1234567890123456789012345
echo "[INDEX]  1.02      - Corrige enderecamento de dados"
# PATH_DATA com o caminho para chegar ao XML a indexar
[ $N_DEB -ne "0" ] && echo "[INDEX]  1.02.01   - Subdiretorio com os dados: $PATH_DATA"

# -------------------------------------------------------------------------- #
# Garante que exista dados a processar
echo "[INDEX]  1.03      - Verifica se tem algum XML para processar"
if [ "$NODATA" -eq "0" ]; then
	if [ $(ls $PATH_DATA/*.xml 2> /dev/null | wc -l) -eq 0 ]; then
		echo "Data missing:- There are no data to process"
		exit 5
	fi
fi

# -------------------------------------------------------------------------- #
# Prepara processamento FULL (mas só apaga se tiver dados liberados para indexar)
echo "[INDEX]  2         - Prepara area de processamento"
if [ "$NODATA" -eq "0" -a "$NOINCR" -eq "1" ]; then
	[ $FAKE -eq 0 ] && echo "[INDEX]  2.01      - Apaga documentos anteriores"
	[ $FAKE -eq 0 ] || echo "[INDEX]  2.01      - Modo fake, apagaria documentos anteriores"
	${PATH_IAHX}/deletedocs.sh $PARMD $OPC_ERRO ${INDEX} *:*
	RSP=$?; [ "$NOERRO" = "1" ] && RSP=0
	source checkerror $RSP "Problem deleting old index ${INDEX}"
fi

# -------------------------------------------------------------------------- #
echo "[INDEX]  3         - Indexa cada XML disponivel em $PATH_INPUT/$PATH_DATA"

# Confere o INDICE em uso
[ $N_DEB -ne "0" ] && echo "                     Indice sendo operado: $PARM1"

echo "[INDEX]  3.01      - Efetua a indexacao XML a XML (localizados em xml.index)"
ITERACAO=1
for i in $PATH_DATA/*.xml 
do
	echo -n "[INDEX]  3.01."; printf "%02d" $ITERACAO
	[ $FAKE -eq 0 ] && echo "   - Indexando $(basename $i)"
	[ $FAKE -eq 0 ] || echo "   - Modo fake, indexaria $(basename $i)"
	if [ -s $i ]; then
		if [ "$FAKE" -ne "1" -a "$NODATA" -eq "0" ]; then
			index.sh $i ${INDEX}
			RSP=$?; [ "$NOERRO" = "1" ] && RSP=0
			source checkerror $RSP "Problem indexing $i"
		else
			echo "======>  index.sh $i ${INDEX}"
		fi
	else
		echo "[INDEX]            - WARNING: Attempt to indexing an empty XML"
	fi
	ITERACAO=$(expr $ITERACAO + 1)
	echo
done

source	$PATH_EXEC/inc/clean_wrk.dummy.inc
source	$PATH_EXEC/inc/infofim.inc
# -------------------------------------------------------------------------- #
cat > /dev/null <<COMMENT
     Entrada :	PARM1 identificando o indice a ser processado
		Opcoes de execucao
		 -a		Fonte alternativa de dados para indexacao
		 --changelog	Mostra historico de alteracoes
		 -d, --debug	Nivel de depuracao [0..255]
		 -e, --no-error	Ignora detecao de erros
		 -f, -F, --FULL	Executa processamento 'FULL'
		 -h, --help	Mostra o help
		 -i, --no-input	Ignora dados de entrada
		 -V, --versao	Mostra a versao
       Saida :	Indice atualizado
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
     Chamada :	1-index.sh [-h|-V|--changelog] [-a] [-d N] [-e] [-f] [-i] <ID_INDEX>
     Exemplo :	nohup 1-index.sh -d 2 ghl &> logs/YYYYMMDD.index.txt &
 Objetivo(s) :	1- Atualizar indice de busca
 Comentarios :  Remonta opcoes de chamada para expansao de comando
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
			_BIT4_	Modo debug de linhas -x
			_BIT7_	Opera em modo FAKE
       Notas :	Deve ser executado como usuario 'tomcat'
 Dependencia :	Tabela iAHx.tab deve estar presente em $PATH_EXEC/tabs
		COLUNA	NOME			COMENTARIOS
		 1	ID_INDICE		ID do indice			(Identificador unico do indice para processamento)
		 2	NM_INDICE		nome do indice conforme o SOLR	(nome oficial do indice)
		 3	NM_INSTANCIA		nome interno da instancia
		 4	DIR_PROCESSAMENTO	diretorio de processamento	(caminho relativo a $PATH_PROC)
		 5	DIR_INDICE		caminho do indice		(caminho relativo)
		 6	RAIZ_INDICES		caminho comum dos indices	(caminho absoluto)
		 7	SRV_TESTE		HOSTNAME do servidor de teste de palicacao
		 8	SRV_HOMOLOG APP		HOSTNAME do servidor de homologacao de aplicacao
		 9	SRV_HOMOLOG DATA	HOSTNAME do servidor de homologacao de dados
		10	SRV_PRODUCAO		HOSTNAME do servidor de producao
		11	IAHX_SERVER		numero do IAHx-server utilizado	(Teste/Homolog/Prod)
		12	DIR_INBOX		nome do diretorio dos dados de entrada
		13	NM_LILDBI		qualificacao total das bases de dados LILDBI-Web, separadas pelo sinal '^'
		14	SITUACAO		estado do indice		(HOMOLOGACAO / ATIVO / INATIVO / ...)
		15	PROCESSA		liberado para processar		(em operacao)
		16-25	RESERVA_DE_OFI						(USO DE OPERACAO DE FONTE DE INFORMACAO)
		26	TIPOPROC                escalacao do processamento	(manual / automatica)
		27	PERIODICIDADE           intervalo entre processamento	(0/pedido 1/diario 2/alternado 3/bisemanal 4/semanal 5/quinzenal 6/mensal)
		28	NM_PORTAL               nome oficial do portal
		29	URL_DISPONIVEL          URL de aplicacao funcional	(P / H / PH / -)
		30	URL                     Universal Resource Locator
		31	PARAMETRO_URL           complemento de URL para acesso web
		32	IDIOMAS                 versoes idiomaticas de interface
		33	VERSAO_APP              versao do OPAC
		34	OBSERVACAO              informações relevantes diversas
		35	WIKI_EXPRESSAO          URL do wiki com a expressao de selecao de registros
		36	LST_FISIDX              lista de FIs indexadas neste indice
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
20130705 Enderecamento de INBOX via tabela iAHx.tab
20140220 Ajuste no mapeamento de diretorios
20140312 Adequacao de variaveis comum aos processamentos em geral (N_DEB e FAKE)
20140313 Reducao de funcoes semelhantes
20140923 Adaptacao para uso com pacote de distribuicao e controle antireentrancia
SPICEDHAM

