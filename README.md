# Arduino-Wireless-Temperature-Data-Logger

The code and schematic file for a data logger I made that logs the temperature wirelessly using an Arduino Uno and an Arduino Mega.

- It can display the temperature and log to a microSD card or to the computer.
- A thermistor is used to determine the temperature and can be connected to either the transmitter or the receiver.
- There is a pair of RF Link Transmitters and Receivers, which can communicate at a distance of up to 500ft (in certain conditions).
- When logging to the microSD card, it creates a .CSV file that can be used to generate a graph of the change in temperature over a period of time.
- When logging to the computer, a Python code runs in the background, communicating with a local web server with a MySQL database. I then can view the temperature from anywhere on my local network.

Check out the video for this project:
http://youtu.be/C8B96F9wcD0

The code was written by Alex Strandberg and is licensed under the MIT License, check LICENSE for more information

[Fritzing](http://fritzing.org/home/) is needed to view the schematic file

## Arduino Libraries
- [LiquidCrystal](http://arduino.cc/en/Reference/LiquidCrystal)
- math.h
- stdlib.h
- [SD](http://arduino.cc/en/Reference/SD)
- [Time](http://playground.arduino.cc/code/time)
- [Timer3](http://playground.arduino.cc/code/timer1)
- [VirtualWire](http://www.airspayce.com/mikem/arduino/VirtualWire/)

## How to Set Up Logging to Computer
1. Download and. install [Python 2.7.8](https://www.python.org/download/releases/2.7.8/)
2. Set up an Apache, MySQL (with phpmyadmin), and PHP server ([WAMP - Windows](http://www.homeandlearn.co.uk/php/php1p3.html), [MAMP - Mac](http://youtu.be/cdZWUJzdcDk), or [LAMP - Linux](https://www.digitalocean.com/community/tutorials/how-to-install-linux-apache-mysql-php-lamp-stack-on-ubuntu)).
3. From phpmyadmin, click "Import" at the top and upload temp_log.sql to set up the database table.
4. Create a new MySQL user with a password.
5. Copy the files in the repository's "public_html" folder into the web server's "public_html", "www", or "htdocs" folder.
6. In that folder, modify both php files (index.php and updatelog.php) by replacing 'db_username' and 'db_password' with your credentials at the top of both files.
7. Connect the Arduino to the computer and see what port it is using (from the Arduino IDE).
8. Modify the logtemp.py file by replacing '/dev/ttyACM0' with the name of the port for your Arduino.
9. Verify that the web server is running and run the Python file.
10. Navigate to http://localhost/ in a web browser and everything should be up and running.
