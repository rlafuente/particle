#!/bin/sh

# particle.sh

# VARIABLE DESCRIPTION
# What is what around here
###########################
#
# $WIDTH and $HEIGHT 
# the number of columns and rows of the final image
#
# $PTOTAL
# the number of particles in the final image = number of pixels of the resized image
# = number of lines in the image text file = $WIDTH * $HEIGHT (it always comes
# together :)
# 
# $PN
# used as a counter in loops to keep track which particle we're working on
#
# $SIZE 
# each particle's size in pixels
# 
# $OUTPUTWIDTH and $OUTPUTHEIGHT (image output only)
# the actual dimensions of the final image



# HTML file output
HTMLFILE="index.html"
# Image file output
IMAGEFILE=output.png

# Particle size (in pixels)
SIZE=16
# Background colour (HTML only for now)
# BACKGROUNDCOLOUR="white"

# Temporary text file locations

# Generated textfile for particle reference
TABLEFILE=_particletable.txt
# RGB text output
RGBTEXTFILE=_input.txt
# HSL text output
HSLTEXTFILE=_inputhsl.txt

# Particle set dir
PARTICLESETDIR='../particlesets/targets/'

importimage () { 

# resize the source image, output it as text and read its dimensions

	INPUTFILE=$1
	WIDTH=$2

	# take source image, convert to MIFF and output in text format (RGB and HSL)
	
	#CHANGING HERE
#	convert $INPUTFILE miff:- >| _input.mif
	
	# watch for negate
		convert input.jpg -colorspace RGB -negate -resize ${WIDTH}x -depth 8 $RGBTEXTFILE 	
	convert input.jpg -colorspace HSL -negate -resize ${WIDTH}x -depth 8 $HSLTEXTFILE 		
	
			convert input.jpg -colorspace RGB -resize ${WIDTH}x -depth 8 _rgb.jpg 	
	convert input.jpg -colorspace HSL -resize ${WIDTH}x -depth 8 _hsl.jpg 		
	
	
	# Determine the number of lines in the text file (subtract 1 because of the header)
#	PTOTAL=`wc -l $RGBTEXTFILE 2> /dev/null | awk '{ print $1 - 1 }'` 
	# CHANGING HERE
	PTOTAL=`wc -l $RGBTEXTFILE | awk '{ print $1 - 1 }'` 	
	
	
	# Way to fix a small bug that for some reason makes $PTOTAL 0 sometimes
	if [ -z $PTOTAL ]
		then
		echo Something went wrong; try again alstublieft
		exit 
	fi
	
	# Calculate the resized image height by dividing the total number of pixels by width	
	HEIGHT=$(($PTOTAL / $WIDTH))
	
	# Echo the values just to make sure that the vars are okay 
	echo height: $HEIGHT
	echo total pixels: $PTOTAL
	
	echo Creating particle table	
	cat $HSLTEXTFILE | \
	sed '1,1d' | \
	sed 's/(//;s/)//' | \
	awk -F, '{ print $4 }' | \
	awk '{ print $1 }' | \
	awk '{ print int($1 / 32) }' >| \
	$TABLEFILE
}

scissors() {

COUNT=0
for ID in `ls ${PARTICLESETDIR}`
	do
			#fix this, not futureproof
		convert ${PARTICLESETDIR}${ID} \
	 	-resize ${SIZE}x${SIZE} \
	 _00${COUNT}.png
	 COUNT=$(($COUNT + 1))
	done

}

createhtmlfile() {

	echo Generating HTML file
	
	# remove any previous output
 	rm $HTMLFILE

	# create XHTML header and CSS parts
	echo '<?xml version="1.0" encoding="utf-8"?><!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"><html xmlns="http://www.w3.org/1999/xhtml">' >> $HTMLFILE
	echo '<head><title>Particle</title><meta http-equiv="Content-Type" content="text/html; charset=utf-8" /><style type="text/css"><!-- body {margin:0; padding:0;background-color: white } --></style></head>' >> $HTMLFILE
	echo "<body>" >> $HTMLFILE

	PN=1

	# and now, one by one, create the markup for each particle
	for (( ROWS = 0; ROWS < $(($HEIGHT)); ROWS++ ))
		do
		for (( COLUMNS = 0; COLUMNS < $(($WIDTH)); COLUMNS++ ))
			do
				
				# lookup the table with the particle values
				ID=`sed ${PN}q\;d $TABLEFILE`
				PARTICLEFILE=\"_00${ID}.png\"	
			# create the <img> tag for that particle
				echo "<img src="${PARTICLEFILE}" />" >> $HTMLFILE
				# update the line counting var
				PN=$(($PN + 1))		
		done
		# line break at the end of each row
		echo "<br />" >> $HTMLFILE 
	done

	# include closing tags
	echo "</body>" >> $HTMLFILE
	echo "</html>" >> $HTMLFILE
	
	# remove the line breaks (or else images will have spacing between them)
	cat $HTMLFILE > _temp.html
	rm $HTMLFILE
	cat _temp.html | tr -d "\n" > $HTMLFILE
	echo Yay!

}

createmonoimage() {

# determine the output's dimensions
OUTPUTWIDTH=$(($WIDTH * $SIZE))		
OUTPUTHEIGHT=$(($HEIGHT * $SIZE))   

# set up a counter to know where in the image we are
PN=1

# prepare the background file
convert -size ${OUTPUTWIDTH}x${OUTPUTHEIGHT} xc:white $IMAGEFILE

# and now, one by one, overlay each particle
for (( ROWS = 0; ROWS < $(($HEIGHT)); ROWS++ ))
 do
 	echo Parsing row $ROWS
 	for (( COLUMNS = 0; COLUMNS < $(($WIDTH)); COLUMNS++ ))
 	do
 		# determine the coordinates of the next particle
 		XPOS=$(($COLUMNS * $SIZE))
 		YPOS=$(($ROWS * $SIZE))

		# lookup the table to see which particle should be applied
		ID=`sed ${PN}q\;d $TABLEFILE`
		PARTICLEFILE=_00${ID}.png
			
		# apply the particle to the background file
		convert $IMAGEFILE $PARTICLEFILE -geometry +${XPOS}+${YPOS} -composite $IMAGEFILE

		# update the line counting var
 		PN=$(($PN + 1))		
 		
 done
done

echo Yay!

}

cleanup () {
	# rm _*.txt 					# remove the text files
	rm _particle* 		# remove the individual particle files
	rm *.mif
}


launch () {
	
	# Check which mode to run
	MODE=${1:?Wrong or missing mode (available: bitmap, html)}
	
		# Check if a filename was entered
	INPUTFILE=${2:?Filename not specified or not found, quitting}
		
	# $WIDTH is the desired width (columns) of the final image
	read -p "Number of columns? (Default: 24)" _WIDTH
	read -p "Particle size? (in pixels; Default: 16)" _SIZE
	WIDTH=${_WIDTH:-24}
	SIZE=${_SIZE:-16}
			
	# importimage $INPUTFILE $WIDTH
	importimage $INPUTFILE $WIDTH	
	scissors
	# createimage	
	createhtmlfile
	
	cleanup
}

## COMMANDS ##

launch $1 $2
