#!/usr/bin/env python
# -*- coding: utf-8 -*-

import csv
import logging
import optparse
import SimpleXMLRPCServer
import socket
import SocketServer

DEFAULT_SERVER_PORT = 8090
DEFAULT_SERVER_ADDRESS = '192.168.1.99'
KEY_SERIAL_NUMBER = 'serials.serial_number'
KEY_MLB_SERIAL_NUMBER = 'serials.mlb_serial_number'
MLB_FILE = '/home/simon/Documents/Mock_ShopfloorBackend/test_WebService/mlbs.csv'

# In real factroy enviroment, the station would be this
"""
			Assy QC  ->  Pre test   ->  FA test  -> Runin  -> OS Preload  -> OOB/Kitting
SMT 				  FATP  										Runin 				GRT Finalize
"""
class ShopfloorService(object):

  def __init__(self):
    pass

  def GetVersion(self):
    """Returns the version of supported protocol."""
    return '1.0'

  def NotifyStart(self, data, station):
    """Notifies shopfloor backend that DUT is starting a manufacturing station.

    Args:
      data: A FactoryDeviceData instance.
      station: A string to indicate manufacturing station.

    Returns:
      A mapping in DeviceData format.
    """
    logging.info('DUT %s Entering station %s', data.get(KEY_MLB_SERIAL_NUMBER),
                 station)
    return {}

  def NotifyEnd(self, data, station):
    """Notifies shopfloor backend that DUT has finished a manufacturing station.

    Args:
      data: A FactoryDeviceData instance.
      station: A string to indicate manufacturing station.

    Returns:
      A mapping in DeviceData format.
    """
    logging.info('DUT %s Leaving station %s', data.get(KEY_MLB_SERIAL_NUMBER),
                 station)
    return {}

  def NotifyEvent(self, data, event):
    """Notifies shopfloor backend that the DUT has performed an event.

    Args:
      data: A FactoryDeviceData instance.
      event: A string to indicate manufacturing event.

    Returns:
      A mapping in FactoryDeviceData format.
    """
    assert event in ['Finalize', 'Refinalize']
    logging.info('DUT %s sending event %s', data.get(KEY_MLB_SERIAL_NUMBER),
                 event)
    return {}

  def GetDeviceInfo(self, data):
    """Returns information about the device's expected configuration.

    Args:
      data: A FactoryDeviceData instance.

    Returns:
      A mapping in DeviceData format.
    """
    logging.info('DUT %s requesting device information',
                 data.get(KEY_MLB_SERIAL_NUMBER))
    with open(MLB_FILE) as f:
      response = ReadMLBs(f, data.get(KEY_MLB_SERIAL_NUMBER))
    return response

  def ActivateRegCode(self, ubind_attribute, gbind_attribute, hwid):
    """Notifies shopfloor backend that DUT has deployed a registration code.

    Args:
      ubind_attribute: A string for user registration code.
      gbind_attribute: A string for group registration code.
      hwid: A string for the HWID of the device.

    Returns:
      A mapping in DeviceData format.
    """
    logging.info('DUT <hwid=%s> requesting to activate regcode(u=%s,g=%s)',
                 hwid, ubind_attribute, gbind_attribute)
    return {}

  def UpdateTestResult(self, data, test_id, status, details=None):
    """Sends the specified test result to shopfloor backend.

    Args:
      data: A FactoryDeviceData instance.
      test_id: A string as identifier of the given test.
      status: A string from TestState; one of PASSED, FAILED, SKIPPED, or
          FAILED_AND_WAIVED.
      details: (optional) A mapping to provide more details, including at least
          'error_message'.

    Returns:
      A mapping in DeviceData format. If 'action' is included, DUT software
      should follow the value to decide how to proceed.
    """
    logging.info('DUT %s updating test results for <%s> with status <%s> %s',
                 data.get(KEY_MLB_SERIAL_NUMBER), test_id, status,
                 details.get('error_message') if details else '')
    return {}


class ThreadedXMLRPCServer(SocketServer.ThreadingMixIn,
                           SimpleXMLRPCServer.SimpleXMLRPCServer):
  """A threaded XML RPC Server."""
  pass

def RunAsServer(address, port, instance, logRequest=False):
  """Starts a XML-RPC server in given address and port.

  Args:
    address: Address to bind server.
    port: Port for server to listen.
    instance: Server instance for incoming XML RPC requests.
    logRequests: Boolean to indicate if we should log requests.

  Returns:
    Never returns if the server is started successfully, otherwise some
    exception will be raised.
  """
  server = ThreadedXMLRPCServer((address, port), allow_none=True,
                                logRequests=logRequest)
  server.register_introspection_functions()
  server.register_instance(instance)
  logging.info('Server started: http://%s:%s "%s" version %s',
               address, port, instance.__class__.__name__,
               instance.GetVersion())
  server.serve_forever()


def ReadMLBs(csvfile, mlb_serial_number):
  """Reads MLB information from a CSV file."""
  mlbs = {}
  for n, line in enumerate(csv.DictReader(csvfile)):
    mlb_sn = line.pop('Mlb_serial_number', None)
    if not mlb_sn:
      raise ValueError('Missing Mlb_serial_number in row %d' % (n+1))
    if mlb_sn in mlbs:
      raise ValueError('Duplicate Mlb_serial_number in row %d' % (n+1))
    mlbs[mlb_sn] = line
    logging.debug('Read MLB %s: %s', mlb_sn, line)
  #print mlbs[mlb_serial_number]
  d_regular = {}
  d_regular[u'vpd.ro.serial_number'] = mlbs[mlb_serial_number]['Serial_number']
  d_regular[u'vpd.ro.region'] = mlbs[mlb_serial_number]['Region']
  d_regular[u'vpd.ro.model_name'] = mlbs[mlb_serial_number]['Model_name']
  d_regular[u'vpd.ro.customization_id'] = mlbs[mlb_serial_number]['Customization_id']
  d_regular[u'vpd.rw.ubind_attribute'] = mlbs[mlb_serial_number]['Ubind_attribute']
  d_regular[u'vpd.rw.gbind_attribute'] = mlbs[mlb_serial_number]['Gbind_attribute']
  d_regular[u'component.brand_code'] = mlbs[mlb_serial_number]['Brand_code']
  d_regular[u'component.emmc'] = mlbs[mlb_serial_number]['EMMC']
  d_regular[u'component.memory'] = mlbs[mlb_serial_number]['Memory']
  d_regular[u'component.sku_id'] = mlbs[mlb_serial_number]['SKU_ID']
  d_regular[u'component.isrmapart'] = mlbs[mlb_serial_number]['IsRMAPart']
  
  logging.info('Returned mlb:%s %s', mlb_serial_number, d_regular)
  return d_regular


#def WriteMLBStation(process_log_file, data, current_station):
#  with open(process_log_file) as f:
#    writer = csv.writer(f)
#    for key in data:
#      if mlb_sn not in data.keys():
#        writer.writerow(key)
#      data.mln_sn.skey + 1
#      write skey
#  return 


def main():
  """Main entry when being invoked by command line."""
  parser = optparse.OptionParser()
  parser.add_option('-a', '--address', dest='address', metavar='ADDR',
                    default=DEFAULT_SERVER_ADDRESS,
                    help='address to bind (default: %default)')
  parser.add_option('-p', '--port', dest='port', metavar='PORT', type='int',
                    default=DEFAULT_SERVER_PORT,
                    help='port to bind (default: %default)')
  parser.add_option('-v', '--verbose', dest='verbose', default=False,
                    action='store_true',
                    help='provide verbose logs for debugging.')
  (options, args) = parser.parse_args()
  if args:
    parser.error('Invalid args: %s' % ' '.join(args))

  log_format = '%(asctime)s %(levelname)s %(message)s'
  logging.basicConfig(level=logging.DEBUG if options.verbose else logging.INFO,
                      format=log_format)

  # Disable all DNS lookups, since otherwise the logging code may try to
  # resolve IP addresses, which may delay request handling.
  socket.getfqdn = lambda (name): name or 'localhost'

  try:
    RunAsServer(address=options.address, port=options.port,
                instance=ShopfloorService(),
                logRequest=options.verbose)
  finally:
    logging.warn('Server stopped.')

#with open(mlbfile) as f:
#  mlbs = ReadMLBs(f, 'M0000000')

if __name__ == '__main__':
  main()


