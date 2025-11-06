#!/bin/bash


/home/pi/scripts/c_helpers/updateConfig ENTER_ACCOUNT ENTER_PASSWORD /home/pi/drone_engage/de_comm/de_comm.config.module.json /home/pi/simulator/sim_de_mavlink_instances/de_comm.1.config.module.json /home/pi/simulator/sim_de_mavlink_instances/de_comm.2.config.module.json

/home/pi/scripts/wifi_start_ap.sh

sudo /home/pi/scripts/wifi_clean_all_non_ap.sh

/home/pi/scripts/sh_clean_logs.sh


