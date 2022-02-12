FROM telegraf:latest
LABEL description="Based on telegraf, this image adds python3 and a telegraf input script to feed fritbox metrics into an influxdb"


RUN apt-get update && \
	apt-get upgrade -y && \
	apt-get install -y python3 python3-pip rsync
RUN	pip3 install fritzconnection

WORKDIR /usr/local/bin
COPY telegrafFritzBox.py .
RUN chmod +x ./telegrafFritzBox.py


# IOTstack declares this path for persistent storage
VOLUME ["/etc/telegraf"]

# EOF
