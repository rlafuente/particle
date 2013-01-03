#!/bin/sh
#
# drawparticle.sh
#
# drawparticle receives two values - size (in pixels) and colour (in RGB 
# hex notation, eg #FF5500) and creates a particle with that size and colour.
#
# USAGE: drawparticle [size] [colour]
#

SIZE=$1
COLOUR=#${2}
ID=$(( `ls _particle* 2> /dev/null | wc -l` + 1 ))

XCENTER=$(($SIZE / 2))
YCENTER=$XCENTER

convert -size ${SIZE}x${SIZE} xc:white \
-fill $COLOUR \
-draw "circle ${XCENTER},${YCENTER} 1,${YCENTER}" \
miff:- >| _particle${ID}.mif
