# -------------------------------------------------------------------------- #
if [ $N_DEB -ne 0 ]; then
	echo "==============================="
	echo "$PRGDR/$TREXE $LCORI"
	echo "= DISPLAY DE VALORES INTERNOS ="
	echo "==============================="

	test -n "$PARM1" && echo "      PARM1 = $PARM1"
	test -n "$PARM2" && echo "      PARM2 = $PARM2"
	test -n "$PARM3" && echo "      PARM3 = $PARM3"
	test -n "$PARM4" && echo "      PARM4 = $PARM4"
	test -n "$PARM5" && echo "      PARM5 = $PARM5"
	test -n "$PARM6" && echo "      PARM6 = $PARM6"
	test -n "$PARM7" && echo "      PARM7 = $PARM7"
	test -n "$PARM8" && echo "      PARM8 = $PARM8"
	test -n "$PARM9" && echo "      PARM9 = $PARM9"
	echo
	echo "      PARMD = $PARMD"
	echo "      DEBUG = $DEBUG"
	echo "DEBUG level = $N_DEB"
	echo "Fake operac = $FAKE"
	echo "      PRGDR = $PRGDR"
	echo "      TREXE = $TREXE"
	echo "      LCORI = $LCORI"
	echo "current dir = $CURRD"
	echo "      IDIDX = $IDIDX"
	echo "      INDEX = $INDEX"
	echo "      INSTA = $INSTA"
	echo "       home = $DIRET"
	[ ${#HOMOL}  -gt 0 ] && echo "Homologacao = $HOMOL"
	[ ${#PRODU}  -gt 0 ] && echo "   Producao = $PRODU"
	[ ${#COMUM}  -gt 0 ] && echo "   RAIZ IDX = $COMUM"
	[ ${#I_BOX}  -gt 0 ] && echo "  Input BOX = $I_BOX"
	[ ${#B_EXT}  -gt 0 ] && echo "B em LILDBI = $B_EXT"
	echo "  PATH_DATA = $PATH_DATA"
	[ ${#BASE}   -gt 0 ] && echo "       BASE = $BASE"
	[ ${#NOXMT}  -gt 0 ] && echo "      NOXMT = $NOXMT   OPC_XMT = $OPC_XMT"
	[ ${#NOERRO} -gt 0 ] && echo "     NOERRO = $NOERRO  OPC_ERRO = $OPC_ERRO"
	[ ${#NOINCR} -gt 0 ] && echo "     NOINCR = $NOINCR  OPC_FULL = $OPC_FULL"
	[ ${#NODATA} -gt 0 ] && echo "     NODATA = $NODATA  OPC_DATA = $OPC_DATA"
	[ ${#NOCOMM} -gt 0 ] && echo "     NOCOMM = $NOCOMM  OPC_COMM = $OPC_COMM"
	echo "==============================="
	[ ${#DESTINO} -gt 0 ] && echo "    DESTINO = $DESTINO"
fi

