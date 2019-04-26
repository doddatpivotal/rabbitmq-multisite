#!/usr/bin/env bash

check_services_completion()
{
    cf target -s $1

    # Wait until services are ready
    while cf services | grep 'create in progress'
    do
      sleep 20
      echo "Waiting for services to initialize..."
    done

    # Check to see if any services failed to create
    if cf services | grep 'create failed'; then
      echo "Service initialization - failed. Exiting."
      return 1
    fi
    echo "Service initialization - successful"
}

# Create services
cf create-space space-1
cf create-space space-2
cf create-space space-3
cf target -s space-1
cf create-service p.rabbitmq single-node-3.7 broker
cf create-service p.mysql db-small event-store-db
cf target -s space-2
cf create-service p.rabbitmq single-node-3.7 broker
cf create-service p.mysql db-small event-store-db
cf target -s space-3
cf create-service p.mysql db-small transaction-db

check_services_completion "space-1"
check_services_completion "space-2"
check_services_completion "space-3"


# Build apps
if [[ $BUILD == "Y" ]]; then
  ./mvnw clean install -DskipTests
fi


# Push apps
PRODUCER_APP_BIN=src/producer/target/producer-0.0.1-SNAPSHOT.jar
CONSUMER_APP_BIN=src/consumer/target/consumer-0.0.1-SNAPSHOT.jar

cf target -s space-1

cf push --no-start -p $PRODUCER_APP_BIN -n rabbitmq-multisite-producer-region-1  producer
cf set-env producer PRODUCER_SOURCE region-1
cf bind-service producer broker
cf start producer

cf push --no-start -p CONSUMER_APP_BIN -n rabbitmq-multisite-producer-region-1  consumer
cf set-env consumer CONSUMER_SOURCE region-1
cf set-env consumer TRANSACTION_DATASOURCE_JDBCURL $TRANSACTION_DATASOURCE_JDBC
cf set-env consumer SPRING_JPA_PROPERTIES_HIBERNATES_DIALECT org.hibernate.dialect.MariaDBDialect
cf bind-service consumer broker
cf bind-service consumer event-store-db
cf start consumer

cf target -s space-2

cf push --no-start -p $PRODUCER_APP_BIN -n rabbitmq-multisite-producer-region-2  producer
cf set-env producer PRODUCER_SOURCE region-2
cf bind-service producer broker
cf start producer

cf push --no-start -p CONSUMER_APP_BIN -n rabbitmq-multisite-producer-region-2  consumer
cf set-env consumer CONSUMER_SOURCE region-2
cf set-env consumer TRANSACTION_DATASOURCE_JDBCURL $TRANSACTION_DATASOURCE_JDBC
cf set-env consumer SPRING_JPA_PROPERTIES_HIBERNATES_DIALECT org.hibernate.dialect.MariaDBDialect
cf bind-service consumer broker
cf bind-service consumer event-store-db
cf start consumer
