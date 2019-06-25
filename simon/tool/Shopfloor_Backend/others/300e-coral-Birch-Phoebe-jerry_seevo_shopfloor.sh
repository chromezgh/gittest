#!/bin/sh

#300e_mudong

cd /home/bitland/300e_mudong/shopfloor/
sudo ./shopfloor_server -m cros.factory.shopfloor.hana_shopfloor -p 9120 &


#Birch

cd /home/bitland/Birch/bundle/shopfloor/
sudo ./shopfloor_server -m cros.factory.shopfloor.hana_shopfloor -p 8095 &


#Phoebe

cd /home/bitland/Phoebe_PVT/bundle/shopfloor/
sudo ./shopfloor_server -m cros.factory.shopfloor.hana_shopfloor -p 8105 &

#coral

cd /home/bitland/coral/Coral_DVT2/bundle/shopfloor/
sudo ./start_mock_shopfloor_v1_coral factory &

#jerry_seevo

cd /home/bitland/jerry_seevo/bundle/shopfloor/
sudo ./shopfloor_server -m cros.factory.shopfloor.jerry_shopfloor  -p 9500 &





