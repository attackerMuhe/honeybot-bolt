FROM redis:7.4.4

RUN apt-get update && apt-get install -y stunnel

COPY redis.conf /etc/redis/redis.conf
COPY stunnel.conf /etc/stunnel/stunnel.conf

