#!/bin/bash

declare -A services

services=(
	['Discover Daemon']='avahi-daemon'
	['Printer Daemon']='cups'
	['Network Manager']='NetworkManager'
	['IPv6 packet filtering']='ip6tables'
)

for service in "${!services[@]}"; do
	echo "==> Disableing: $service"
	chkonfig "${services[$service]}" off
done