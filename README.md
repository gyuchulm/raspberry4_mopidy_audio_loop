
# Raspberry pi 4 audio looper 
original version is 
https://github.com/PetitPrinc3/PIpod-Nano

original version is made with 
- Raspberry pi zero 
- Pirate Audio Headphone Amp

# we have many option to listen music / sound
but I want to build some simple audio / podcast player without concerns! 
there are so many video looper but not many audio loopers with Raspberry pi
so I found the projects and forked this projects, and will edit some features! 

```
Main features
##Hardware
- Raspberry pi 4B + (tested)

##Environment
Setting up with Mopidy 
boot on play in the folder Raspberry pi 4 /home/pi/Music
also It has built with Mopidy. you can control the music and sound with Elegant web Environment!

##now on Edit 
there are some feature with the button, 
Now I am on going with remove / adapt only plug and play versions

```
# Further development
```
- remove button and other feature for optimization
- sync with dropbox
- parcing some sound from somewhere (Nasa or ITunes Podcast?) 
```


# Getting started!
```

## Getting started

These instructions will get you a copy of the project up and running on your pi. 

### Prerequisites

You'll need a fresh install of [Raspberrypi OS](https://www.raspberrypi.org/downloads/) (It is also Rasbian Buster compatible. Older versions were not tested).
Before following the steps below, make sure that your pi is connected to the internet and your Pirate Audio board is connected to your pi. At this point, it is preferable to have the pi plugged into the main, rather than having it running on the ups power supply. 

### Automatic Setup

A step by step series of examples that tell you how to get the project to work on your pi.

First you need to clone the repository :

```
pi@raspberrypi:~ $ git clone https://github.com/G-a-v-r-o-c-h-e/PIpod-Nano
```

Then go to the Pipod-Nano folder and give install.sh the right permissions :

```
pi@raspberrypi:~ $ cd PIpod-Nano
pi@raspberrypi:~ $ sudo chmod +x install.sh
```

You are now ready to run the installation. Run install.sh with root privileges and specify the path to the folder you want the pi to play music from :

:warning: Your path must not end with a slash (for example use /home/pi/Music rather than /home/pi/Music/)

```
pi@raspberrypi:~ $ sudo ./install.sh /home/pi/Music
```

Default folder will be /home/pi/Music if you don't mention any.

Reboot and you should be done !

### Manual Setup

First, follow the steps provided by [Pimonori](https://github.com/pimoroni/pirate-audio) to get the pirate audio software up and running on your pi.

Then you'll need to install mpd for mopidy and mpc, in order to have control over the the webclient through commands.

```
pi@raspberrypi:~ $ sudo apt-get install mopidy-mpd mpc -y
```

#### Play music on boot

Now, you'll want to create a bash script, that will allow you to have the pi play songs on boot automaticaly. You can either do something pretty simple such as :
 ```
 #!/bin/bash
 sleep 60 
 for song in `ls /home/pi/Music`; do mpc add 'file:///home/pi/Music/$song'; done
 mpc play
 ```
Or you can also do something a bit more complex, but that should be faster on boot, such as my autoplay.sh file.
If you decide that you want use this script, make sure that you add the following lines at the begining of the document :
```
#!/bin/bash
path=/home/pi/Music
```
Don't forget to create every folder and file that is mentioned into the script either.

You need to make this script executable so run :

```
pi@raspberrypi:~ $ sudo chmod +x autoplay.sh
```

Great, so now we want this script to be run on boot, so we will create a systemd service.
Create a file in /etc/systemd/system, that you'll name "something.service". Edit it whith whatever text editor you love and write :
```
[Unit]
Description= Some text
After=pulseaudio.service
After=remote-fs.target
After=sound.target
After=mopidy.service

[Service]
Type=simple
RemainAfterExit=no
ExecStart=/path/to/your/autoplay.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

Now, to have it ran on boot :

```
pi@raspberrypi:~ $ sudo systemctl start something.service
pi@raspberrypi:~ $ sudo systemctl enable something.service
```

#### Edit the volume button's sensibility

To do this, navigate to /usr/local/lib/python3.7/dist-packages/mopidy_raspberry_gpio/ and edit the frontend.py file.

You're looking for this part of the document :

```
    def handle_volume_up(self):
        volume = self.core.mixer.get_volume().get()
        volume += 5
        volume = min(volume, 100)
        self.core.mixer.set_volume(volume)

    def handle_volume_down(self):
        volume = self.core.mixer.get_volume().get()
        volume -= 5
        volume = max(volume, 0)
        self.core.mixer.set_volume(volume)
```

Simply edit the volume +=/-= value from 5% to whatever you want (obviously a value between 0 and 100)

#### Buttons

First things first, we need to create a python file that will shutdown the pi if we hold the play button for a few secs and smoothly increase/decrease the volume as we hold the volume buttons. You can do this with whatever button you want, simply modify the GPIO value. My script will be the following :

```
#!/usr/bin/env python
from gpiozero import Button
import time
import os

stopButton = Button(5)
volumeUp, volumeDown = Button(20), Button(6)

while True:
        if stopButton.is_pressed:
                tmp, duration = time.time(), 0
                while stopButton.is_pressed:
                        duration = time.time() - tmp
                        if duration > 3:
                                os.system("shutdown now -h")
        if volumeUp.is_pressed:
                time.sleep(.25)
                while volumeUp.is_pressed:
                        os.system("mpc volume +5")
                        time.sleep(.01)

        if volumeDown.is_pressed:
                time.sleep(.25)
                while volumeDown.is_pressed:
                        os.system("mpc volume -5")
                        time.sleep(.01)

        time.sleep(1)
```

Now to have this script run on boot, we will edit /etc/rc.local and add the following line before "exit 0" :

```
sudo python /path/to/your/pythonscript.py &

exit 0
```

#### Allow Mopidy to load metadata

It is possible that Mopidy won't load your files properly (the artcover, title and author, etc.). To correct that, we need to increase the value of metadata_timeout in the mopidy.conf file. It is located at /etc/mopidy/mopidy.conf and you should edit the following :

```
[file]
enabled = true
media_dirs = /home/pi/Music
show_dotfiles = false
excluded_file_extensions =
  .directory
  .html
  .jpeg
  .jpg
  .log
  .nfo
  .pdf
  .png
  .txt
  .zip
follow_symlinks = false
metadata_timeout = 5000
```


And you're done ! You've succesfully (hopefully) performed every modification that the automated installation would have done ! Reboot the pi and here you go !

## Having an issue ?

### Common issues 

- The autoplay.sh seems not to be run on boot : no song is loaded to my playlist.
 ```
 Answer : did you give your script the authorization to be run ? (chmod +x) 
 If so, check 'systemctl status autoplay'. 
 If an mpd error appears, you need to make sure that mpc is working correctly. (simply type mpc)  
 if mpc is not working, try to reinstall mpd-mopidy.
 Otherwise, you may need to add a sleeping time in your autoplay.sh file.
 To do so, simply add "sleep 10" before the "mpc volume 1" line.
 ```
 - The power button is not working.
 ```
 Answer : check wether the /etc/rc.local file is executable or not. 
 Make sure you did not forget the "&". 
 Check your python syntax.
 ```
 
 - Some of my files are not loading.
 ```
 Answer : Are you using a .mp3 / .wav / .flac file ? Don't your files contain spaces in their names ?
 If you are not, please make sure your file is mopidy compatible and add your extension to the autoplay.sh as follows :
 sudo nano /usr/share/PIpodScripts/autoplay.sh
 Edit this line :
 for song in `ls $path | grep ".mp3\|.wav\|.flac\|.yourextension"`; do if [ `cat /usr/share/PIpodScripts/database |grep -c $song` -eq "0" ]; then echo $song >> /tmp/.db$;fi ; done
 ```
 
 For any other questions, feel free to contact me !

## To be done

```
- Allow the loading of files that contain spaces in their name
- Add a battery indicator on the screen
- Find a way to add a wake up function to the shutdown button
- Create a 3D model for a nice looking shell
```

## Thanks

Many thanks to :
 - The pimonori and mopidy community
 - The pimonori staff
 - The open source world

## Feel like helping me ?

I have a ton of projects and if you feel like helping me out, feel free to use my [Paypal](https://paypal.me/AReppelin).
Many thanks !
