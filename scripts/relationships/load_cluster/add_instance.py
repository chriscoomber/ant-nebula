#!/usr/bin/env python
# Source: load generator instance
# Target: load cluster - which holds shared information
from cloudify import ctx
from cloudify import exceptions

# Get available area codes, and store one on the source
available_area_codes = ctx.target.instance.runtime_properties['available_area_codes']
try:
    area_code = available_area_codes.pop()
except IndexError:
    raise exceptions.NonRecoverableError('No area codes left')

# TODO: locking, so that two tasks don't grab the same area code
ctx.target.instance.runtime_properties['available_area_codes'] = available_area_codes
ctx.source.instance.runtime_properties['area_code'] = area_code
