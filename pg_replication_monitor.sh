#!/bin/env bash 
#set -x
############################################################
#Author    : ChinaXing - chen.yack@gmail.com
#Create    : 2012-12-14 17:16
#Function  : monitor pgsql's replication
############################################################

source repl_mon.conf

function error_report
{
    echo "[$1]$2"
    exit 1
}

function get_status
{
    sent_location=$($PSQL -U $MASTER_USER -t \
        -c "SELECT sent_location from pg_stat_replication" \
        -h$MASTER_ADDRESS -p$MASTER_PORT)
    pg_current_xlog_location=$($PSQL -U $MASTER_USER -t \
        -c "SELECT pg_current_xlog_location()" \
        -h$MASTER_ADDRESS -p$MASTER_PORT)
    pg_last_xlog_receive_location=$($PSQL -U $SLAVE_USER -t \
        -c "SELECT pg_last_xlog_receive_location()" \
        -h$SLAVE_ADDRESS -p$SLAVE_PORT)
    pg_last_xlog_replay_location=$($PSQL -U $SLAVE_USER -t \
        -c "SELECT pg_last_xlog_replay_location()" \
        -h$SLAVE_ADDRESS -p$SLAVE_PORT)

    sent_location=${sent_location##*/}
    pg_current_xlog_location=${pg_current_xlog_location##*/}
    pg_last_xlog_receive_location=${pg_last_xlog_receive_location##*/}
    pg_last_xlog_replay_location=${pg_last_xlog_replay_location##*/}

}

function check
{
  let sent_receive_lag=16#$sent_location-16#$pg_last_xlog_receive_location
  let current_sent_lag=16#$pg_current_xlog_location-16#$sent_location
  let replay_receive_lag=16#$pg_last_xlog_replay_location-16#$pg_last_xlog_receive_location

  echo send_receive_lag:$sent_receive_lag
  echo current_sent_lag:$current_sent_lag 
  echo replay_receive_lag:$replay_receive_lag
}

get_status

if  [ -z "$sent_location" ] || \
    [ -z "$pg_last_xlog_receive_location" ] || \
    [ -z "$pg_last_xlog_replay_location" ] || \
    [ -z "$pg_current_xlog_location" ]
then
    error_report "ERROR" "status has NULL value:
    sent_location:$sent_location
    pg_current_xlog_location:$pg_current_xlog_location
    pg_last_xlog_receive_location:$pg_last_xlog_receive_location
    pg_last_xlog_replay_location:$pg_last_xlog_replay_location
    "
fi


check
