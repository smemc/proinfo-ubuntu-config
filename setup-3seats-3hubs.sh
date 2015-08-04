#!/bin/bash

total_passos=8
passo_atual=0

tn502_endereco="$(lspci | grep SM501 | cut -d' ' -f1 | sed 's/\./:/')"
tn502_display=":$(echo ${tn502_endereco} | awk -F: '{ print $1 * 100 + $2 * 10 + $3 }')"

progresso() {
  passo_atual=$(( passo_atual + 1 ))
  echo ">>> (${passo_atual}/${total_passos}) ${1}"
}

do_apt() {
  apt install -y --no-install-recommends ${@}
}

progresso "Instalando os arquivos de regras do udev"

install -m 644 etc/udev/rules.d/71-usb-3seats-3hubs.rules /etc/udev/rules.d
install -m 644 etc/udev/rules.d/72-usb-3seats-late.rules /etc/udev/rules.d

progresso "Instalando os arquivos de serviço do systemd"

install -d /etc/systemd/scripts
install -m 755 etc/systemd/scripts/* /etc/systemd/scripts
install -m 644 etc/systemd/system/*.service /etc/systemd/system

progresso "Adicionando o PPA do projeto Ubuntu Multiseat"

apt-add-repository ppa:ubuntu-multiseat

progresso "Preparando o sistema para a instalação dos novos pacotes"

apt update
apt -y upgrade

progresso "Instalando os pacotes necessários"

do_apt xserver-xorg-video-nested zram-config

progresso "Instalando os arquivos de configuração do Xorg para a placa de vídeo TN-502"

install -d /etc/X11/xorg.conf.d
install -m 644 etc/X11/xorg.conf.d/tn502-3seats.conf.in /etc/X11/xorg.conf.d/tn502-3seats.conf
install -m 644 etc/X11/xorg.conf.d/nested-3seats.conf.in /etc/X11/xorg.conf.d/nested-3seats.conf
sed -i -e "s/@TN502_DISPLAY@/${tn502_display}/" -e "s/@TN502_ADDRESS@/${tn502_endereco}/" /etc/X11/xorg.conf.d/tn502-3seats.conf
sed -i -e "s/@TN502_DISPLAY@/${tn502_display}/" /etc/X11/xorg.conf.d/nested-3seats.conf

progresso "Ativando os serviços do systemd necessários para os computadores do ProInfo"

systemctl enable x-daemon-3seats@${tn502_display}.service
systemctl start zram-config.service

progresso "Ativando as novas regras do udev e trazendo os novos terminais à vida"

udevadm trigger
