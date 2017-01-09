#!/bin/bash
#
# Author : Ben Souverbie
# Date   : 2017-01-09
# Feel free to take it, change it to your taste or whatever :)

ORDER=$1
if [ -z $ORDER ]
then
	ORDER="false"
fi

echo "Listing the displays"
LDISP=$(xrandr | grep -v disconnected | grep connected | cut -d' ' -f1)
for DISP in $LDISP
do
	RES=$(xrandr | grep -v disconnected | grep -A1 $DISP | grep -v connected | awk '{print $1}')
	PW=$(echo $RES | cut -d'x' -f1)
	PH=$(echo $RES | cut -d'x' -f2)
	W=$(xrandr | grep DP-0 | awk '{print $13}')
	W=${W:0:-2}
	PDENSITY=$(($PW/($W/26)))
	W=$(($W*$W))
	H=$(xrandr | grep DP-0 | awk '{print $15}')
	H=${H:0:-2}
	H=$(($H*$H))
	DIAG=$(($W+$H))
	DIAG=$(echo "sqrt($DIAG)" | bc)
	DIAG=$(($DIAG/26))
	echo "+ Display $DISP :"
	echo "++ Size          : ${DIAG}\" in diagonal"
	echo "++ Resolution    : $RES"
	echo "++ Pixel density : $PDENSITY px/inch"

	if [ $PDENSITY -lt 100 ]
	then
		echo "This screen is not HiDPI - nothing to do"
	else
		if [ $ORDER = "reset" ]
		then
			echo "Set the display scaling to 1"
			gsettings set org.gnome.desktop.interface scaling-factor 1

			echo "Zoom to native 1x"
			ZOUT="1"
			echo "+ Zoom out on display $DISP by a factor of $ZOUT"
			xrandr --output $DISP --scale ${ZOUT}x${ZOUT}

			RENDER=$(xrandr | grep $DISP | awk '{print $4}' | cut -d'+' -f1)
			echo "+ Rendering resolution set to $RENDER"

			echo "+ Set the panning so the cursor can go all over the screen"
			xrandr --output $DISP --panning $RENDER
		elif [ $ORDER = "optimal" ]
		then
			echo "Set the display scaling to 2"
			gsettings set org.gnome.desktop.interface scaling-factor 2
			VPDENSITY=$(($PDENSITY/2))
			echo "+ Virtual pixel density is now $VPDENSITY"

			echo "Zoom out to a confortable virtual resolution (arround 92 px/inch)"
			ZOUT=$((920/$VPDENSITY))
			ZOUT=$(sed 's/.\{1\}$/.&/' <<< "$ZOUT")
			echo "+ Zoom out on display $DISP by a factor of $ZOUT"
			xrandr --output $DISP --scale ${ZOUT}x${ZOUT}

			RENDER=$(xrandr | grep $DISP | awk '{print $4}' | cut -d'+' -f1)
			echo "+ Rendering resolution set to $RENDER and scaled down to $RES"

			echo "+ Set the panning so the cursor can go all over the screen"
			xrandr --output $DISP --panning $RENDER
		fi
	fi
done
