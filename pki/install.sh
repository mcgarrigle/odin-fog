#!/usr/bin/env bash

function cmd_server {
  mkdir -p /etc/pki/CA /etc/pki/libvirt/private 

  cp cacert.pem /etc/pki/CA

  cp "${HOSTNAME}-key.pem"  /etc/pki/libvirt/private/serverkey.pem
  cp "${HOSTNAME}-cert.pem" /etc/pki/libvirt/servercert.pem

  cp clientkey.pem  /etc/pki/libvirt/private
  cp clientcert.pem /etc/pki/libvirt

  systemctl enable --now virtqemud

  systemctl start virtproxyd-tls.socket
  systemctl try-restart virtproxyd.service

  systemctl start libvirtd-tls.socket
  systemctl try-restart libvirtd.service
}

function cmd_user {
  mkdir -p $HOME/.pki/libvirt
  cp cacert.pem $HOME/.pki/
  cp clientkey.pem clientcert.pem $HOME/.pki/libvirt
}

function cmd_help {
  echo "install.sh [server | user | help]"
}

HOSTNAME=$(hostname -s)
cmd_${1-help}
