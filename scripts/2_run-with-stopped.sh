#!/bin/bash

# Create a file called _set-env.sh and put your environment variables in here
./_set-env.sh

echo "REGION_1_CF_API : $REGION_1_CF_API"
echo "REGION_1_CF_USERNAME : $REGION_1_CF_USERNAME"
echo "REGION_1_CF_ORG : $REGION_1_CF_ORG"
echo "REGION_1_CF_SPACE : $REGION_1_CF_SPACE"
echo "REGION_1_CONSUMER_URL : $REGION_1_CONSUMER_URL"
echo "REGION_2_CONSUMER_URL : $REGION_2_CONSUMER_URL"
echo "REGION_1_PRODUCER_URL : $REGION_1_PRODUCER_URL"
echo "REGION_2_PRODUCER_URL : $REGION_2_PRODUCER_URL"

echo "Starting the consumer app from region 1."
cf login -a $REGION_1_CF_API -u $REGION_1_CF_USERNAME -p $REGION_1_CF_PASSWORD -o $REGION_1_CF_ORG -s $REGION_1_CF_SPACE --skip-ssl-validation && \

echo "Stopping the consumer app from region 1."
cf stop consumer
sleep 20

TIMESTAMP=`date -u +"%Y-%m-%dT%H:%M:%SZ"`

echo "Generating 10 events for each producer app."
for i in {21..30}
do
  curl -X POST $REGION_1_PRODUCER_URL/event?eventNumber=$i -H "Content-Type:application/json" -d "event $i - to recover" -k
  echo "sending $i"
done

for i in {31..40}
do
  curl -X POST $REGION_2_PRODUCER_URL/event?eventNumber=$i -H "Content-Type:application/json" -d "event $i" -k
  echo "sending $i"
done

echo "Validating the transaction database has a total of 30 events registered"
TRANSACTION_COUNT=`curl -X GET $REGION_2_CONSUMER_URL/transaction -H "Content-Type:application/json" -k`
echo "Transaction count : $TRANSACTION_COUNT"
if [ "$TRANSACTION_COUNT" != "30" ]
then
  echo "Transaction count does not match."
  exit 1
fi
