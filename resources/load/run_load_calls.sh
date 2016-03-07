#!/bin/sh

# Inputs
ssc_address=$1
self_ip=$2
area_code=$3
group_id=$4
calls_per_sec_per_group=$5
total_calls_per_group=$6
call_length=$7
first_total_calls=$8
port_1=$9
port_2=$10

dir=/etc/load
cd /tmp

# Start the UAS and UAC. These use media, which requires root access
sudo ${dir}/sipp $ssc_address -sf ${dir}/media_uas.xml -p $port_2 -i $self_ip -trace_stat -default_behaviors all,-bye -bg
if [ "$first_time" = true ]
then
  sudo ${dir}/sipp $ssc_address -sf ${dir}/media_uac.xml -inf reg_subs_call_${group_id}.csv -p $port_1 -i $self_ip -trace_stat -fd 10 -trace_err -r $calls_per_sec_per_group -rate_scale 1 -m $first_total_calls -d $call_length -default_behaviors all,-bye -bg
  first_time=false
else
  sudo ${dir}/sipp $ssc_address -sf ${dir}/media_uac.xml -inf reg_subs_call_${group_id}.csv -p $port_1 -i $self_ip -trace_stat -fd 10 -trace_err -r $calls_per_sec_per_group -rate_scale 1 -m $total_calls_per_group -d $call_length -default_behaviors all,-bye -bg
fi

# Wait for the UAC to finish
rc=0
while [ $rc -ne 1 ]
do
  sleep 5
  ps -eaf | grep reg_subs_call_${group_id} | grep -v grep
  rc=$?
done

# Kill the UAS
process_id=$( ps -eaf | grep " -p $port_2 -i $self_ip -trace_stat" | grep -v grep | awk '{{print $2}}')
if [ -n $process_id ]
then
  sudo kill $process_id
fi
