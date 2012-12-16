pg_replication_monitor
======================

postgresql replication monitor

I use four variable in postgresql to judgment the health of replication:

- **sent_location** (in master) 

- **pg_current_xlog_location()** (in master)

- **pg_last_xlog_receive_location()** (in slave)

- **pg_last_xlog_replay_location()** (in slave)


to produce three indicators:

- **send_receive_lag** : indicate the send-receive delay between master and slave

- **current_sent_lag** : indicate the write-send delay of master

- **replay_receive_lag** : indicate the receive-replay delay of slave

You can set Warn and Critical threshold in configuration file as needed

You can also specify a reporter program to do the report, such as SMS message sender.
