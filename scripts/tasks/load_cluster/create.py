#!/usr/bin/env python
# Instance: load cluster - which holds shared information
from cloudify import ctx
from cloudify.state import ctx_parameters as inputs


# Get the area codes (input to this script) and store them in runtime properties
ctx.instance.runtime_properties['available_area_codes'] = inputs['area_codes'].split(',')
