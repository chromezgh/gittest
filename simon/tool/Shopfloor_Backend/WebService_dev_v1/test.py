#!/usr/bin/python3.5
# -*- coding: utf-8 -*-

# station control 
# error return
# improve the effeciency
#
import csv

Test = {'mlb_serial_number': 'M0000001', 'gbind_attribute': '123456'}



def WriteDataStation(process_log_file, data):
  with open(process_log_file, 'r+') as plf:
    item_names = ['Date','Mlb_serial_number','HWID','Mac']
    writer_process_log_ob = csv.DictWriter(plf, fieldnames=item_names)
    #writer_process_log_ob.writerow({'Date': '000000','Mlb_serial_number': data['mlb_serial_number']})
    last_process_log_ob = csv.DictReader(plf)

    # if not exist mlb_sn, then create it 
    for row in last_process_log_ob:
      print(row)
      if data['mlb_serial_number'] == row['Mlb_serial_number']:
        break
      if data['mlb_serial_number'] != row['Mlb_serial_number']:
        continue 
      writer_process_log_ob.writerow({'Date': '0123','Mlb_serial_number': data['mlb_serial_number']})

    # if mlb_sn exists, then just update the other data/station
    #for row in last_process_log_ob:
    #  if data['mlb_serial_number'] == row['Mlb_serial_number']:
    #    last_process_log_ob[data['mlb_serial_number']]['Date'] = 456
    #    writer_process_log_ob.writerow({'Date': '123','Mlb_serial_number': data['mlb_serial_number'],'HWID': '0','Mac': '0'})

WriteDataStation('/home/simon/Documents/Mock_ShopfloorBackend/test_WebService/process_log.csv', Test)
