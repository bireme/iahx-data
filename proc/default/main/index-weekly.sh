#!/bin/bash

# -------------------------------------------------------------------------- #
# index-weekly.sh - Efetua a atualizacao semanal de INSTANCIA
# -------------------------------------------------------------------------- #
#    Corrente : /bases/iahx/proc/INSTANCIA/main/
#     Chamada : index-weekly.sh [-h|-V|--changelog] [-d N] [-e] [-i|-f] <ID_INDEX>
#     Exemplo : nohup $PATH_PROC/INSTANCIA/main/index-weekly.sh -f default &> logs/$(date '+%Y%m%d%H%M%S').txt &
# Objetivo(s) : 1- Limpar indice caso seja processamento FULL
#		2- Atualizar/Gerar indice de busca
#  IMPORTANTE : deve ser executado com o user 'tomcat'
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
vrs:  1.00 20121009, FJLopes
        - Edicao original
vrs:  1.01 20121123, FJLopes
	- Padronizacao de codigo
vrs:  2.00 20130606, FJLopes
	- Otimizacao de tabela de configuracao
vrs:  2.01 20130705, FJLopes
	- Unificacao de rotina de indexacao
vrs:  2.02 20140815, FJLopes
	- padronizacao para pacote de distribuicao
HISTORICO

# ========================================================================== #
#                                BIBLIOTECAS                                 #
# ========================================================================== #
# Incorpora biblioteca especifica de iAHx
source	$PATH_EXEC/inc/iAHx2.inc
# Conta com as funcoes:
#  rdANYTHING     rdINDEX        rdINSTANCIA    rdDIRETORIO    rdINDEXFILE
#  rdINDEXROOT    rdTESTE        rdHOMOLOG      rdPRODUCAO     rdINBOX
#  rdLILDBIWEB    rdPORT         rdSERVER       rdSTATUS       rdPROCESSA
#  rdTYPE         rdPERIOD       rdALL          rdTODAS        rdPORTAL
#  rdURLOK        rdURL          rdOBJETO       rdHOMAPPL      rdVERSION
#  rdLANG         rdOBSERVATION  rdTIMEHOMOL    rdTIMEPROD

# Incorpora biblioteca de armadilhas (chincada)
source $PATH_EXEC/inc/armadilhar.inc
# Conta com as funcoes:
#	clean_term	clean_hup	clean_int	clean_kill	clean_up	clean_exit
#       leF		contaF		descontaF	resetF

# Incorpora biblioteca de controle basico de processamento
source	$PATH_EXEC/inc/infoini.inc
# Conta com as funcoes:
#	isNumber

# Incorpora carregador de defaults padrao
source	$PATH_EXEC/inc/lddefault.dummy.inc
# Incorpora HELP e tratador de opcoes
source	$PATH_EXEC/inc/mhelp_opc.weekly.inc

# ========================================================================== #

#     1234567890123456789012345
echo "[idxupd]  1         - Atualizacao de Indice"

# -------------------------------------------------------------------------- #
# Garante que o indice esta definido
if [ -z "$PARM1" ]; then
	#     1234567890123456789012345
	echo "[idxupd]  1.01      - Erro na chamada falta o parametro 1"
	echo
	echo "Syntax error:- Missing PARM1"
	echo "$AJUDA_USO"
	exit 2
fi

# -------------------------------------------------------------------------- #
# Garante existencia da tabela de configuracao (sai com codigo de erro 3 - Configuration Error)
#                                            1234567890123456789012345
[ $N_DEB -ne 0 ]                    && echo "[idxupd]  0.00.01   - Testa se ha tabela de configuracao"
[ ! -s "$PATH_EXEC/tabs/iAHx.tab" ] && echo "[idxupd]  1.01      - Tabela iAHx nao encontrada" && exit 3

unset	IDIDX	INDEX
# Garante existencia do indice indicado na tabela de configuracao (sai com codigo de erro 4 - Configuration Failure)
# alem de tomar nome oficial do indice para o SOLR
#                                        1234567890123456789012345
[ $N_DEB -ne 0 ] && echo "[idxupd]  0.00.02   - Testa se o indice eh valido"
IDIDX=$(rdANYTHING $PARM1)
[ $? -eq 0 ]     && INDEX=$(rdINDEX $IDIDX)
[ -z "$INDEX" ]  && echo "[idxupd]  1.01      - PARM1 nao indica um indice valido" && exit 4

[ $N_DEB -ne 0 ] && echo "[idxupd]  0.00.03   - Carrega todas as configuracoes do indice apontado"
INSTA=$(rdINSTANCIA $IDIDX);	# Toma o nome da instancia para controle de flag antireentrancia
DIRET=$(rdDIRETORIO $IDIDX);	# Toma o caminho relativo do diretorio de trabalho

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

[ $N_DEB -ne 0 ]              && echo "[idxupd]  0.00.04   - Verifica se o diretorio corrente esta correto"
[[ ! "$CURRD" = *"$DIRET"* ]] && echo "[idxupd]  1.01      - Diretorio corrente nao eh apropriado" && exit 5

# -------------------------------------------------------------------------- #
# Garante disponibilidade de subsidios
echo "[idxupd]  1.01      - Garante subsidios operacionais"
echo "[idxupd]  1.01.01   - Garante existencia do diretorio xml.index"
[ -d "xml.index" ] || mkdir -p xml.index

# -------------------------------------------------------------------------- #
# Servico de pre-processamento, harvest e indexacao da instancia

# get xml
#     1234567890123456789012345
echo "[idxupd]  2         - Coleta dados"
0-process-inbox.sh $PARMD $OPC_DATA $OPC_ERRO $IDIDX
RSP=$?; [ "$NOERRO" = "1" ] && RSP=0
source checkerror $RSP "step 1 - collecting xml"

# indexacao - index data
#     1234567890123456789012345
echo "[idxupd]  3         - Inicia o processamento de indexacao"
1-index.sh $PARMD $OPC_DATA $OPC_ERRO $OPC_FULL $IDIDX
RSP=$?; [ "$NOERRO" = "1" ] && RSP=0
source	checkerror $RSP "step 2 - index"

source	$PATH_EXEC/inc/clean_wrk.dummy.inc
source	$PATH_EXEC/inc/infofim.inc
# -------------------------------------------------------------------------- #
cat > /dev/null <<COMMENT

     Entrada:	PARM1 identificacao do indice processar
		Opcoes de execucao
		 --changelog		Mostra historico de alteracoes
		 -d N, --debug N	Nivel de depuracao
		 -e, --no-error		Ignora detecao de erros
		 -f, -F, --FULL		rocessamento nao incremental
		 -h, --help		Mostra o help
		 -i, --no-input		Ignora dados na caixa de entrada
		 -V, --versao		Mostra a versao
       Saida:	Indice processado em /home/javaapps/iahx-server/indexes/INSTANCIA/main/data/index/
    Corrente:	/bases/iahx/proc/INSTANCIA/main/
     Chamada:	/index-weekly.sh [-h|-V|--changelog] [-e] [-i|-f] [-d N] <ID_INDEX>
     Exemplo:	/bases/iahx/proc/INSTANCIA/main/index-weekly.sh -f bioetica &> logs/$(date '+%Y%m%d%H%M%S').txt &
 Objetivo(s):	1- Eliminar documentos existentes caso seja FULL
		2- Atualizar/Gerar indice de busca
 Comentarios:	-
 Observacoes:	DEBUG eh uma variavel mapeada por bit
		_BIT0_	Aguarda tecla <ENTER>
		_BIT1_	Mostra mensagens de debug
		_BIT2_	Modo verboso
		_BIT3_	Modo debug de linha -v
		_BIT4_	Modo debug de linha -x
		_BIT7_	Execucao FAKE
       Notas:	Deve ser executado com o usuario 'tomcat'
Dependencias:	Variaveis de ambiente que devem estar previamente ajustadas:
		geral	      TRANSFER - Usuario para troca de arquivos entre servidores
		geral		_BIT0_ - 00000001b
		geral		_BIT1_ - 00000010b
		geral		_BIT2_ - 00000100b
		geral		_BIT3_ - 00001000b
		geral		_BIT4_ - 00010000b
		geral		_BIT5_ - 00100000b
		geral		_BIT6_ - 01000000b
		geral		_BIT7_ - 10000000b
		iAHx		 ADMIN - e-mail ofi@bireme.br
		iAHx	     PATH_IAHX - caminho para os executaveis do pcte
		iAHx	     PATH_PROC - caminho para a area de processamento
		iAHx	    PATH_INPUT - caminho para os dados de entrada
		iAHx	    INDEX_ROOT - Raiz dos indices de busca
		iAHx	        STiAHx - Hostname do servidor de teste
		iAHx	        SHiAHx - Hostname do servidor de homologacao
		iAHx	        SPiAHx - Hostname do servidor de producao
		ISIS	     ISIS - WXISI      - Path para pacote
		ISIS	 ISIS1660 - WXIS1660   - Path para pacote
		ISIS	    ISISG - WXISG      - Path para pacote
		ISIS	     LIND - WXISL      - Path para pacote
		ISIS	  LIND512 - WXISL512   - Path para pacote
		ISIS	   LINDG4 - WXISLG4    - Path para pacote
		ISIS	LIND512G4 - WXISL512G4 - Path para pacote
		ISIS	      FFI - WXISF      - Path para pacote
		ISIS	  FFI1660 - WXISF1660  - Path para pacote
		ISIS	   FFI512 - WXISF512   - Path para pacote
		ISIS	    FFIG4 - WXISFG4    - Path para pacote
		ISIS	   FFI4G4 - WXISF4G4   - Path para pacote
		ISIS	   FFI256 - WXISF256   - Path para pacote
		ISIS	 FFI512G4 - WXISF512G4 - Path para pacote
COMMENT
exit
cat > /dev/null <<SPICEDHAM
CHANGELOG
20121009 Adaptacao para servidor generico
20121123 Completamento de padrao de codigo fonte e suporte a depuracao"
20130131 Inclusao de unset de IDIDX e INDEX
         uso da funcao readANY para recuperar por qualquer item
20130403 Modularizacao do codigo fonte (includes)
20130606 Enderecamento de INBOX via tabela iAHx.tab
20130705 Unificacao de rotina de indexacao
20140815 Padronizacao para pacote de distribuicao
SPICEDHAM

