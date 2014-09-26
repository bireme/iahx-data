# -------------------------------------------------------------------------- #
# Anota dados de inicio de execucao
CURRD=$(pwd);				# Diretorio corrente
HINIC=$(date '+%s');			# Hora de inicio em segundos desde 1/1/1970
HRINI=$(date '+%Y%m%d %H:%M:%S');	# Hora de inicio no formato YYYYmmdd hh:mm:ss
_DOW_=$(date '+%u');			# dia da semana de 0(domingo) a 6(sabado)
_DIA_=$(date '+%d');			# Dia corrente (dd)
_MES_=$(date '+%m');			# Mes corrente (mm)
_ANO_=$(date '+%Y');			# Ano corrente (YYYY)
TREXE=$(basename $0);			# Denominacao do programa em execucao
PRGDR=$(dirname $0);			# Path para o programa em execucao
LCORI=$*;				# Linha de comando original da chamada
DTISO=${_ANO_}${_MES_}${_DIA_};		# Data calendario no formato YYYYMMDD
N_DEB=0

# ========================================================================== #
# Funcoes de uso geral podem ser colocadas aqui
# ========================================================================== #

# isNumber	Determina se o parametro eh (TRUE) ou nao (FALSE) numerico
# -------------------------------------------------------------------------- #
# PARM $1	String a verificar se eh ou nao numerica
# Observ.	Baseado no fato que `-eq` soh funciona bem com numeros
#		 testa se o parametro eh numericamente igual a asi proprio
#		 descarta a eventual mensagem de erro (/dev/null) e
#		 devolve o resultado do proprio teste
#
isNumber() {
	[ "$1" -eq "$1" ] 2> /dev/null
	return $?
}

# rdConfig	Le o item de configuracao indicado no parametro
# -------------------------------------------------------------------------- #
# PARM $1	Item de configuracao a ser lido
# Observ.	O arquivo a ser lido eh o contido na variavel CONFIG com
#		 regras de caminho (corrente/relativo/absoluto) do S.O.
#
rdConfig () {
        if [ -f "$CONFIG" ]; then
                grep "^$1" $CONFIG > /dev/null
                RETORNO=$?
                if [ $RETORNO -eq 0 ]; then
                        RETORNO=$(grep "^$1" $CONFIG | tail -n "1" | cut -d "=" -f "2")
                        echo $RETORNO
                else
                        false
                fi
        else
                false
        fi
        return
}

# chkError	
# -------------------------------------------------------------------------- #
# PARM $1	Mensagem de erro a ser exibida no STDOUT
# Observ.	
#
chkError () {
        LSTERR=$?
        [ ${LSTERR} -ne 0 ] && echo "fatal: ${1} (${LSTERR})" && exit ${LSTERR}
}





# ========================================================================== #
echo "[TIME-STAMP] $HRINI [:INI:] $TREXE $LCORI"

