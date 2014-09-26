# -------------------------------------------------------------------------- #
# Anota hora de termino e calcula duracao em segundos e humana
[ "$N_DEB" != "0" ] && echo " = = =>  -Procedimentos terminados"
HRFIM=$(date '+%Y%m%d %H:%M:%S');				# Hora de fim de execucao no formato YYYYMMDD hh:mm:ss
HFINI=$(date '+%s');						# Hora de fim de execucao em segundos desde 1/1/1970
TPROC=$(expr $HFINI - $HINIC);					# Tempo de processamento em segundos
SRPROC=$(expr $TPROC % 3600);					# Resto de tempo em segundos
HTPROC=$(expr $(expr $TPROC - $SRPROC) / 3600);			# Horas de processamento
STPROC=$(expr $SRPROC % 60);					# Segundos de processamento
MTPROC=$(expr $(expr $SRPROC - $STPROC) / 60);			# Minutos de processamento
THUMAN=$(printf "%02d:%02d:%02d" $HTPROC $MTPROC $STPROC);	# Horas : Minutos : Segundos de processamento
echo "Tempo de execucao de $TREXE em $HRINI: $TPROC [s] ou $THUMAN"
echo "[TIME-STAMP] $HRFIM [:FIM:] $TREXE $LCORI"

unset	HRINI	HRFIM	HINIC	HFINI
unset	TPROC	HTPROC	MTPROC	STPROC	SRPTOC	THUMAN
unset	_DIA_	_MES_	_ANO_	DTFJL
unset	CURRD	TREXE	PRGDR	LCORI

