# Fork of Itobey/Lexiv/TelegrafFritzBox

## Introduction

This is a fork to create a Docker-based version of TelegrafFritzBox for DSL Internet. I tested this using a FritzBox 7590 with FRITZ!OS: 07.29 and with Docker under Raspberry Pi 4 4GB. 

The TIG-stack is required. This assumes you already have Grafana and Influx running in another docker network. If this is not the case, feel free to add Grafana or Influx to the docker-compose.yaml or to other means of running this stack, as the yaml provided only contains Telegraf.

## Changes in this fork
* Set the DSL-variable to true in the TelegrafFritzBox script
* Remove InfluxDB from docker-compose.yaml
* Change docker-compose for compatiblity with IOTstack

## Getting started
### For local testing
```
pip3 install fritzconnection
python3 telegrafFritzBox.py -i x.x.x.x -u <FritzBoxUser> -p <FritzBoxPassword>
```

### Run as standalone dockercontainer
```
docker build -t telegraf-fritzbox4pi .
```

### Alternative use with the IOTstack
(See https://github.com/SensorsIot/IOTstack for mor informations)

Build at first the native telegraf container with IOTstack template
```
cd ./IOTstack/.templates/telegraf
docker build -t telegraf-iostack .
```
Then edit the IOTstack docker-compose.yml
```
  telegraf-fritzbox:
    container_name: telegraf-fritzbox
    build: ../TelegrafFritzBox/.
    restart: unless-stopped
    environment:
    - TZ=Etc/UTC
    ports:
    - "8092:8092/udp"
    - "8094:8094/tcp"
    - "8125:8125/udp"
    volumes:
    - ./volumes/telegraf:/etc/telegraf
    - /var/run/docker.sock:/var/run/docker.sock:ro
```
Now you can use telegraf like the plain telegraf container and additionally the fritzconnection part

<hr>

# Original Readme.md
# Fork of Lexiv/TelegrafFritzBox

## Introduction

This is a fork to create a Docker-based version of TelegrafFritzBox for cable internet instead of DSL. I tested this using a FritzBox 6591 with FRITZ!OS: 07.13. Some restrictions apply - see `Configuring Grafana` below for details.
You can also use this without Docker, most of the original Readme below applies.

The TIG-stack is required. This assumes you already have Grafana running in another docker network. If this is not the case, feel free to add Grafana to the docker-compose.yaml or to other means of running this stack, as the yaml provided only contains Telegraf and InfluxDB.

## Changes in this fork

I've initially set the DSL-variable to false in the TelegrafFritzBox.py script and added the user parameter in the TelegrafFritzBox.conf (which you do not need to use, if you're running entirely in Docker). To have the script running in Docker, I've created a new Telegraf image containing the script. I also provide a docker-compose.yaml to create your TIG-stack (without Grafana - to add Grafana see further down below).

## Getting Started

You can test if this works with your modem by using the `testNonDSLuplink.py` script and passing your host, user and password along. See the original readme for more information.

First build the Docker Image to create a Telegraf Image with the necessary Python script (or use my prebuild image from Dockerhub: itobey/telegraf-fritzbox)
`docker build -t my-cool-name .`
This image needs to be referenced in the `docker-compose.yaml`. Moreover mount the `telegraf.conf` inside the container by using a volume (see docker-compose.yaml) This file needs to be edited to contain your FritzBox-IP, user and password (I advise creating a separate user as mentioned in the original readme).
Also mount the the `influxdb.conf` to the InfluxDB container or create your own configuration.
Choose username and password to your liking.

## Configuring Grafana
Add a new datasource in Grafana: InfluxDB. As an URL choose your InfluxDB container - for me it's another network so I chose to map the port to the host system: 172.17.0.1:8086
No need to enable any options, just fill in the InfluxDB details. If you went with my defaults, fill in:
- Database: FritzBox
- User: telegraf
- Password: telegraf123
- HTTP Method: GET

Import `GrafanaFritzBoxDashboard.json` in Grafana and choose the InfluxDB. This json is from another fork of this Github Project - some panels do not work with cable as opposed to DSL (TotalBytesReceived, TotalBytesSent and Line Damping - can't say if Errors work, as there are currently no errors). I might work on the dashboard in the future.

<hr>

[![MIT license](https://img.shields.io/github/license/Schmidsfeld/TelefrafFritzBox?color=blue)](https://opensource.org/licenses/MIT)
[![made-with-python](https://img.shields.io/badge/Python-3.7%2C%203.8-green)](https://www.python.org)
[![HitCount](http://hits.dwyl.com/Schmidsfeld/TelefrafFritzBox.svg)](http://hits.dwyl.com/Schmidsfeld/TelefrafFritzBox)

# TelegrafFritzBox
A Telegraf collector written in Phthon, gathering several crucial metrics for the Fritz!Box router by AVM via the TR-064 protocol. This collection includes a main phyton3 script, a telegraf config file and a Grafana dashboard.

The communication with the router is based on the FritzConnection library https://github.com/kbr/fritzconnection by Klaus Bremer.

For some future development of this script (especially with cable internet access) additional help is required. The script now has been sanatized not to crash if a varible is nout found. Please send me examples of your
`http://fritz.box:49000/tr64desc.xml`
If you have another connection type please check it there is an equivalent to the DSL statistics in there...

Forking and modifying this script is explicitly encouraged (hence you most likely need to adjust for your situation). I would appreciate if you drop me a note f you implement other stuff so I can backport it into the main script. 


## The End Result
Information that you get
* Full status of your current and past transfer speeds
* Current and possible line speeds
* The line dampening and noise margin
* The errors occurring the line
* Local networks (LAN and WLAN traffic)
* connected WLAN clients

![Grafana dashboard](doc/FritzBoxDashboard2.png?raw=true)

## Details
### Concept
The script utilizes a single connection to the FritzBox router with the FritzConnection library. From there it reads out several service variable collections via TR-064. Note, that for performance reasons only one connection is established and every statistics output is only requested once. From the dictionary responses containing several variables each, the desired variables are extracted manually and parsed. The parsed arguments are then formatted appropriately as integers or strings according to the influxDB naming scheme. Lastly the gathered information is output as several lines in the format directly digested by Telegraf / InfluxDB.

### Output
* The output is formatted in the influxDB format. 
* By default the influxDB dataset FritzBox will be generated
* All datasets are tagged by the hostname of the router and grouped into different sources
* All names are sanitized (no "New" in variable names)
* All variables are cast into appropriate types (integer for numbers, string for expressions and float for 64bit total traffic)

![InfluxDB compatible output](doc/OutputScript.png?raw=true)

## Install
Several prerequisites need to be met to successfully install this script and generate the metrics. Some seem to be obvious but will be mentioned here for sake of complete documentation. 
* Have an operational TIG stack (Telegraf, InfluxDB, Grafana) with all of them installed and operational.
* Activate the TR-064 protocoll in the Fritzbox (Heimnetz -> Netzwerk -> Netzwerkeinstellungen)
* Optional: Have a dedicated user on the Fritz!Box (for example :Telegraf)
* download and install the script (example for debian/ubuntu)
```
apt install python3-pip
pip3 install fritzconnection
git clone https://github.com/Schmidsfeld/TelegrafFritzBox/
chmod +x ./TelegrafFritzBox/telegrafFritzBox.py
chmod +x ./TelegrafFritzBox/telegrafFritzSmartHome.py
cp ./TelegrafFritzBox/telegrafFritzBox.py /usr/local/bin
cp ./TelegrafFritzBox/telegrafFritzSmartHome.py /usr/local/bin
```
* Edit the telegraf file and adjust the credentials (`nano ./TelegrafFritzBox/telegrafFritzBox.conf`)
* If you want to use the FritzBox smarthome features also in (`nano ./TelegrafFritzBox/telegrafFritzSmartHome.conf`)
```
cp ./TelegrafFritzBox/telegrafFritzBox.conf /etc/telegraf/telegraf.d
cp ./TelegrafFritzBox/telegrafFritzSmartHome.conf /etc/telegraf/telegraf.d
python3 ./TelegrafFritzBox/telegrafFritzBox.py
systemctl restart telegraf
```
* Load your Grafana dashboard (grafana/GrafanaFritzBoxDashboard.json)

## This script uses optionally the environment variables for authentification:
The required IP and Password can be set from environment variables
* ``FRITZ_IP_ADDRESS``  IP-address of the FritzBox (Default 169.254.1.1)
* ``FRITZ_TCP_PORT``    Port of the FritzBox (Default: 49000)
* ``FRITZ_USERNAME``    Fritzbox authentication username (Default: Admin)
* ``FRITZ_PASSWORD``    Fritzbox authentication password

## Non DSL Uplink
This version should at least not crash if other uplinks than DSL are used. Some stats will be missing. This can be partly circumvented by setting the variable `` IS_DSL = False`` in the python file. Since I don't have the information or devices to test non DSL uplinks, I put together a testfile.
If you have a non DSL line (Cable / Fiber / LTE etc.) and a fritzbox, please consider sending me the output of  
```
python3 testNonDSLuplink.py -p PASSWORD
```


## Future Plans
This Project is ready and tested locally, to ensure it is suiteable for publications, but not yet finished. For some parts I need help with additional testing (especially other connections than DSL). There are several things planned for future releases:
* Gather more stats about signals strengths
* Getting data about active phones and calls etc
* Gather upstream information for cable based uplinks

## Changelog
Since the last major milestone the following parts have been changed
* IP and password in environment variabe or telegraf config file
* Fixed crash on non DSL connection (some stats still missing)
* Added statistics about connected LAN / WLAN devices
* First beta for smarthome devices (in a seperate file)
* No more dedicated user required (admin account is the default iy only password is given)
