#!/bin/bash

# Create a file called _set-env.sh and put your environment variables in here
./_set-env.sh

echo "REGION_1_CONSUMER_URL : $REGION_1_CONSUMER_URL"
echo "REGION_2_CONSUMER_URL : $REGION_2_CONSUMER_URL"
echo "REGION_1_PRODUCER_URL : $REGION_1_PRODUCER_URL"
echo "REGION_2_PRODUCER_URL : $REGION_2_PRODUCER_URL"

TIMESTAMP=`date -u +"%Y-%m-%dT%H:%M:%SZ"`

echo "Calling the event recovery from the consumer app from region 2 with the timestamp matching the last generated events."
curl -X GET "$REGION_2_CONSUMER_URL/event?source=region-1&fromEventNumber=21" -H "Content-Type:application/json" -k

echo "Validating the transaction database has a total of 40 events registered"
TRANSACTION_COUNT=`curl -X GET $REGION_2_CONSUMER_URL/transaction -H "Content-Type:application/json" -k`
echo "Transaction count : $TRANSACTION_COUNT"
if [ "$TRANSACTION_COUNT" != "40" ]
then
  echo "Transaction count does not match."
  exit 1
fi