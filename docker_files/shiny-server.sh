#!/bin/sh

# Make sure the directory for individual app logs exists
mkdir -p /var/log/shiny-server
chown shiny.shiny /var/log/shiny-server
chmod +x /srv/shiny-server/*/www/*
chmod +x /srv/shiny-server/DEApp/data/*
chmod -R +x /srv/shiny-server/shaman/*
chmod -R +x /srv/shiny-server/STARTapp/*
chmod -R +x /srv/shiny-server/tsar_nasqar/*

exec shiny-server >> /var/log/shiny-server.log 2>&1
#exec shiny-server

#R -e "shiny::runApp('/srv/shiny-server/deseq2shiny',host='0.0.0.0', port=80, launch.browser=F)"
