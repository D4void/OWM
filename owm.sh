#!/bin/bash 

#    owm.sh 
#    a bash script to download and parse OpenWeatherMap current weather and hourly forecast
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

version="0.1"

##########################################################################################################################

# Settings

APIKEY=""
LOCATIONID=""
# Language supported by OpenWeatherMap
#  English - en, Russian - ru, Italian - it, Spanish - es (or sp), Ukrainian - uk (or ua), German - de, Portuguese - pt, 
#  Romanian - ro, Polish - pl, Finnish - fi, Dutch - nl, French - fr, Bulgarian - bg, Swedish - sv (or se), 
#  Chinese Traditional - zh_tw, Chinese Simplified - zh (or zh_cn), Turkish - tr, Croatian - hr, Catalan - ca
LANG="fr"
# OpenWeatherMap Units format : standard (Kelvin), metric(Celsius), imperial(Fahrenheit)
UNITS="metric" 
# default theme if not specified with -t
THEME="accuweather15"
# Record current temperature and pressure
BAROGRAPH=false
# set forecast nb day (min 1 to 5 max)
FDAYRANGE=3
#set forecast time (only 01 - 04 - 07 - 10 - 13 - 16 - 19 - 22 )
# set forecast morning time
FAMTIME="07"
# set forecast noon time
FNTIME="13"
# set forecast afternoon time
FPMTIME="16"
# Activate log
DOLOG=false

##########################################################################################################################

# Functions

__help()
{
	echo
	cat <<END_HELP
owm.sh	-- download and parse OpenWeatherMap data for current weather and forecasts

USAGE: owm.sh [-a] [-b] [-c] [-f] [-h] [-t <theme dir>]


OPTIONS:
	-a download and parse all. (current condition and hourly forecast)
	-b activate barograph. Can be defined in the settings.
	-c download and parse current condition only.
	-f download and parse forecasts only.
	-h this help.
	-t <theme dir> define the theme directory to use for icons. Can be defined in the settings.


version $version
END_HELP

	exit 0
}

__log() {
	if $DOLOG; then
		echo $(date '+%Y/%m/%d %Hh%Mm%Ss:') "$1" >> $LOGFILE
	fi
}

__error() {
	__log "$1"
	__log "End."
	exit 1
}

__checkrequirements () {
	__log "Checking for required commands: ${REQUIRE}."
	command -v command >/dev/null 2>&1 || {
		__log "WARNING> \"command\" not found. Check requirements skipped !"
		return 1 ;
	}
	for requirement in ${REQUIRE} ; do
		command -v ${requirement} > /dev/null || {
                        __log "$requirement required but not found !"
                        _return=1
		}
	done
	[ -z "${_return}" ] || { 
		__error "Requirement missing." 
        }
}

__dl_data() {	
	__log "Downloading weather data. API call: $1 ..."
	status=$(curl --connect-timeout 30 -o $TMPRAW --silent --write-out '%{http_code}\n' "$1" 2>> $LOGFILE)
	if [[ $? -ne 0 ]]; then
		__error "Failed to download (Check your connection or site is down)"
	fi
	if [[ $status -ne 200 ]]; then
		__error "Failed to download (Check settings: apikey ? etc)"
	fi
	mv "$TMPRAW" "$2"
	__log "Data downloaded."
}

__check_theme(){	
	if [[ ! -d "$OWMDIR/icons/$THEME" ]]; then
		__log "Icons folder $OWMDIR/icons/$THEME doesn't exist. Using default one."
		THEME="accuweather15"
	else
		__log "Using icons folder $OWMDIR/icons/$THEME"
	fi
}

__parse_process_current() {
	local dataepoch ldataepoch city cdesc ctemp chum crain cpress ccloud cvis csr css degree cardir cws ccalc
	dataepoch=$(jq '.dt' "$1")
	if [[ ! -e "$OWMDDIR/clepoch" ]]; then
		echo "0" > "$OWMDDIR/clepoch"
	fi
	ldataepoch=$(cat "$OWMDDIR/clepoch")
	# if it's a new OpenWeatherMap caculated data, we will parse it
	if [[ $dataepoch -eq $ldataepoch ]]; then
		__log "We already have the latest current weather data ($(date --date="@$ldataepoch" +"%d/%m/%Y %Hh%M")). No parsing."
	else	
		echo "$dataepoch" > "$OWMDDIR/clepoch"
		__log "Parsing current weather data ..."
		#calculated data
		ccalc="$(date --date="@$dataepoch" +"%d/%m/%Y %Hh%M")"
		echo "$ccalc" > "$OWMDDIR/ccalc"
		#city
		city="$(jq '.name' "$1" | sed "s/\"//g")"
		echo "$city" > "$OWMDDIR/city"
		#weather description
		cdesc="$(jq '.weather[0].description' "$1" | sed "s/\"//g")"
		echo "$cdesc" > "$OWMDDIR/cdesc"
		#weather image file
		icon="$OWMDIR/icons/$THEME/$(jq '.weather[0].icon' "$1" | sed "s/\"//g").png"
		__log "Copy current weather image $icon to $OWMDDIR/current.png"
		cp "$icon" "$OWMDDIR/current.png"	
		#temperature
		ctemp="$(jq '.main.temp' "$1" | awk '{print int($1+0.5)}')"
		#pressure
		cpress="$(jq '.main.pressure' "$1")"
		if $BAROGRAPH; then
				__log "Barograph enabled: recording pressure and temperature data"
				echo "$dataepoch $cpress $ctemp" >> "$HTPRESSDAT"
				$OWMDIR/plot.sh "$HTPRESSDAT" "$GRAPH1" "$GRAPH2"
		fi	
		ctemp="$ctemp°"
		echo "$ctemp" > "$OWMDDIR/ctemp"
		cpress="$cpress hPa"
		echo "$cpress" > "$OWMDDIR/cpress"
		#humidity
		chum="$(jq '.main.humidity' "$1")%"
		echo "$chum" > "$OWMDDIR/chum"
		#rain
		crain=$(jq 'select(.rain) != null' "$1")
		if [[ "$(jq '.rain' "$1")" != "null" ]]; then
			crain="$(jq '.rain.3h' "$1") mm"		
		else
			crain="n/a"
		fi
		echo "$crain" > "$OWMDDIR/crain"
		#cloudiness
		ccloud="$(jq '.clouds.all' "$1")%"
		echo "$ccloud" > "$OWMDDIR/ccloud"
		#visibility
		cvis="$(echo "scale=2;$(jq '.visibility' "$1") / 1000"|bc) km"
		echo "$cvis" > "$OWMDDIR/cvis"
		#sunrise
		csr="$(date --date="@$(jq '.sys.sunrise' "$1")" +"%Hh%M")"
		echo "$csr" > "$OWMDDIR/csr"
		#sunset
		css="$(date --date="@$(jq '.sys.sunset' "$1")" +"%Hh%M")"
		echo "$css" > "$OWMDDIR/css"
		#wind	
		degree=$(jq '.wind.deg' "$1")
		if [[ "$degree" != "null" ]]; then
			degree=$(echo "$degree" | awk '{print int($1+0.5)}')
			cardir=${SECTOR[$(echo "$(echo "scale=2;$degree/22.5"|bc)" | awk '{print int($1+0.5)}')]}
			__log "Copy current rosa of wind $OWMDIR/icons/$THEME/$cardir.png to $OWMDDIR/crow.png"
			cp "$OWMDIR/icons/$THEME/$cardir.png" "$OWMDDIR/crow.png"
			degree="$degree°"		
		else
			degree="n/a"
			__log "Copy current rosa of wind $OWMDIR/icons/$THEME/CLM.png to $OWMDDIR/crow.png"
			cp "$OWMDIR/icons/$THEME/CLM.png" "$OWMDDIR/crow.png"
		fi
		echo "$degree" > "$OWMDDIR/cwd"
		if [[ $UNITS != "imperial" ]]; then
			cws="$(echo "$(jq '.wind.speed' "$1")*3.6"|bc|awk '{print int($1+0.5)}') km/h"
		else
			cws="$(jq '.wind.speed' "$1"|awk '{print int($1+0.5)}') mi/h"
		fi
		echo "$cws" > "$OWMDDIR/cws"
		__log "$city, $cdesc, $ctemp, $chum, $crain, $cpress, $ccloud, $cvis, $csr, $css, $degree, $cws, $ccalc"
	fi
}

__search_findex() {
	local key
	__log "Searching JSON tab index for $2"
	for ((i=0; i<$3; i++ ))
	do
		key="$(date --date="@$(jq ".list[$i].dt" "$1")"  +"%y%m%d%H")"
		if [[ "$key" == "$2" ]]; then
			__log "found: index is $i"
			return $i
		fi
	done
	__error "I don't find this forecast time ($key). Check the settings. Exiting"
}

__search_windmax() {
	local key wmax=0 imax=0 ws
	__log "Searching max wind speed of day $2"
	for ((i=0; i<$3; i++ ))
	do
		key="$(date --date="@$(jq ".list[$i].dt" "$1")"  +"%y%m%d")"
		if [[ "$key" == "$2" ]]; then
			ws=$(jq ".list[$i].wind.speed" "$1"| awk '{print int($1+0.5)}')
			if [[ $ws -ge $wmax ]]; then
				wmax=$ws
				imax=$i								
			fi
		fi		
	done
	return $imax
}

__parse_process_forecast() {
	local idxmax idxndayam idxndayn idxndaypm idxwnday datelang iconnday wdname famdesc fndesc fpmdesc famtemp fntemp fpmtemp fwsmax cardir degree
	idxmax=$(jq '.cnt' "$1")
	datelang="${LANG,,}""_""${LANG^^}"	
	if [[ $FDAYRANGE -lt 1 || $FDAYRANGE -gt 5 ]]; then
		__error "FDAYRANGE has a wrong value. Check the settings. Exiting."
	fi
	if [[ ! -e "$2" ]]; then
		echo "" > "$2"
	fi
	jq '.list' "$1" > "$TMPRAW"	
	if [[ $(diff -q "$TMPRAW" "$2") == "" ]]; then
		__log "We already have the latest forecast data. No parsing."
	else
		jq '.list' "$1" > "$2"
		__log "Parsing forecast data (weather, temperature, wind)"	
		for (( nday=1; nday<=$FDAYRANGE; nday++ ))
		do
			__search_findex "$1" "$(date --date="+$nday days" +"%y%m%d$FAMTIME")" "$idxmax"
			idxndayam=$?
			__search_findex "$1" "$(date --date="+$nday days" +"%y%m%d$FNTIME")" "$idxmax"
			idxndayn=$?
			__search_findex "$1" "$(date --date="+$nday days" +"%y%m%d$FPMTIME")" "$idxmax"
			idxndaypm=$?
			#day+$nday day name
			wdname=$(LANG=$datelang date --date="+$nday days" +"%A")
			echo "$wdname" > "$OWMDDIR/f$(echo $nday)wdname"	
			#forecast temp in $nday 
			famtemp="$(jq ".list[$idxndayam].main.temp" "$1"| awk '{print int($1+0.5)}')°"
			echo "$famtemp" > "$OWMDDIR/f$(echo $nday)amtemp"
			fntemp="$(jq ".list[$idxndayn].main.temp" "$1"| awk '{print int($1+0.5)}')°"
			echo "$fntemp" > "$OWMDDIR/f$(echo $nday)ntemp"
			fpmtemp="$(jq ".list[$idxndaypm].main.temp" "$1"| awk '{print int($1+0.5)}')°"
			echo "$fpmtemp" > "$OWMDDIR/f$(echo $nday)pmtemp"		
			#forecast description		
			famdesc="$(jq ".list[$idxndayam].weather[0].description" "$1"| sed "s/\"//g")"
			echo "$famdesc" > "$OWMDDIR/f$(echo $nday)amdesc"
			fndesc="$(jq ".list[$idxndayn].weather[0].description" "$1"| sed "s/\"//g")"
			echo "$fndesc" > "$OWMDDIR/f$(echo $nday)ndesc"
			fpmdesc="$(jq ".list[$idxndaypm].weather[0].description" "$1"| sed "s/\"//g")"
			echo "$fpmdesc" > "$OWMDDIR/f$(echo $nday)pmdesc"
			#forecast image filename
			iconnday="$OWMDIR/icons/$THEME/$(jq ".list[$idxndayam].weather[0].icon" "$1" | sed "s/\"//g").png"
			__log "Copy weather image $iconnday to $OWMDDIR/f$(echo $nday)am.png"
			cp "$iconnday" "$OWMDDIR/f$(echo $nday)am.png"
			iconnday="$OWMDIR/icons/$THEME/$(jq ".list[$idxndayn].weather[0].icon" "$1" | sed "s/\"//g").png"
			__log "Copy weather image $iconnday to $OWMDDIR/f$(echo $nday)n.png"
			cp "$iconnday" "$OWMDDIR/f$(echo $nday)n.png"
			iconnday="$OWMDIR/icons/$THEME/$(jq ".list[$idxndaypm].weather[0].icon" "$1" | sed "s/\"//g").png"
			__log "Copy weather image $iconnday to $OWMDDIR/f$(echo $nday)pm.png"
			cp "$iconnday" "$OWMDDIR/f$(echo $nday)pm.png"
			#forecast max wind in the day (speed and direction)
			__search_windmax "$1" "$(date --date="+$nday days" +"%y%m%d")" "$idxmax"
			idxwnday=$?
			if [[ $UNITS != "imperial" ]]; then
				fwsmax="$(echo "$(jq ".list[$idxwnday].wind.speed" "$1")*3.6"|bc|awk '{print int($1+0.5)}') km/h"
			else
				fwsmax="$(jq ".list[$idxwnday].wind.speed" "$1"|awk '{print int($1+0.5)}') mi/h"
			fi	
			echo "$fwsmax" > "$OWMDDIR/f$(echo $nday)wsmax"
			degree=$(jq ".list[$idxwnday].wind.deg" "$1" | awk '{print int($1+0.5)}')
			cardir=${SECTOR[$(echo "$(echo "scale=2;$degree/22.5"|bc)" | awk '{print int($1+0.5)}')]}
			echo "$cardir" > "$OWMDDIR/f$(echo $nday)wmaxdir"
	
			__log "day+$nday: $wdname, $famdesc, $fndesc, $fpmdesc, $famtemp, $fntemp, $fpmtemp, $fwsmax, $cardir"
		done
	fi
	rm "$TMPRAW"
}

##########################################################################################################################

OWMDIR=$(dirname $0)
OWMDDIR="$OWMDIR/data"
LOGFILE="$OWMDIR/owm.log"
TMPRAW="$OWMDDIR/tmp.raw"
CURCONDFILE="$OWMDDIR/weather.raw"
FORCONDFILE="$OWMDDIR/forecast.raw"
LFORCONDFILE="$OWMDDIR/lforecast.raw"
HTPRESSDAT="$OWMDDIR/Htempress.dat"
GRAPH1="$OWMDDIR/barograph.png"
GRAPH2="$OWMDDIR/lbarograph.png"
cURI="http://api.openweathermap.org/data/2.5/weather?id=$LOCATIONID&appid=$APIKEY&lang=$LANG&units=$UNITS"
fURI="http://api.openweathermap.org/data/2.5/forecast?id=$LOCATIONID&appid=$APIKEY&lang=$LANG&units=$UNITS"
SECTOR=("N" "NNE" "NE" "ENE" "E" "ESE" "SE" "SSE" "S" "SSW" "SW" "WSW" "W" "WNW" "NW" "NNW" "N")

if $BAROGRAPH; then
	REQUIRE="curl jq bc diff gnuplot"
else
	REQUIRE="curl jq diff bc"
fi

__log "Executing $0"
__checkrequirements
__check_theme

while [ -n "$1" ]; do
	case $1 in
		-h)__help;shift;;
		-t)shift;THEME=$1;shift;;
		-b)BAROGRAPH=true;shift;;
		-a)__dl_data "$cURI" "$CURCONDFILE";__dl_data "$fURI" "$FORCONDFILE";__parse_process_current "$CURCONDFILE";__parse_process_forecast "$FORCONDFILE" "$LFORCONDFILE";shift;;
		-c)__dl_data "$cURI" "$CURCONDFILE";__parse_process_current "$CURCONDFILE";shift;;
		-f)__dl_data "$fURI" "$FORCONDFILE";__parse_process_forecast "$FORCONDFILE" "$LFORCONDFILE";shift;;
		--)break;;
		-*) echo "Error: No such option $1. -h for help"; exit 1;;
	esac
done

__log "End."

exit 0;

