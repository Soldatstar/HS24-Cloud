#!/bin/bash

# Logging-Funktion
log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') [INFO]: $1"
}

# Wiederhole den Vorgang 100 Mal
for i in {1..100}
do
  log "Creating container (Iteration $i)"
  container_id=$(sudo docker create -v /home/debian/tmp/micronaut-native/import:/import -v /home/debian/tmp/micronaut-native/done:/done cr.gitlab.fhnw.ch/ip5-24vt/fileimporter/micronaut_native:micronaut-native-image-simplified)
  
  log "Starting container (Iteration $i)"
  sudo docker start "$container_id" > /dev/null 2>&1


  # Stoppe den Container
  sudo docker stop "$container_id" > /dev/null 2>&1

  # Lösche den Container
  sudo docker rm "$container_id" > /dev/null 2>&1
done
