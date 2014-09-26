# ------------------------------------------------------------------------- #
# Texto de ajuda de utilizacao do comando

AJUDA_USO="
Uso: $TREXE [OPCOES] [<PARM1>]

Opcoes:
 -h, --help             Exibe este texto de ajuda e para a execucao
 -V, --version          Exibe a versao corrente do comando e para a execucao
 -c, --config NOMEARQU  Usa NOMEARQU para obter a configuracao do aplicativo
                         (uso de path eh permitido em NOMEARQU)
 -o, --output NOMEARQU  Usa NOMEARQU para relacionar instancias aprovadas no
                         teste, por padrao nao grava arquivo algum
 --changelog            Exibe o historico de mudancas
 -d, --debug NIVEL      Nivel de mensagens de depuracao [0..n]
 -s, --server NOME      Servidor de producao a utilizar no teste
                         (default db02dx)

PARAMETROS:
 PARM1  Nome (opcional) do arquivo com as URLs de teste, por DEFAULT vale
         \"testar.rol\" localizado no diretorio corrente, ou em ~/bin, ou
         \$PATH_PROC/tabs, ou \$PATH_PROC/bin, ou \$PATH_IAHX[, ou \$TABS]
"
#2345678901234567890123456789012345678901234567890123456789012345678901234567890
#        1         2         3         4         5         6         7         8

# ------------------------------------------------------------------------- #
# Texto de sintaxe do comando

SINTAXE="

Uso: $TREXE [OPCOES] [<PARM1>]

"

# ------------------------------------------------------------------------- #
# Ajustes de operacao por omissao

CONFIG="$PRGDR/$(echo $TREXE | sed 's/\.sh/\.cfg/')"

# ------------------------------------------------------------------------- #
# Tratamento das opcoes de linha de comando (qdo houver alguma)

while test -n "$1"
do
	case "$1" in

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

		--changelog)
		        TOTLN=$(wc -l $0 | awk '{ print $1 }')
			INILN=$(grep -n "<SPICEDHAM" $0 | tail -1 | cut -d ":" -f "1")
			LINHAI=$(expr $TOTLN - $INILN)
			LINHAF=$(expr $LINHAI - 2)
			echo -e -n "\n$TREXE - "
			tail -$LINHAI $0 | head -$LINHAF
			echo
			exit 0
		;;

		-c | --config)
			shift
			CONFIG="$1"
			if [ ! -s "$CONFIG" ]; then
				echo "Arquivo de configuracao $CONFIG nao localizado ou vazio"
				exit 1
			fi
		;;

		-o | --output)
			shift
			OUT_F="$1"
		;;

		-s | --server)
			shift
			SERVER="$1"
			[ -z "$SERVER" ] && SERVER="db02dx"
			echo "[tiAHx]            - Testa contra o servidor de producao: $SERVER"
		;;

		-d | --debug)
			shift
			DEBUG="$1"
		;;

		*)
			if [ $(expr index $1 "-") -eq 0 ]; then
				if test -z "$PARM1"; then PARM1=$1; shift; continue; fi
			        if test -z "$PARM2"; then PARM2=$1; shift; continue; fi
				if test -z "$PARM3"; then PARM3=$1; shift; continue; fi
				if test -z "$PARM4"; then PARM4=$1; shift; continue; fi
				if test -z "$PARM5"; then PARM5=$1; shift; continue; fi
				if test -z "$PARM6"; then PARM6=$1; shift; continue; fi
				if test -z "$PARM7"; then PARM7=$1; shift; continue; fi
				if test -z "$PARM8"; then PARM8=$1; shift; continue; fi
				if test -z "$PARM9"; then PARM9=$1; shift; continue; fi
			else
				echo "Opcao nao valida. ($1)"
			fi
		;;

	esac
	shift
done
# Assume valores default para arquivo de saida e de entrada
[ -z "$PARM1" ] && PARM1=transfere.rol;         # Arquivo de saida com a lista de instancias a transferir
[ -z "$PARM2" ] && PARM2=testar.rol;            # Arquivos de entrada com as URL a testar

QUERY_STRING='/select/?q=*:*&rows=0'

# ------------------------------------------------------------------------- #
# Le configuracao do arquivo se ele existir

if [ -s "$CONFIG" ]; then

	# Valores sao opcionais no arquivo de configuracao
	TEMP=$(PegaValor QUERY_STR)
	echo "TEMP vale : $TEMP"
	[ -n "$TEMP" ] && QUERY_STRING=$TEMP

fi

# Para DEBUG assume valor DEFAULT antecipadamente
isNumber $DEBUG
[ $? -ne 0 ]         && DEBUG="0"
[ "$DEBUG" -ne "0" ] && PARMD="-d $DEBUG"
# -------------------------------------------------------------------------- #
# Avalia nivel de depuracao
[ $(($DEBUG & $_BIT3_)) -ne 0 ] && set -v
[ $(($DEBUG & $_BIT4_)) -ne 0 ] && set -x


