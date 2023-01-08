mkdir -p /tmp
touch /tmp/.db$
touch /usr/share/PIpodScripts/database
for song in `ls $path | grep ".mp3\|.wav\|.flac"`; do if [ `cat /usr/share/PIpodScripts/database |grep -c $song` -eq "0" ]; then echo $song >> /tmp/.db$;fi ; done
mv /usr/share/PIpodScripts/database /usr/share/PIpodScripts/database.save
cat /tmp/.db$ /usr/share/PIpodScripts/database.save > /usr/share/PIpodScripts/database

while [ `mpc`=="mpd error: Connection refused" ]; do sleep 1; done
mpc volume 60

#Loading the playlist

if [ -s /tmp/.db$ ]
then
	echo 'New songs were found !'
	lastsong=`sed -n '1p' /usr/share/PIpodScripts/database`
	mpc add file://$path/$lastsong
	mpc play
	sleep 1
	for song in `cat /usr/share/PIpodScripts/database | grep -v "$lastsong"`; do mpc add file://$path/$song; done
else
	if [ -z /var/lib/mopidy/m3u/ ]
	then
		echo "No new song available. No playlist found."
		lastsong=`sed -n '1p' /usr/share/PIpodScripts/database`
		mpc add file:///$path/$lastsong
		mpc play
		sleep 1
		for song in `cat /usr/share/PIpodScripts/database | grep -v "$lastsong"`; do mpc add file://$path/$song; done     
	else
		list=`find /var/lib/mopidy/m3u/ -printf '%T+ %p\n' | sort -r | grep "m3u8" | head -1 |grep -Eoi '/2[^>]+' | tr -d "/" | cut -f 1 -d '.'`
		mpc load $list
		mpc play
		echo mpc playlist $list loaded. No new song was found.
	fi
fi

mpc repeat on

#Saving

filename=`date +"%Y%m%d%T" | tr -d ":"`
mpc save $filename

#Cleaning

rm /tmp/.db$

lists=`ls /var/lib/mopidy/m3u/ | grep -c ""`
if [ "$lists" -gt "3" ]
then
	last=`find /var/lib/mopidy/m3u/ -printf '%T+ %p\n' | sort -r | grep "m3u8" | head -1 |grep -Eoi '/var/[^>]+'`
	for list in `find /var/lib/mopidy/m3u | grep "m3u8" | grep -v "$last"`; do rm $list; done
fi
