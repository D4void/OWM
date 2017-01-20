# OWM
conky and bash script to download and parse OpenWeatherMap current weather and hourly forecast

owm.sh is a bash script to automatically download and parse OpenWeatherMap current weather and hourly forecast.
Then you can use it with conky to display your meteo on your desktop.

 http://openweathermap.org/
 https://github.com/brndnmtthws/conky


DEPENDENCIES

 This bash script requires: 
  * curl
  * jq
  * bc
  * diff
  * gnuplot if you activate barograph


INSTALL

 Copy owm directory into your .conky directory and be sure to chmod u+x owm.sh and plot.sh


BEFORE USING

 Find your location id and register on OpenWeatherMap website to get an API key.
 https://openweathermap.org/find?q=
 API Key: see https://openweathermap.org/appid
 Then fill the settings at the begining of the script.
 You can edit lang, units, nb days forecast, choose time (forecast is hourly)


USE

 owm.sh [-a] [-b] [-c] [-f] [-h] [-t <theme dir>]

 Options:
        -a download and parse all. (current condition and hourly forecast)
        -b activate barograph. Can be defined in the settings.
        -c download and parse current weather only.
        -f download and parse forecasts only.
        -h this help.
        -t <theme dir> define the theme directory to use for icons. Can be defined in the settings.


 You have my 2 french conky scripts as examples in the owm directory : owm-conkyrc & owmbaro-conkyrc

 Launch owm.sh -a one time before launching conky or you won't have any data to display
 and you will have to wait the conky refesh.

 Example: 
 ~/.conky/owm/owm.sh -a
 Then conky -c ~/.conky/owm/owm-conkyrc

 Limits with free api key:
 Do not send requests more than 1 time per 10 minutes from one device/one API key.
 Normally the weather is not changing so frequently.
 If you do more, your api key can be blocked. 

 Barograph:
 If you activate barograph, I recommand a 24/24 online pc and prefer a crontab to regularly launch owm.sh 
 Remove "${texeci 600 bash $HOME/.conky/owm/owm.sh -a" from your conky script.
 Then crontab -e
 */10 * * * * /home/user/.conky/owm/owm.sh -a > /dev/null # owm every 10mn 


Have fun
(forgive my english)
