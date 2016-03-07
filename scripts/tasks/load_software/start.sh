#!/bin/bash

# Node config
area_code=$(ctx instance runtime-properties area_code)
self_ip=$(ctx instance host_ip)

# Call config
# The default config provides 10 calls per second, and calls last 20 seconds. This implies 36K BHCA
# and 200 active calls per load node (minus a bit for registrations).
ssc_address="${ssc_ip}:${ssc_port}"
calls_per_sec=$call_rate
call_length=20

subscribers=$[30*$calls_per_sec] # The number of callee subscribers (= caller subscribers)
# The number of groups. Each group's register/call cycle is out of phase. Must be <=10.
if [ "$calls_per_sec" -le "10" ]
then
  groups=$calls_per_sec
else
  groups=10
fi
calls_per_subscriber=100 # The number of calls to make between each registration.
reg_per_sec=$[2*$calls_per_sec]

# Do some math. For accuracy, make sure these numbers divide nicely. There's a lot of restrictions
# here.
subscribers_per_group=$[$subscribers/$groups] # Must be <=100
calls_per_sec_per_group=$[$calls_per_sec/$groups]
reg_per_sec_per_group=$[$reg_per_sec/$groups]
total_calls_per_group=$[$calls_per_subscriber*$subscribers/$groups]

program_dir="/etc/load"

## Create .csv files for SIPp
cd /tmp
for (( group_id=0; group_id<$groups; group_id++ ))
do
  # The left numbers are of the format <area-code>5550<group-no>XX
  # The right numbers are of the format <area-code>5551<group-no>XX
  left_prefix="${area_code}5550${group_id}"
  right_prefix="${area_code}5551${group_id}"
  password=${sip_password}

  cat >reg_subs_1_${group_id}.csv <<EOF
SEQUENTIAL,PRINTF=$subscribers_per_group
$left_prefix%02d;[authentication username=$left_prefix%02d@$sip_domain \
password=$password];$sip_domain;,
EOF

  cat >reg_subs_2_${group_id}.csv <<EOF
SEQUENTIAL,PRINTF=$subscribers_per_group
$right_prefix%02d;[authentication username=$right_prefix%02d@$sip_domain \
password=$password];$sip_domain;,
EOF

  cat >reg_subs_call_${group_id}.csv <<EOF
SEQUENTIAL,PRINTF=$subscribers_per_group
$left_prefix%02d;$right_prefix%02d;$sip_domain;,
EOF
done


## Run the script for each group. We can't do much more than kick this off in a background thread,
## as it endlessly loops
for (( group_id=0; group_id<$groups; group_id++ ))
do
  # Stagger the groups
  first_total_calls=$[$total_calls_per_group*$group_id/$groups]
  nohup /etc/load/run_load.sh \
      $ssc_address \
      $self_ip \
      $area_code \
      $group_id \
      $reg_per_sec_per_group \
      $subscribers_per_group \
      $calls_per_sec_per_group \
      $total_calls_per_group \
      $call_length \
      $first_total_calls \
      >/dev/null 2>&1 </dev/null &

  # Also print out the command we just used
  echo "/etc/load/run_load.sh $ssc_ip $self_ip $area_code $group_id $reg_per_sec_per_group $subscribers_per_group $calls_per_sec $total_calls_per_group $call_length $first_total_calls" \
    > command_to_run_reg.txt
done
