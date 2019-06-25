#!/usr/bin/python2.7

# verify the registration whether can match device/type or not
# should be copy to path: usr/local/factory/py/
# made by SW Simon
# 
import binascii
import base64
import re
import struct

import factory_common  # pylint: disable=W0611
from cros.factory.proto import reg_code_pb2
from cros.factory.proto.reg_code_pb2 import RegCode
from cros.factory.utils import type_utils
from cros.factory.test.rules import registration_codes

from cros.factory.test.rules.registration_codes import *

LEGACY_REGISTRATION_CODE_LENGTH = 72
REGISTRATION_CODE_PAYLOAD_BYTES = 32
DEVICE_PATTERN = re.compile(r'^\w+$')

# maple:  =CisKIKUMQoIBtH44vPgvgAUF1vyrhZyLRGTHap5HkEWahn21EAEaBW1hcGxlEOmqsPwL,
#         =CisKIEyjw658x9wvW0a1EceK6YwdXRv2OewBNpUl7U1JypjMEAAaBW1hcGxlEKbhnq4I

# maple14 =Ci0KIGTHOeJ08dhTCn3XUPkJo--G_cT_p81whXZ7iN8PZUhVEAEaB21hcGxlMTQQ18-c1g4=,
#         =Ci0KIH_vw9AEr3Ef6y6MEOyXVZng1GeoE6egAymiKQsmJKfLEAAaB21hcGxlMTQQ-8uNowo=

#robo:    =CioKIFssNf9DI3qCHi8uKOdy9IcdRiyp4TDfHewdVfXNcifOEAEaBHJvYm8QhKanuQI=,
#         =CioKICsMNtU9jGO9ApwBlAV3ql-pJnmsAK0SVsdq6I6R1ufdEAAaBHJvYm8QmdDEuw4=

#robo360: =Ci0KIFlo0saSIdmfNSW7KkpK5M2QujyD3gSQi6X9wEbuMR8mEAEaB3JvYm8zNjAQoOrpmwY=,
#         =Ci0KIMN5zxbO-hJQMar1GuIRJ8wqFSijWa3PKZ8-PsIRaawCEAAaB3JvYm8zNjAQus7PtwE=

encoded_string=['=CisKIKUMQoIBtH44vPgvgAUF1vyrhZyLRGTHap5HkEWahn21EAEaBW1hcGxlEOmqsPwL',
                '=CisKIEyjw658x9wvW0a1EceK6YwdXRv2OewBNpUl7U1JypjMEAAaBW1hcGxlEKbhnq4I']

#dopefish
encoded_string=['=Ci4KIPEPGlzVvybvtVl2oIsO9Hhi5S8G4vaHRD3LIzwFMDgXEAEaCGRvcGVmaXNoEKLT5Ro=',
                'Ci4KII901Zodo87vxQMdnAtv1WdfHn109GlmI5lwsyA8VdJOEAAaCGRvcGVmaXNoEPiI-qID']

for code in encoded_string:
    reg_code = RegistrationCode(code)
    print "Type  :", reg_code.type
    print "Device:", reg_code.device


