# -------------------------------------------------------------------------- #

[ -f "antes.txt" ]  && rm -f antes.txt
[ -f "depois.txt" ] && rm -f depois.txt
[ -f "APAGAR.rol" ] && rm -f APAGAR.rol
[ $(ls *.md5 2> /dev/null) ] && rm -f *.md5
[ $(ls *.flg 2> /dev/null) ] && rm -f *.flg

