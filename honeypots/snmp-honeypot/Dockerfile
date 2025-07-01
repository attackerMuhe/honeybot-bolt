FROM python:3.9-alpine

WORKDIR /app

COPY snmp_server.py .
COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

RUN mkdir -p /var/log/snmp

EXPOSE 161/udp

CMD ["python", "snmp_server.py"]