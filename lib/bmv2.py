# using the connection from switch.py
from switch import SwitchConnection
from p4.tmp import p4config_pb2

def buildDeviceConfig(bmv2_json_file_path=None):
    """Builds the device config for BMv2"""
    device_config = p4config_pb2.P4DeviceConfig()
    device_config.reassign = True
    with open(bmv2_json_file_path) as f:
        device_config.device_data = f.read()
    return device_config

# Connection wrapper for BMv2 software switch - inherit from SwitchConnection
class Bmv2SwitchConnection(SwitchConnection):
    def buildDeviceConfig(self, **kwargs):
        return buildDeviceConfig(**kwargs)