#!/bin/bash

#    plot.sh 
#    a bash script to plot graph with data recorded by owm.sh (pression and temperature)
#    Copyright (C) 2017 - D4void - d4void@orange.fr
#    https://github.com/D4void/OWM
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

DATE=$(date --date="+12 hour" +"%s")
DATE1WAGO=$(date --date="1 week ago" +"%s")
DATAFILE="$1"
GRAPH1="$2"
GRAPH2="$3"

gnuplot <<EOF
set terminal png font "arial,10"
set output "$GRAPH1"
unset key
set title "Evolution température et pression atmosphérique"
set xlabel "date"
set style line 1 lc rgb "red" lw 2
set style line 2 lc rgb "blue" lw 2
set yzeroaxis ls 1 lw 2
set y2zeroaxis ls 2 lw 2
set ylabel "pression atmosphérique (hPa)" tc ls 1
set y2label "température (°C)" tc ls 2
set grid
set xdata time
set timefmt "%s"
set xtics 86400
set format x "%d/%m"
set xrange ["$DATE1WAGO":"$DATE"]
set ytics nomirror tc ls 1
set y2tics nomirror tc ls 2
#set yrange [960:1080]
#set y2range [-10:30]
plot "$DATAFILE" using 1:2 title "pression atmosphérique" with lines ls 1, "$DATAFILE" using 1:3 title "température" with lines ls 2 axes x1y2
EOF


gnuplot <<EOF
set terminal png enhanced size 110,80 background "light-grey" font "arial,5"
set output "$GRAPH2"
unset key
set style line 1 lc rgb "red" lw 1
set style line 2 lc rgb "blue" lw 1
set style line 3 lc rgb "white" lw 1 pt 1
set xdata time
set timefmt "%s"
set xtics 86400
set ytics 10
set y2tics 5
set format x "%d"
set margin 6,3,2,1
set xrange ["$DATE1WAGO":"$DATE"]
set ytics nomirror tc ls 1
set y2tics nomirror tc ls 2
plot "$DATAFILE" using 1:2 with lines ls 1, "$DATAFILE" using 1:3 with lines ls 2 axes x1y2, 0 ls 2 axes x1y2
EOF

exit 0
