#!/usr/bin/python -u
#

"""Utility for accessing web services."""

import json
import logging
import xmlrpclib

# This is a top level helper so it can't use cros.factory.external.
try:
  import zeep
  import zeep.cache
  import zeep.helpers
  import zeep.transports
  HAVE_ZEEP = True
except ImportError:
  HAVE_ZEEP = False

try:
  import jsonrpclib
  HAVE_JSONRPCLIB = True
except ImportError:
  HAVE_JSONRPCLIB = False

try:
  from twisted.internet import defer
  from twisted.internet import threads
  from twisted.web import xmlrpc
  HAVE_TWISTED = True
except ImportError:
  HAVE_TWISTED = False

try:
  from txjsonrpc.web import jsonrpc
  HAVE_TXJSONRPC = True
except ImportError:
  HAVE_TXJSONRPC = False


# URL prefixes if you want to override RPC protocol.
PREFIX_XMLRPC = 'xmlrpc:'
PREFIX_WSDL = 'wsdl:'
PREFIX_JSONRPC = 'jsonrpc:'
PREFIX_JSON_FILTER = 'json:'

PROTOCOL_PREFIXES = [PREFIX_XMLRPC,
                     PREFIX_WSDL,
                     PREFIX_JSONRPC,
                     PREFIX_JSON_FILTER]


def CheckPackage(url, has_package, package_name):
  if not has_package:
    raise ImportError(
        'The URL %s needs Python package "%s" installed. '
        'Please install that by command: "sudo pip install %s"' %
        (url, package_name, package_name))


def ParseURL(url):
  """Parses the URL to extract protocol prefixes from real URL."""
  protocols = []
  while ':' in url:
    if any(map(url.startswith, PROTOCOL_PREFIXES)):
      protocol, colon, url = url.partition(':')
      protocols.append(protocol + colon)
    else:
      break
  return protocols, url


class WebServiceProxy(object):
  """An abstract class for proxy to web services.

  Most web services are using HTTP as transport instance, which may cause race
  condition (CannotSendRequest) if we try to send new requests before some
  previous response was fully processed.

  As a result, most WebServiceProxy implementations should try to keep only
  URL in constructor, and create the real proxy object when the callRemote is
  invoked.
  """

  def callRemote(self, method, *args, **kargs):
    raise NotImplementedError

  def __getattr__(self, name):
    def _wrapper(*args, **kargs):
      return self.callRemote(name, *args, **kargs)
    return _wrapper


class XMLRPCProxy(WebServiceProxy):
  """A proxy for web service implemented in XML-RPC."""

  def __init__(self, url):
    self._url = url

  def callRemote(self, method, *args, **kargs):
    proxy = xmlrpclib.ServerProxy(self._url, allow_none=True)
    return getattr(proxy, method)(*args, **kargs)


class TwistedXMLRPCProxy(WebServiceProxy):
  """ A proxy for web service implemented in XML-RPC, powered by Twisted."""

  def __init__(self, url):
    CheckPackage(url, HAVE_TWISTED, 'twisted')
    self._url = url

  def callRemote(self, method, *args, **kargs):
    proxy = xmlrpc.Proxy(self._url, allowNone=True)
    return proxy.callRemote(method, *args, **kargs)


class JSONRPCProxy(WebServiceProxy):
  """A proxy for web service implemented in JSON-RPC."""

  def __init__(self, url):
    CheckPackage(url, HAVE_JSONRPCLIB, 'jsonrpclib')
    self._url = url

  def callRemote(self, method, *args, **kargs):
    proxy = jsonrpclib.Server(self._url)
    return getattr(proxy, method)(*args, **kargs)


class TXJSONRPCProxy(WebServiceProxy):

  def __init__(self, url):
    CheckPackage(url, HAVE_TXJSONRPC, 'txJSON-RPC')
    self._url = url

  def callRemote(self, method, *args, **kargs):
    proxy = jsonrpc.Proxy(self._url)
    return proxy.callRemote(method, *args, **kargs)


class ZeepProxy(WebServiceProxy):
  """A proxy for web service implemented as Zeep Client (WSDL/SOAP)."""

  def __init__(self, url):
    CheckPackage(url, HAVE_ZEEP, 'zeep')
    self._url = url
    # Without cache, zeep will retrieve WSDL on every connection.
    self._cache = zeep.cache.InMemoryCache()

  def callRemote(self, method, *args, **kargs):
    transport = zeep.transports.Transport(cache=self._cache)
    proxy = zeep.Client(self._url, transport=transport).service
    result = proxy[method](*args, **kargs)
    # By default zeep returns collections.OrderedDict.
    return zeep.helpers.serialize_object(result, target_cls=dict)


class TwistedProxy(WebServiceProxy):
  """A virtual proxy to turn a proxy into twisted deferred proxy."""

  def __init__(self, proxy):
    CheckPackage('<unknown>', HAVE_TWISTED, 'twisted')
    assert isinstance(proxy, WebServiceProxy)
    self._proxy = proxy

  def callRemote(self, method, *args, **kargs):
    return threads.deferToThread(
        self._proxy.callRemote, [method] + args, kargs)


class JSONProxyFilter(WebServiceProxy):
  """A proxy that converts input and output for chained proxies."""

  def __init__(self, proxy):
    assert isinstance(proxy, WebServiceProxy)
    self._proxy = proxy

  def callRemote(self, method, *args, **kargs):
    if kargs:
      raise TypeError(
          'Keyword arguments (%r) not allowed for web service method: %s.' %
          (kargs, method))
    result = self._proxy.callRemote(method, *map(json.dumps, args))
    if HAVE_TWISTED and isinstance(result, defer.Deferred):
      return result.addCallback(json.loads)
    return json.loads(result)


def CreateWebServiceProxy(url, use_twisted=False):
  """Returns a web service proxy that will work against specified URL.

  The URL should be a reference to web service, with optional prefixes:
  - json: Translate input and output into JSON string.
  - wsdl: Assume the URL itself returns a WSDL document.
  - jsonrpc: Assume the URL refers to a JSON-RPC server.
  - xmlrpc: Assume the URL refers to a XML-RPC server.

  URLs ends with 'wsdl' will be recognized as WSDL service as well.

  For example,
  - ``json:http://10.3.0.11/proxy`` will connect to a XML-RPC service that both
    arguments and return values should be JSON simple strings.
  - ``http://10.3.0.11/?wsdl' will connect to a WSDL (usually SOAP) service.
    The input and output must be encoded as generic compound types.
  - ``json:wsdl:http://10.3.0.11' will connect to a WSDL service, and encode
    the argument and return values as JSON simple strings.

  Args:
    url: A string to web service URL.
    use_twisted: Set to True to create Twisted-friendly proxies.
  """
  enable_json_filter = False
  force_wsdl = False
  force_jsonrpc = False
  force_xmlrpc = False

  protocols, url = ParseURL(url)

  if PREFIX_XMLRPC in protocols:
    force_xmlrpc = True
  if PREFIX_JSONRPC in protocols:
    force_jsonrpc = True
  if PREFIX_WSDL in protocols:
    force_wsdl = True
  if PREFIX_JSON_FILTER in protocols:
    enable_json_filter = True

  forced = [force_wsdl, force_jsonrpc, force_xmlrpc]
  if forced.count(True) > 1:
    raise ValueError('URL %s has too many protocol identifiers.' % url)

  if not any(forced) and url.lower().endswith('wsdl'):
    force_wsdl = True

  # Now, start building the proxy or filters.
  if force_wsdl:
    proxy = ZeepProxy(url)
    if use_twisted:
      proxy = TwistedProxy(proxy)
  elif force_jsonrpc:
    proxy = TXJSONRPCProxy(url) if use_twisted else JSONRPCProxy(url)
  else:
    proxy = TwistedXMLRPCProxy(url) if use_twisted else XMLRPCProxy(url)

  if enable_json_filter:
    logging.info('Enabled JSON input/output filter for web service: %s', url)
    proxy = JSONProxyFilter(proxy)

  return proxy


### 1. Assume your real shopfloor service is here, and all its input and output
# must be JSON strings:
real_url = 'http://192.168.1.99:8090/'
service1 = xmlrpclib.ServerProxy(real_url, allow_none=True)

# The input is a JSON string. The output is also JSON, for example
# '{"vpd.ro.region": "us"}'
#print(service1.GetVersion())

### 2. The webservice_utils provides 'json:' prefix to filter that.

# station: S10000046 -> P10000309 -> F10000307 -> R10000565 -> Finalize
#             SMT          FFT       RunInFAT        GRT        ship
# mlb_sn:
# N24_500e_DVT2: sku1-M749NDUL sku3-M749NDXG sku4-M749NDZN sku5-M749NE12  M749NDUA M749NDUS
# Coral: M748MMCF  8S5B20R07042ZZP283Q0001

#for 1st floor
#url1 = 'json:http://192.168.250.20:8081/TestWebService/Service1.asmx?wsdl'
#service1 = CreateWebServiceProxy(url1)
#print(service1.NotifyStart({u'serials.mlb_serial_number': u'M749NDY1'}, 'S10000046'))
#print(service1.NotifyEnd({u'serials.mlb_serial_number': u'M749NDY1'}, 'S10000046'))

# for 2nd floor
#url2 = 'json:http://10.240.0.20:8081/TestWebService/Service1.asmx?wsdl'
#service1 = CreateWebServiceProxy(url2)
#print('[DEBUG] test function from Webservice: GetDeviceInfo')

#url3 = 'json:http://10.240.0.199:8081/Service1.asmx?wsdl'

#print(service1.NotifyStart({u'serials.mlb_serial_number': u'M749NDY1'}, 'S10000046'))
#print(service1.NotifyEnd({u'serials.mlb_serial_number': u'M749NDUS'}, 'P10000309'))
#print(service1.ActivateRegCode({u'vpd.rw.ubind_attribute': u'xxx'}, 'Finalize'))
#print(service1.NotifyEvent({u'serials.mlb_serial_number': u'M748MMCF'}, 'Finalize'))
#print(service1.GetDeviceInfo({u'serials.mlb_serial_number': u'M749NE12'}))

#print(service1.GetDeviceInfo({u'serials.mlb_serial_number': u'8S5B20R07042ZZP283Q0001'}))

url2 = 'json:http://doa.bitland.com.cn:8001/Service1.asmx?wsdl'
service1 = CreateWebServiceProxy(url2)

url4 = 'json:http://10.240.0.20:8001/WBTEST/Service1.asmx?wsdl'
service1 = CreateWebServiceProxy(url4)

print('DEBUG: Call NotifyStart')
print(service1.NotifyStart({u'serials.mlb_serial_number': u'M845L90B'}, 'F10000307'))
print('DEBUG: Call GetDeviceInfo')
print(service1.GetDeviceInfo({u'serials.mlb_serial_number': u'M845L90B'}))
print('DEBUG: Call NotifyEnd')
print(service1.NotifyEnd({u'serials.mlb_serial_number': u'M845L90B'}, 'F10000307'))

# Input is real variable, and output is real dict, for example
"""{
    u'vpd.ro.region': u'us',\
    u'vpd.rw.ubind_attribute': u'=Ci0KIMoXBMPaaMYDEYngMzYTR3sbjTER6dlbwiVwnUb7sAlTEAEaB3JvYm8zNjAQi-eIuAo=',\
    u'vpd.ro.serial_number': u'P201RRFG',\
    u'vpd.rw.gbind_attribute': u'=Ci0KIMN5zxbO-hJQMar1GuIRJ8wqFSijWa3PKZ8-PsIRaawCEAAaB3JvYm8zNjAQus7PtwE=',\
    u'vpd.ro.model_name': u'Lenovo 500e Chromebook'\
}
"""

