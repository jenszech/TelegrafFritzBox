FROM telegraf:1.16.2
LABEL description="Based on telegraf, this image adds python3 and a telegraf input script to feed fritbox metrics into an influxdb"

WORKDIR /usr/local/bin

COPY telegrafFritzBox.py .

RUN apt-get update && \
	apt-get upgrade -y && \
	apt-get install -y python3 python3-pip && \
	pip3 install fritzconnection && \
	chmod +x ./telegrafFritzBox.py
