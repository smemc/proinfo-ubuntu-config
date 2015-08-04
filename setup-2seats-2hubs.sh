#!/bin/bash

total_passos=5
passo_atual=0

tn502_endereco="$(lspci | grep SM501 | cut -d' ' -f1 | sed 's/\./:/')"

progresso() {
  passo_atual=$(( passo_atual + 1 ))
  echo ">>> (${passo_atual}/${total_passos}) ${1}"
}

progresso "Instalando os arquivos de regras do udev"

install -m 644 etc/udev/rules.d/71-usb-2seats-2hubs.rules /etc/udev/rules.d
install -m 644 etc/udev/rules.d/72-usb-2seats-2hubs-late.rules /etc/udev/rules.d

progresso "Instalando os arquivos de serviço do systemd"

install -m 644 etc/systemd/system/le-nextboot-*.service /etc/systemd/system

progresso "Instalando os arquivos de configuração do Xorg para a placa de vídeo TN-502"

install -d /etc/X11/xorg.conf.d
install -m 644 etc/X11/xorg.conf.d/tn502-2seats.conf.in /etc/X11/xorg.conf.d/tn502-2seats.conf
sed -i -e "s/@TN502_ADDRESS@/${tn502_endereco}/" /etc/X11/xorg.conf.d/tn502-2seats.conf

progresso "Ativando os serviços do systemd necessários para os computadores do ProInfo"

apt install zram-config
systemctl start zram-config.service

progresso "Ativando as novas regras do udev e trazendo os novos terminais à vida"

udevadm trigger
