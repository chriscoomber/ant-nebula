#!/usr/bin/env python
# Source: load generator instance
# Target: load cluster - which holds shared information
from cloudify import ctx

# Get used area code, and put it back on the list. We don't protect against simultaneous access of
# the target.
used_area_code = ctx.source.instance.runtime_properties['area_code']
area_codes = ctx.target.instance.runtime_properties['available_area_codes']
area_codes.append(used_area_code)
ctx.target.instance.runtime_properties['available_area_codes'] = area_codes
