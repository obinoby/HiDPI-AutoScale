#!/bin/bash
#
# @Author: Ben Souverbie <obinoby>
# @Date:   2017-01-09T21:24:34+01:00
# @Last modified by:   obinoby
# @Last modified time: 2017-01-15T21:31:48+01:00
#
# Feel free to take it, change it to your taste or whatever :)
#
# The principle :
# - Gnome is used to scale up the display by multiplying by 2 in both directions
# -> On some screen that provide a too big zoom. Sharp yes, but way too big.
# - So we use xrandr to render the display on a much higher resolution than the screen is capable of
# -> And then we scale it down to the native resolution of the screen
#
# The folder ~/.gnomescale contain one file per display containing the specific setting of that display
# After the first launch a file is created for each display and is used te reconfigure the display any time.
# The file is readed only if no new configuration is specified.
#
# All screens are to get the same virtual dpi so that display is consistent from screen to screen.
#
# Options :
# - reset : Set the screen back to native resolution without scaling
# - optimal : Set the display to a confortable 96dpi equivalent screen
# - 80 : Set the display to a 80dpi equivalent (you can choose any value)

ACTION=$1
if [ -z $ACTION ]
then
	#ACTION="false"
	ISSET=0
fi

CONFDIR="$HOME/.gnomescale"
mkdir -p $CONFDIR

# Check if the given parameter is an integer or not
re='^[0-9]+$'
if ! [[ $ACTION =~ $re ]]
then
	if [[ "$ACTION" != "reset" ]]
	then
		# Default value for optimal
		DDPI=96
		ACTION="optimal"
		ISSET=0
	else
		ISSET=2
	fi
else
	DDPI=$ACTION
	ACTION="optimal"
	ISSET=1
fi

#if [ $ACTION != "false" ]
#then
	echo "Listing the displays"
	LDISP=$(xrandr | grep -v disconnected | grep connected | cut -d' ' -f1)
	#Loop on every active display
	for DISP in $LDISP
	do
		#Get the native screen resolution in that form 1024x768
		RES=$(xrandr | grep -v disconnected | grep -A1 $DISP | grep -v connected | awk '{print $1}')
		#Separate the width and height values
		PW=$(echo $RES | cut -d'x' -f1)
		PH=$(echo $RES | cut -d'x' -f2)
		#Get the screen width in milimeters in that form 533mm
		W=$(xrandr | grep $DISP | awk '{print $13}')
		#Remove the "mm" from the string
		W=${W:0:-2}
		#Calculate the horizotal pixel density and convert from milimeters to inches
		#The result is like 121 pixel/inch
		PDENSITY=$(($PW/($W/26)))
		#Calculate the diagonal of the screen using Pythagore law (w²+h²)=d²
		#First square the width
		W=$(($W*$W))
		#Get the screen height in milimeters
		H=$(xrandr | grep $DISP | awk '{print $15}')
		#Remove the "mm" from the string
		H=${H:0:-2}
		#Then square the height
		H=$(($H*$H))
		#Sum them
		DIAG=$(($W+$H))
		#Calculate the square root
		DIAG=$(echo "sqrt($DIAG)" | bc)
		#And convert in inches
		DIAG=$(($DIAG/26))
		#Display screen information so that the user can anderstand what is happening
		echo "+ Display $DISP :"
		echo "++ Size          : ${DIAG}\" in diagonal"
		echo "++ Resolution    : $RES"
		echo "++ Pixel density : $PDENSITY px/inch"

		# Check if that screen already have a saved configuration
		if [ -f $CONFDIR/${DISP}_${PDENSITY} ] && [ $ISSET -eq 0 ]
		then
			echo "++ That screen already have a saved configuration"
			echo "++ and no new specific configuration is asked"
			INFO=$(cat $CONFDIR/${DISP}_${PDENSITY})
			if [[ "$INFO" == "reset" ]]
			then
				echo "++ --> using a 1x ratio"
				ACTION="reset"
			else
				DPI=$INFO
				echo "++ --> using it : $DPI dpi"
			fi
		else
			DPI=$DDPI
		fi

		# Before scaling let be sure that the screen is HiDPI
		# The arbitrary value here is not_HiDPI<100dpi<=HiDPI
		if [ $PDENSITY -lt 100 ]
		then
			echo "This screen is not HiDPI - nothing to do"
		else
			case $ACTION in
				"reset")
					# Set that display to native resolution without scaling
					echo "Set the display scaling to 1"
					gsettings set org.gnome.desktop.interface scaling-factor 1
					OUT=$?
					case $OUT in
						0)
							# Setings OK ; going to next setting
							;;
						*)
							# Problem when applying this setting
							echo "Problem when applying this setting : exiting"
							exit 1
							;;
					esac

					echo "Zoom to native 1x"
					ZOUT="1"
					echo "+ Zoom out on display $DISP by a factor of $ZOUT"
					xrandr --output $DISP --scale ${ZOUT}x${ZOUT}
					OUT=$?
					case $OUT in
						0)
							# Setings OK ; going to next setting
							;;
						*)
							# Problem when applying this setting
							echo "Problem when applying this setting : exiting"
							exit 2
							;;
					esac

					RENDER=$(xrandr | grep $DISP | awk '{print $4}' | cut -d'+' -f1)
					OUT=$?
					case $OUT in
						0)
							# Setings OK ; going to next setting
							;;
						*)
							# Problem when applying this setting
							echo "Problem when applying this setting : exiting"
							exit 3
							;;
					esac
					echo "+ Rendering resolution set to $RENDER"

					echo "+ Set the panning so the cursor can go all over the screen"
					xrandr --output $DISP --panning $RENDER
					OUT=$?
					case $OUT in
						0)
							# Setings OK ; going to next setting
							;;
						*)
							# Problem when applying this setting
							echo "Problem when applying this setting : exiting"
							exit 4
							;;
					esac

					# We did someting so update the conf file
					echo "reset" > $CONFDIR/${DISP}_${PDENSITY}
				;;
				"optimal")
					# Set that display to scale that is like the standard 96dpi ($DPI=96)
					# or the given wanted dpi
					echo "Set the display scaling to 2"
					gsettings set org.gnome.desktop.interface scaling-factor 2
					OUT=$?
					case $OUT in
						0)
							# Setings OK ; going to next setting
							;;
						*)
							# Problem when applying this setting
							echo "Problem when applying this setting : exiting"
							exit 1
							;;
					esac
					VPDENSITY=$(($PDENSITY/2))
					echo "+ Virtual pixel density is now $VPDENSITY"

					echo "Zoom out to a confortable virtual resolution (arround $DPI px/inch)"
					#Calculate the scaling factor for zooming out
					#BASH does not support real numbers so by multiplying the dpi by ten before
					#and dividing the result by ten (by placing a dot one char before end)
					#we get a better value
					TDPI=$(($DPI*10))
					ZOUT=$(($TDPI/$VPDENSITY))
					ZOUT=$(sed 's/.\{1\}$/.&/' <<< "$ZOUT")
					echo "+ Zoom out on display $DISP by a factor of $ZOUT"
					xrandr --output $DISP --scale ${ZOUT}x${ZOUT}
					OUT=$?
					case $OUT in
						0)
							# Setings OK ; going to next setting
							;;
						*)
							# Problem when applying this setting
							echo "Problem when applying this setting : exiting"
							exit 2
							;;
					esac

					RENDER=$(xrandr | grep $DISP | awk '{print $4}' | cut -d'+' -f1)
					OUT=$?
					case $OUT in
						0)
							# Setings OK ; going to next setting
							;;
						*)
							# Problem when applying this setting
							echo "Problem when applying this setting : exiting"
							exit 3
							;;
					esac
					echo "+ Rendering resolution set to $RENDER and scaled down to $RES"

					echo "+ Set the panning so the cursor can go all over the screen"
					xrandr --output $DISP --panning $RENDER
					OUT=$?
					case $OUT in
						0)
							# Setings OK ; going to next setting
							;;
						*)
							# Problem when applying this setting
							echo "Problem when applying this setting : exiting"
							exit 4
							;;
					esac

					# We did someting so update the conf file
					echo "$DPI" > $CONFDIR/${DISP}_${PDENSITY}
				;;
				*)
					echo "Uncknown parameter - abort"
					exit 1
				;;
			esac
		fi
	done
#fi

exit 0
