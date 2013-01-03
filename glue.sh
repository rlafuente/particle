#!/bin/sh

# glue.sh
# Combines all particles available into one big, final image

# By itself, it receives the particle coordinates, final image size and particle ID
# and composites it on the final image.

# USAGE: glue.sh [x-origin] [y-origin] [size] [particlenumber]


OUTPUTWIDTH=$1
OUTPUTHEIGHT=$2
SIZE=$3
WIDTH=$4
HEIGHT=$5

convert -size ${OUTPUTWIDTH}x${OUTPUTHEIGHT} xc:white -fill white -draw "rectangle 0,0 1,1" output.png

PN=1

for (( ROWS = 0; ROWS < $(($HEIGHT)); ROWS++ ))
 do
 	echo Parsing row $ROWS
 	for (( COLUMNS = 0; COLUMNS < $(($WIDTH)); COLUMNS++ ))
 	do
 	
 		# determine the coordinates of the next object
 		XPOS=$(($COLUMNS * $SIZE))
 		YPOS=$(($ROWS * $SIZE))
 		
 		# glue all the bits together
		convert output.png _particle${PN}.mif -geometry +${XPOS}+${YPOS} -composite output.png
 		# update the line counting var
 		PN=$(($PN	+ 1))		
 		
 	done
 done




