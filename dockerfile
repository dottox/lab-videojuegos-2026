FROM python:3.12-slim

ENV DEBIAN_FRONTEND=noninteractive

# Instalar solo lo necesario para tu Makefile
RUN apt-get update && \
    apt-get install -y make entr git && \
    pip install git+https://github.com/thisismypassport/shrinko8 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app