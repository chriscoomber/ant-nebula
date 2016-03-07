#!/bin/sh

# Inputs
ssc_address=$1
self_ip=$2
area_code=$3
group_id=$4
reg_per_sec_per_group=$5
subscribers_per_group=$6
calls_per_sec_per_group=$7
total_calls_per_group=$8
call_length=$9
first_total_calls=$10

dir=/etc/load

# Arbitrary ports that probably aren't used. Need to be unique across the whole deployment (because
# otherwise our router gets confused).
port_1="${area_code}${group_id}0"
port_2="${area_code}${group_id}1"

cd /tmp
first_time=true

while :
do
  ## Register the subscribers
  ${dir}/sipp ${ssc_address} -sf ${dir}/auth_reg_client.xml -inf reg_subs_1_${group_id}.csv -p $port_1 -bind_local -i $self_ip -trace_stat -trace_err -r $reg_per_sec_per_group -rate_scale 1 -m $subscribers_per_group -default_behaviors all,-bye -bg

  # Wait for the process to finish
  rc=0
  while [ $rc -ne 1 ]
  do
    sleep 0.5
    ps -eaf | grep reg_subs_1_${group_id} | grep -v grep
    rc=$?
  done

  ${dir}/sipp ${ssc_address} -sf ${dir}/auth_reg_client.xml -inf reg_subs_2_${group_id}.csv -p $port_2 -bind_local -i $self_ip -trace_stat -trace_err -r $reg_per_sec_per_group -rate_scale 1 -m $subscribers_per_group -default_behaviors all,-bye -bg

  # Wait for the process to finish
  rc=0
  while [ $rc -ne 1 ]
  do
    sleep 0.5
    ps -eaf | grep reg_subs_2_${group_id} | grep -v grep
    rc=$?
  done

  # Run the call load
  /etc/load/run_load_calls.sh \
      $ssc_address \
      $self_ip \
      $area_code \
      $group_id \
      $calls_per_sec_per_group \
      $total_calls_per_group \
      $call_length \
      $first_total_calls \
      $port_1 \
      $port_2

  # Also print out the command we just used
  echo "/etc/load/run_load_calls.sh $ssc_address  $self_ip  $area_code $group_id $calls_per_sec_per_group $total_calls_per_group $call_length $first_total_calls $port_1 $port_2" \
    > command_to_run_calls.txt
done
