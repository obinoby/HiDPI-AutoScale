<!--
@Author: Ben Souverbie <obinoby>
@Date:   2017-01-09T22:43:37+01:00
@Last modified by:   obinoby
@Last modified time: 2017-01-09T22:43:52+01:00
-->



# HiDPI-AutoScale

The principle :
- Gnome is used to scale up the display by multiplying by 2 in both directions
-> On some screen that provide a too big zoom. Sharp yes, but way too big.
- So we use xrandr to render the display on a much higher resolution than the screen is capable of
-> And then we scale it down to the native resolution of the screen

Options :
- reset : Set the screen back to native resolution without scaling
- optimal : Set the display to a confortable 96dpi equivalent screen
- 80 : Set the display to a 80dpi equivalent (you can choose any value)
