#!/bin/bash

run_container() {
  container_name=$1

  echo "[$(date)] [$container_name] Running tests for $container_name"
  echo "[$(date)] [$container_name] Removing done files for $container_name"
  rm -r /home/debian/tmp/$container_name/done/*
  echo "[$(date)] [$container_name] Copying 10'000 files to import directory for $container_name"
  cp /home/debian/tmp/10000/* /home/debian/tmp/$container_name/import/
  echo "[$(date)] [$container_name] Waiting for 30 seconds"
  sleep 30
  echo "[$(date)] [$container_name] Cleaning imported files for $container_name"
  rm -r /home/debian/tmp/$container_name/done/*
  echo "[$(date)] [$container_name] Finished tests for $container_name"
}

# Paare aus einem JVM- und einem nativen Framework, die keinen Core teilen
container_pairs=(
  "spring-jvm quarkus-native"
  "quarkus-jvm micronaut-native"
  "micronaut-jvm spring-native"
)

# Intervall in Sekunden zwischen den Start der Paare
interval=5

# Paare parallel testen
for pair in "${container_pairs[@]}"; do
  jvm_container=$(echo $pair | cut -d' ' -f1)
  native_container=$(echo $pair | cut -d' ' -f2)

  echo "[$(date)] Starting tests for pair: $jvm_container and $native_container"

  run_container $jvm_container &
  run_container $native_container &

  wait

  echo "[$(date)] Finished tests for pair: $jvm_container and $native_container"
  echo "[$(date)] Waiting for $interval seconds before running the next pair"
  sleep $interval

done

echo "[$(date)] All tests completed"
