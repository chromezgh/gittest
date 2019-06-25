#!/usr/bin/python -u
import xmlrpclib
real_url = 'http://101.1.2.4:8115'
proxy=xmlrpclib.ServerProxy(real_url)

#method in hana_shopfloor: 
"""
1.GetMLBInfo(self, mlb_sn, operator_id, station_id)
2.FinishSMT(self, mlb_sn, device_data, report_blob_xz=None) 
3.GetDeviceInfo(self, mlb_sn) 
4.FinishRunIn(self, mlb_sn=None, mac_address=None, device_data=None, report_blob_xz=None) 
5.FinishHWID(self, mlb_sn)
6.FinishRegCode(self, mlb_sn, device_data)
7.FinishFA(self, mlb_sn, device_data)
8.UploadReport(self, serial, report_blob, report_name=None, stage='FA')
9.Finalize(self, serial_number)
"""
print(proxy.GetDeviceInfo("TESTMLB-M-USWIFI"))
#print(proxy.FinishHWID("TESTMLB-M-USWIFI"))
#print(proxy.GetMLBInfo("TESTMLB-M-USWIFI", "a", "a"))


