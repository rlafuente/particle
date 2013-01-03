#!/bin/sh

  ###########
 ## ISSUES ##
##########
#
# REMAKE all the functions so they accept arguments instead of calling existing vars
# REMAKE THE SCRIPT so as to demand all parameters in the command line
# $SIZE needs to be user-defined
#
############

## VARIABLE DESCRIPTION ##
#
# $WIDTH and $HEIGHT 
# the number of columns and rows of the final image
#
# $PTOTAL
# the number of particles in the final image = number of pixels of the resized image
# = number of lines in the image text file = $WIDTH * $HEIGHT (it always comes
# together :)
# 
# $OUTPUTWIDTH and $OUTPUTHEIGHT 
# the actual dimensions of the final image
#
# $SIZE 
# the scaling factor for the final image
# e.g., if this is 20, then each particle will be 20 px tall and 20 px wide
#

OUTPUTTEXTFILE=_input.txt
SIZE=16

importimage () { # resize the source image, output it as text and read its dimensions

	_INPUTFILE=$1
	_WIDTH=$2

	# take source image, convert to MIFF and output in text format
	convert $_INPUTFILE miff:- >| input.mif
	convert input.mif -colorspace RGB -resize ${_WIDTH}x${_WIDTH} -depth 8 $OUTPUTTEXTFILE 
	
	# remove the header of the text output
	cat $OUTPUTTEXTFILE | sed '1,1d' > $OUTPUTTEXTFILE 
	
	# FIX THIS: clunky method to echo the line count to a variable - grep the numbers from wc's standard output
	PTOTAL=`wc -l $OUTPUTTEXTFILE 2> /dev/null | awk '{ print $1 }'` 
	if [ -z $PTOTAL ]
		then
		echo Something went wrong, try again
		exit 
	fi
	
	# Calculate the resized image height by dividing the total number of pixels (= lines in the text file) by width
	_HEIGHT=$(($PTOTAL / $_WIDTH)) 		
	HEIGHT=$_HEIGHT	
	
	# Output also as an image, just for checking how it looks
	convert $_INPUTFILE -colorspace RGB -resize ${_WIDTH}x${_WIDTH} -depth 8 _inputrgb.png 
	
	# WE WILL ALSO NEED an HSL output so we can read each pixel's brightness
	# convert $INPUTFILE -colorspace HSL -resize ${WIDTH}x${WIDTH} -depth 8 _inputhsl.png 
	
	# Echo the values just to make sure that the vars are okay; remove this in the final version?
	echo width: $_WIDTH
	echo height: $_HEIGHT
	echo total pixels: $PTOTAL
}

createimage () { # Create the final image from the values that were output by importimage()

	OUTPUTWIDTH=$(($WIDTH * $SIZE))		
	OUTPUTHEIGHT=$(($HEIGHT * $SIZE)) 
	
	# Maybe some of these commands would be more efficient with awk?
	cat $OUTPUTTEXTFILE | \
		# the input file reads like
		# x,y (r,g,b) #hex
		#
		# we start by removing the RGB values, since we'll work with the hex ones
	sed 's/([0-9, ]*)//' | \
	
	sed 's/\://' | \
	sed 's/\#//' | \
	sed 's/.*/\.\/drawparticle.sh &/' | \
		# IM outputs black as 'black' instead of the hex value, so let's fix that
	sed 's/black/000000/' | \
		# and finally, take out the commas
	sed 's/\,/ /' >| \
	output.txt
	echo Finished reading pixels, creating image
	
	#FIX THIS
	XCENTER=$(($SIZE / 2))
	YCENTER=$XCENTER
	
	bash output.txt
	bash glue.sh $OUTPUTWIDTH $OUTPUTHEIGHT $SIZE $WIDTH $HEIGHT

}

getcolour () { # get target pixel's colour from a text file and saves it to $particlecolour- NEEDS REDOING
	
	$OUTPUTTEXTFILE=$1
	$PN=$2	
	
	# read the pixel in line N of the input text file ($6 is the hex value)
	PCOLOUR=`sed -n "$PN"'{p;q;}' $OUTPUTTEXTFILE | awk '{ print $6 }'`
	
}

cleanup () {
# rm _*.txt 					# remove the text files
rm _particle* 		# remove the individual particle files
echo Done
}

launch () {
	
	# Check if a filename was entered
	INPUTFILE=${1:?Filename not specified or not found, quitting}
		
	# $WIDTH is the desired width (columns) of the final image
	read -p "Number of columns? (Default: 24)" RWIDTH
	WIDTH=${RWIDTH:-24}
			
	# AND WE'LL ALSO need a way to prevent those nasty divide by zero events that pop up sometimes
	
	importimage $INPUTFILE $WIDTH
	createimage 
	
	cleanup
	
}

## COMMANDS ##

launch $1
