
# ========================================================================== #
#                                  FUNCOES
# ========================================================================== #
cat > /dev/null <<COMMENT

	rdLIB		-		[Ok]		Retorna informacoes sobre a biblioteca iAHx.inc
readANY	rdANYTHING	PARM1		[Ok]	1	Retorna o ID do indice, por qualquer item
readIDX	rdINDEX		PARM1		[Ok]	2	Retorna o nome do indice
readINS	rdINSTANCIA	PARM1		[Ok]	3	Retorna o nome da instancia
readDIR	rdDIRETORIO	PARM1		[Ok]	4	Retorna o diretorio de processamento
	rdINDEXFILE	PARM1		[Ok]	5	Retorna o caminho relativo do indice
readCMM	rdINDEXROOT	PARM1		[Ok]	6	Retorna o caminho da raiz dos indices
	rdTESTE		PARM1		[Ok]	7	Retorna o nome do servidor de teste
readHOM	rdHOMOLOG	PARM1		[Ok]	9	Retorna o nome do servidor de homologacao de dados
readPRO	rdPRODUCAO	PARM1		[Ok]	10	Retorna o nome do servidor de producao
readINB	rdINBOX		PARM1		[Ok]	12	Retorna o diretorio de dados no INBOX
readLDW	rdLILDBIWEB	PARM1		[Ok]	13	Retorna o caminho para bases externas em LilDBI-Web
	rdPORT		PARM1		[Ok]		Obtem o numero do iahx-server configurado para o indice
	rdSERVER	PARM1		[Ok]	11	Obtem o numero do iahx-server solicitado para o indice
	rdSTATUS	PARM1		[Ok]	14	Status da instancia (Ativo / Desativo /?)
	rdPROCESSA	PARM1		[Ok]	15	Obtem situacao do processamento 
	rdINFO		PARM1		[Ok]	ALL	retorna informacoes do indice/instancia
	rdTYPE		PARM1		[Ok]	26	Retorna o tipo de processamento (MANUAL / PROGRAMADO)
	rdPERIOD	PARM1		[Ok]	27	Frequencia de processamento (0 pedido/1 diar/2 alternado/3 2Xsem/4 semanal/5 quinzenal/6 mensal)
	rdALL		PARM1		[Ok]	1/3	Retorna pares ID Instancia
	rdTODAS		PARM1		[Ok]	3	Retorna com a lista de instancias no arquivo de PARM1
	rdPORTAL	PARM1		[Ok]	28	Nome do portal
	rdURLOK		PARM1		[Ok]	29	URL publicamente disponivel (P / H / PH / -)
readURL	rdURL		PARM1		[Ok]	30	URL (parte fixa)
	rdOBJETO	PARM1		[Ok]	31	Documento a ser acessado
	rdHOMAPPL	PARM1		[Ok]	8	Retorna o nome do servidor de homologacao de aplicacao
	rdVERSION	PARM1		[Ok]	33	Versão do iAHx
	rdLANG		PARM1		[Ok]	32	Obtem lista de idiomas da interface
	rdOBSERVATION	PARM1		[Ok]	34	Observacoes sobre a Instancia
	rdCONSULTA	PARM1		[]		Indice consultado
	rdTIMEHOMOL	PARM1		[Ok]		Ultima atualizacao em homologacao
	rdTIMEPROD	PARM1		[Ok]		Ultima atualizacao em producao
	rdBASES		PARM1 PARM2	[]		Bases participantes do indice

COMMENT
# ========================================================================== #
# rdANYTHING	Le o ID oficial do indice
# PARM $1	ID ou qualquer item tabelado para o indice
# Observacao	Retorna o primeiro encontrado qdo houver mais de um
#		Antiga funcao readANY
#
rdANYTHING() {
	TMPR=$(grep -i "^${1}\b" $PATH_EXEC/tabs/iAHx.tab)
	if [ $? -eq 0 ]; then
		# Perguntou usando o proprio identificador
		echo  "$TMPR" | awk -F "\t" '{ print $1 }' | head -1
	else
		# Perguntou usando outro elemento de dado
		TMPR=$(grep -i "\b${1}\b" $PATH_EXEC/tabs/iAHx.tab)
		if [ $? -eq 0 ]; then
			echo "$TMPR" | awk -F "\t" '{ print $1 }' | head -1
		else
			#  Nao encontrou correspondencia
			false
		fi
	fi
}

# rdINDEX	Le o nome do indice como o SOLR conhece
# PARM $1	ID do indice a recuperar dados
# Observacao	Antiga funcao readIDX
#
rdINDEX() {
	TMPR=$(grep "^${1}	" $PATH_EXEC/tabs/iAHx.tab)
	if [ $? -eq 0 ]; then
		echo  "$TMPR" | awk -F "\t" '{ print $2 }'
	else
		false
	fi
}

# rdINSTANCIA	Obtem o nome da instancia como o usuario conhece
# PARM $1	ID do indice a recuperar dados
# Observacao	Complemento da URL para acesso a pesquisa
#		Antiga funcao readINS
#
rdINSTANCIA() {
	TMPR=$(grep "^${1}	" $PATH_EXEC/tabs/iAHx.tab)
	if [ $? -eq 0 ]; then
		echo "$TMPR" | awk -F "\t" '{ print $3 }'
	else
		false
	fi
}

# rdDIRETORIO	Le o diretorio de processamento
# PARM $1 	ID do indice a recuperar dados
# Observacao	Diretorio corrente para tempo de processamento
#		Antiga funcao readDIR
#
rdDIRETORIO() {
	TMPR=$(grep "^${1}	" $PATH_EXEC/tabs/iAHx.tab)
	if [ $? -eq 0 ]; then
		echo "$TMPR" | awk -F "\t" '{ print $4 }'
	else
		false
	fi
}

# rdINDEXFILE	Obtem o caminho relativo especifico do indice
# PARM $1	ID do indice a gravar dados
# Observacao	Topo da arvore dos indices no iahx-server
#
rdINDEXFILE() {
	TMPR=$(grep "^${1}	" $PATH_EXEC/tabs/iAHx.tab)
	if [ $? -eq 0 ]; then
		echo "$TMPR" | awk -F "\t" '{ print $5 }'
	else
		false
	fi
}

# rdINDEXROOT	Obtem o caminho comum nos servidores (raiz dos indices)
# PARM $1	ID do indice a recuperar/gravar dados
# Observacao	Topo da arvore dos indices no iahx-server
#		Antiga funcao readCMM
#
rdINDEXROOT() {
	TMPR=$(grep "^${1}	" $PATH_EXEC/tabs/iAHx.tab)
	if [ $? -eq 0 ]; then
		echo "$TMPR" | awk -F "\t" '{ print $6 }'
	else
		false
	fi
}

# rdTESTE	Le o nome do servidor de teste
# PARM $1	ID do indice a recuperar dados
# Observacao	hostname do servidor de teste
#
rdTESTE() {
	TMPR=$(grep "^${1}	" $PATH_EXEC/tabs/iAHx.tab)
	if [ $? -eq 0 ]; then
		echo "$TMPR" | awk -F "\t" '{ print $7 }'
	else
		false
	fi
}

# rdHOMOLOG	Le o nome do servidor de homologacao
# PARM $1	ID do indice a recuperar dados
# Observacao	hostname do servidor de homologacao
#		Antiga funcao readHOM
#
rdHOMOLOG() {
	TMPR=$(grep "^${1}	" $PATH_EXEC/tabs/iAHx.tab)
	if [ $? -eq 0 ]; then
		echo "$TMPR" | awk -F "\t" '{ print $9 }'
	else
		false
	fi
}

# rdPRODUCAO	Le o nome do servidor de producao
# PARM $1	ID do indice a recuperar dados
# Observacao	hostname do servidor de producao
#		Antiga funcao readPRO
#
rdPRODUCAO() {
	TMPR=$(grep "^${1}	" $PATH_EXEC/tabs/iAHx.tab)
	if [ $? -eq 0 ]; then
		echo "$TMPR" | awk -F "\t" '{ print $10 }'
	else
		false
	fi
}
								
# rdINBOX	Obtem o diretorio de INBOX em $PATH_INPUT
# PARM $1	ID do indice a recuperar dados
# Observacao	Antiga funcao readINB
#
rdINBOX() {
	TMPR=$(grep "^${1}	" $PATH_EXEC/tabs/iAHx.tab)
	if [ $? -eq 0 ]; then
		echo "$TMPR" | awk -F "\t" '{ print $12 }'
	else
		false
	fi
}

# rdLILDBIWEB	Obtem o endereco da bases de LILDBI-Web
# PARM $1	ID do indice a recuperar dados
# Observacao	O endereco deve incluir hostname e caminho completo ate a base de dados
#		Antiga funcao readLDW
#
rdLILDBIWEB() {
	TMPR=$(grep "^${1}	" $PATH_EXEC/tabs/iAHx.tab)
	if [ $? -eq 0 ]; then
		echo "$TMPR" | awk -F "\t" '{ print $13 }' | tr "^" "\012"
	else
		false
	fi
}

# rdPORT	Obtem o numero do iahx-server efetivo para o indice
# PARM $1	ID do indice a recurerar o iahx-server
# Observacao	No retorno se o codigo for TRUE o numero retornado eh valido
#
rdPORT() {
	INDX=$(rdINDEX $1)
	INSTANCIAS="${PATH_IAHX}/../instances/"
	for instance in $(ls $INSTANCIAS)
	do
		if [ -f "${INSTANCIAS}/${instance}/conf/Catalina/localhost/${INDX}.xml" ]; then
			echo ${instance}
			break
		fi
		false
	done
}

# rdSERVER	Obtem o numero do iahx-server solicitado para o indice
# PARM $1	ID do indice a recuperar o iahx-server
# Observacao	No retorno o numero do servidor
#
rdSERVER() {
	TMPR=$(grep "^${1}	" $PATH_EXEC/tabs/iAHx.tab)
	if [ $? -eq 0 ]; then
		echo "$TMPR" | awk -F "\t" '{ print $11 }'
	else
		false
	fi
}

# rdSTATUS	Obtem o status da instancia
# PARM $1	ID do indice a recuperar dados
# Observacao	Responde como ATIVO / INATIVO / DESATIVADO / HOMOLOGACAO / ?
#
rdSTATUS() {
	TMPR=$(grep "^${1}	" $PATH_EXEC/tabs/iAHx.tab)
	if [ $? -eq 0 ]; then
		echo "$TMPR" | awk -F "\t" '{ print $14 }'
	else
		false
	fi
}

# rdPROCESSA	Obtem estado do processamento do indice LIBERADO ou NAO
# PARM $1 	ID do indice a saber se esta em processamento
# Observacao	Responde como SIM / NAO
#
rdPROCESSA() {
	TMPR=$(grep "^${1}	" $PATH_EXEC/tabs/iAHx.tab)
	if [ $? -eq 0 ]; then
		echo "$TMPR" | awk -F "\t" '{ print $15 }' | tr [:lower:] [:upper:]
	else
		false
	fi
}

# rdINFO	Exibe as informacoes da instancia/indice
# PARM $1	ID do indice a saber as informacoes
# Observacao	.
#
rdINFO() {
	TMPR=$(grep "^${1}	" $PATH_EXEC/tabs/iAHx.tab)
	if [ $? -eq 0 ]; then
		echo "=============="
		echo "     ID_INDEX $(rdANYTHING  $TMPR)"
		echo "     NM_INDEX $(rdINDEX     $TMPR)"
		echo " NM_INSTANCIA $(rdINSTANCIA $TMPR)"
		echo "       PORTAL $(rdPORTAL    $TMPR)"
		echo "  DIR_PROCESS $(rdDIRETORIO $TMPR)"
		echo "  LOCAL_INDEX $(rdINDEXROOT $TMPR)/$(rdINDEXFILE $TMPR)"
		if [ -z $(rdTESTE $TMPR) ]; then
			echo "   Serv Teste (nao tem)"
		else
			echo "   Serv Teste $(rdTESTE $TMPR)"
		fi
		if [ ! $(rdHOMOLOG $TMPR) = "." ]; then
			echo " Serv Homolog $(rdHOMOLOG   $TMPR)"
		else
			echo " Serv Homolog no processamento"
		fi
		echo "Serv Producao $(rdPRODUCAO  $TMPR)"
		echo "         PORT 898$(rdPORT   $TMPR) no iahx-server $(echo "$TMPR" | awk -F "\t" '{ print $11 }')"
		echo "    DIR_INBOX $(rdINBOX     $TMPR)"
		echo "     SITUACAO $(rdSTATUS    $TMPR)"
		echo "    PROCESSAR $(rdPROCESSA  $TMPR) em modo $(rdTYPE $TMPR) com frequencia $(rdPERIOD $TMPR)"
		URL=$(rdURL $TMPR)
		if [ ! -z "$URL" -a ! "$URL" = "-" ]; then
			echo "URL de Acesso http://$(rdURL $TMPR)/$(rdOBJETO $TMPR)"
		fi
		if [ ! -z $(rdTESTE $TMPR) ]; then
			echo " URL SOLR TST http://$(rdTESTE $TMPR).bireme.br:898$(rdPORT $TMPR)/$(rdINDEX $TMPR)/admin"
		fi
		if [ ! $(rdHOMOLOG $TMPR) = "." ]; then
			echo " URL SOLR HOM http://$(rdHOMOLOG $TMPR).bireme.br:898$(rdPORT $TMPR)/$(rdINDEX $TMPR)/admin"
		fi
		echo " URL SOLR PRD http://$(rdPRODUCAO $TMPR).bireme.br:898$(rdPORT $TMPR)/$(rdINDEX $TMPR)/admin"
		echo "=============="
	else
		false
	fi
}

# rdTYPE	Obtem o tipo de processamento do indice
# PARM $1	ID do indice a recuperar dados
# Observacao	Tipos suportados MANUAL / AUTOMATICO
#
rdTYPE() {
	TMPR=$(grep "^${1}	" $PATH_EXEC/tabs/iAHx.tab)
	if [ $? -eq 0 ]; then
		echo "$TMPR" | awk -F "\t" '{ print $26 }'
	else
		false
	fi
}

# rdPERIOD	Obtem a periodicidade de processamento/atualizacao
# PARM $1	ID do indice a recuperar dados
# Observacao	Responde com um text (anual / weekly / annual / bi-semanal / ...)
#
rdPERIOD() {
	TMPR=$(grep "^${1}	" $PATH_EXEC/tabs/iAHx.tab)
	if [ $? -eq 0 ]; then
		echo "$TMPR" | awk -F "\t" '{ print $27 }'
	else
		false
	fi
}

# rdALL		Le a chave primaria de todas as instancias e seus nomes
# PARM $1	caminho e nome do arquivo para conter a lista
# Observacao	Grava no arquivo indicado a lista colunas separadas por pipe
#
rdALL () {
	awk -F "\t" '{ print $1 "|" $3 }' $PATH_EXEC/tabs/iAHx.tab > $1
}

# rdTODAS	Le o nome de todas as instancias
# PARM $1       caminho e nome do arquivo para conter a lista
# Observacao    Grava no arquivo indicado a lista com as instancias cadastradas
#
rdTODAS() {
	awk -F "\t" '{ print $3 }' $PATH_EXEC/tabs/iAHx.tab > $1
}

# rdPORTAL	Obtem o nome do portal servido pelo indice
# PARM $1	ID do indice a recuperar dados
# Observacao	Nome humano do portal
#
rdPORTAL() {
	TMPR=$(grep "^${1}	" $PATH_EXEC/tabs/iAHx.tab)
	if [ $? -eq 0 ]; then
		echo "$TMPR" | awk -F "\t" '{ print $28 }'
	else
		false
	fi
}

# rdURLOK	Obtem o nivel de disponibilidade do indice
# PARM $1	ID do indice a recuperar dados
# Observacao	Tipo de disponibilidade publica (P / H / PH / -)
#
rdURLOK() {
	TMPR=$(grep "^${1}	" $PATH_EXEC/tabs/iAHx.tab)
	if [ $? -eq 0 ]; then
		echo "$TMPR" | awk -F "\t" '{ print $29 }'
	else
		false
	fi
}

# rdURL		Obtem a URL de chamada da interface OPAC sem parametros (parte fixa)
# PARM $1	ID do indice a recuperar dados
# Observacao	URL base da interface de pesquisa sem a identificacao do indice
#		Antiga funcao readURL
#
rdURL() {
	TMPR=$(grep "^${1}	" $PATH_EXEC/tabs/iAHx.tab)
	if [ $? -eq 0 ]; then
		echo "$TMPR" | awk -F "\t" '{ print $30 }'
	else
		false
	fi
}

# rdOBJETO	Obtem o parametro de acesso a URL
# PARM $1	ID do indice a recuperar dados
# Observacao	Complemento da URL para pesquisa
#
rdOBJETO() {
	TMPR=$(grep "^${1}	" $PATH_EXEC/tabs/iAHx.tab)
	if [ $? -eq 0 ]; then
		echo "$TMPR" | awk -F "\t" '{ print $31 }'
	else
		false
	fi
}

# rdHOMAPP	Obtem o servidor da homologacao da aplicacao
# PARM $1	ID do indice a recuperar dados
# Observacao	Responde com o nome do servidor de homologacao da aplicacao
#
rdHOMAPP() {
	TMPR=$(grep "^${1}	" $PATH_EXEC/tabs/iAHx.tab)
	if [ $? -eq 0 ]; then
		echo "$TMPR" | awk -F "\t" '{ print $8 }'
	else
		false
	fi
}

# rdVERSION	Obtem a versao do iAHx aplicado
# PARM $1	ID do indice a recuperar dados
# Observacao	Responde com o numero da versao
#
rdVERSION() {
	TMPR=$(grep "^${1}	" $PATH_EXEC/tabs/iAHx.tab)
	if [ $? -eq 0 ]; then
		echo "$TMPR" | awk -F "\t" '{ print $33 }'
	else
		false
	fi
}

# rdLANG	Obtem lista de idiomas da interface
# PARM $1	ID do indice a recuperar dados
# Observacao	Responde com o texto cadastrado
#
rdLANG() {
	TMPR=$(grep "^${1}	" $PATH_EXEC/tabs/iAHx.tab)
	if [ $? -eq 0 ]; then
		echo "$TMPR" | awk -F "\t" '{ print $32 }'
	else
		false
	fi
}

# rdOBSERVATION	Obtem notas sobre a instancia
# PARM $1	ID do indice a recuperar dados
# Observacao	Responde com o texto cadastrado
#
rdOBSERVATION() {
	TMPR=$(grep "^${1}	" $PATH_EXEC/tabs/iAHx.tab)
	if [ $? -eq 0 ]; then
		echo "$TMPR" | awk -F "\t" '{ print $34 }'
	else
		false
	fi
}

# rdCONSULTA	Obtem o nome do indice fisico consultado
# PARM $1	ID do indice a recuperar dados
# Observacao	
#rdCONSULTA() {
#}

# rdTIMEHOMOL	Obtem a versao do iAHx aplicado
# PARM $1	ID do indice a recuperar dados
# Observacao	Responde com data e hora no formato YYYYMMDD hh:mm:ss
#
rdTIMEHOMOL() {
	TMPR=$(grep "^${1}	" $PATH_EXEC/tabs/iAHx.tab)
	if [ $? -eq 0 ]; then
		INDEXROOT=$(rdINDEXROOT $1)
		IDXSOLR=$(rdINDEX $1 | tr "-" "/")
		[ "$IDXSOLR" = "portal/org" ] && IDXSOLR="portalorg/main"
		SERVER=$(rdHOMOLOG $1)
		if [ -z "$SERVER" -o "$SERVER" = "." ]; then
			# Homologacao inexistente
			#echo "0000-00-00 00:00:00"
			# Homologacao no processamento
			ls -l --time-style full-iso $INDEXROOT/$IDXSOLR/data/index/segments.gen | awk '{ print $6 " " $7 }'
		else
			# Homologacao remota
			ssh transfer@$SERVER ls -l --time-style full-iso $INDEXROOT/$IDXSOLR/data/index/segments.gen | awk '{ print $6 " " $7 }'
		fi
	else
		false
	fi
}

# rdTIMEPROD	Obtem a versao do iAHx aplicado
# PARM $1	ID do indice a recuperar dados
# Observacao	Responde com data e hora no formato YYYYMMDD hh:mm:ss
#
rdTIMEPROD() {
	TMPR=$(grep "^${1}	" $PATH_EXEC/tabs/iAHx.tab)
	if [ $? -eq 0 ]; then
		INDEXROOT=$(rdINDEXROOT $1)
		IDXSOLR=$(rdINDEX $1 | tr "-" "/")
		[ "$IDXSOLR" = "portal/org" ] && IDXSOLR="portalorg/main"
		SERVER=$(rdPRODUCAO $1)
		if [ -z "$SERVER" -o "$SERVER" = "." ]; then
			# Producao inexistente
			echo "0000-00-00 00:00:00"
			# Producao no processamento
			#ls -l --time-style full-iso $INDEXROOT/$IDXSOLR/data/index/segments.gen | awk '{ print $6 " " $7 }'| cut -d "." -f "1"
		else
			# Producao remota
			ssh -p 8022 transfer@$SERVER "ls -l --time-style full-iso $INDEXROOT/$IDXSOLR/data/index/segments.gen" | awk '{ print $6 " " $7 }'| cut -d "." -f "1"
		fi
	else
		false
	fi
}

# rdBASES	Obtem lista de bases participantes do indice
# PARM $1	ID do indice
# PARM $2	Caminho
# Observacao	
#rdBASES() {
#}

# rdLIB		Obtem informacoes da library
# Observacao	
rdLIB() {
	T_LN=$(wc -l $PATH_EXEC/inc/iAHx2.inc | awk '{ print $1 }')
	I_LN=$(grep -n "<LIB_INFORMATION" $PATH_EXEC/inc/iAHx2.inc | tail -1 | cut -d ":" -f "1")
	LN_I=$(expr $T_LN - $I_LN)
	LN_F=$(expr $LN_I - 2)
	tail -n "$LN_I" $PATH_EXEC/inc/iAHx2.inc | head -$LN_F
}

# ========================================================================== #
cat > /dev/null <<LIB_INFORMATION
+----------------------------------------------------------------------------+
| Library: iAHx2.inc versao: 2.01                                            |
|                                                                            |
| 20140812 Adequacao ao novo layout da tabela iAHx.tab                       |
| 20140815 Implementacao das funcoes rdINFO e rdLIB                          |
| 20140828 Definicoes de periodicidade melhoradas                            |
|                                                                            |
| Relacao de funcoes:                                                        |
|  rdLIB          rdANYTHING     rdINDEX        rdINSTANCIA    rdDIRETORIO   |
|  rdINDEXFILE    rdINDEXROOT    rdTESTE        rdHOMOLOG      rdPRODUCAO    |
|  rdINBOX        rdLILDBIWEB    rdPORT         rdSERVER       rdSTATUS      |
|  rdPROCESSA     rdINFO         rdTYPE         rdPERIOD       rdALL         |
|  rdTODAS        rdPORTAL       rdURLOK        rdURL          rdOBJETO      |
|  rdHOMAPPL      rdVERSION      rdLANG         rdOBSERVATION  rdTIMEHOMOL   |
|  rdTIMEPROD                                                                |
+----------------------------------------------------------------------------+
LIB_INFORMATION

