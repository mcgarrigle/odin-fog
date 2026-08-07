#!/usr/bin/env bash

sudo dnf install -y acpid
sudo systemctl enable --now acpid
sudo dnf install -y qemu-guest-agent
