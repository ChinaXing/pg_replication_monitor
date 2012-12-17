#!/usr/bin/env bash 
set -x
############################################################
#Author    : ChinaXing - chen.yack@gmail.com
#Create    : 2012-12-14 17:16
#Function  : monitor pgsql's replication
############################################################

function error_report
{
    echo "[$1]$2"
    if [ -n "$REPORTER" ]
    then
        $REPORTER "$@"
    fi
    exit 1
}

function get_status
{
    sent_location=$($PSQL -U $MASTER_USER -t -d postgres \
        -c "SELECT sent_location from pg_stat_replication" \
        -h$MASTER_ADDRESS -p$MASTER_PORT)
    pg_current_xlog_location=$($PSQL -U $MASTER_USER -t -d postgres \
        -c "SELECT pg_current_xlog_location()" \
        -h$MASTER_ADDRESS -p$MASTER_PORT)
    pg_last_xlog_receive_location=$($PSQL -U $SLAVE_USER -t -d postgres \
        -c "SELECT pg_last_xlog_receive_location()" \
        -h$SLAVE_ADDRESS -p$SLAVE_PORT)
    pg_last_xlog_replay_location=$($PSQL -U $SLAVE_USER -t -d postgres \
        -c "SELECT pg_last_xlog_replay_location()" \
        -h$SLAVE_ADDRESS -p$SLAVE_PORT)

    sent_location=${sent_location##*/}
    pg_current_xlog_location=${pg_current_xlog_location##*/}
    pg_last_xlog_receive_location=${pg_last_xlog_receive_location##*/}
    pg_last_xlog_replay_location=${pg_last_xlog_replay_location##*/}

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
        return 1
    fi

    return 0
}

function check
{
  let send_receive_lag=16#$sent_location-16#$pg_last_xlog_receive_location
  let current_sent_lag=16#$pg_current_xlog_location-16#$sent_location
  let replay_receive_lag=16#$pg_last_xlog_replay_location-16#$pg_last_xlog_receive_location

  if [ -n "$DEBUG" ]
  then
      echo send_receive_lag:$send_receive_lag
      echo current_sent_lag:$current_sent_lag 
      echo replay_receive_lag:$replay_receive_lag
  fi
}

function report
{

    if [ $send_receive_lag -gt $SEND_RECEIVE_LAG_MAX ]
    then
        error_report "WARN" "SEND_RECEIVE_LAG -gt $SEND_RECEIVE_LAG_MAX : $send_receive_lag"
    fi

    if [ $current_sent_lag -gt $CURRENT_SENT_LAG_MAX ]
    then
        error_report "WARN" "CURRENT_SENT_LAG -gt $CURRENT_SENT_LAG_MAX : $current_sent_lag"
    fi

    if [ $replay_receive_lag -gt $REPLAY_RECEIVE_LAG_MAX ]
    then
        error_report "WARN" "REPLAY_RECEIVE_LAG -g $REPLAY_RECEIVE_LAG_MAX : $replay_receive_lag"
    fi
}

function usage
{
    echo """
    $0 -- monitor postgresql's replication


    --OPTIONS--
    -h         this message
    -D         do debug, show debug info out
    -c FILE    indicate the configuration file FILE, default is repl_mon.conf in current directory.
    -l FILE    write log to FILE, default is STDOUT


    eg:
          $0 -c my_replication_mon.conf -l ./replication_monitor.log
    """
}

function parse_args
{
    while getopts "hDc:l:" option
    do
        case $option in 
            h) usage
                exit 0
                ;;
            D) DEBUG=TRUE
                ;;
            c) CONF=$OPTARG
                ;;
            l) LOG=$OPTARG
                ;;
            *) error_report "ERROR" "Invalid argument : $option"
                exit 1
                ;;
        esac
    done

    if [ -n "$CONF" ]
    then
        source $CONF
    else
        source repl_mon.conf
    fi

    if [ -n "$LOG" ]
    then
        exec > $LOG
        exec 2 > $LOG
    fi
}


# --------------- Main -------------- #
parse_args "$@"
get_status
check
report
# --------------- END --------------- #
