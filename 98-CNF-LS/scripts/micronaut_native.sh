#!/bin/bash

log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') [INFO]: $1"
}

total_startup_time=0
read_success=0
startup_times=()
log_file="startup_times_log.txt"
times_file="sorted_startup_times_micronaut_native.txt"

# Wiederhole den Vorgang
while (( read_success < 100 ))
do
  container_id=$(sudo docker create -v /home/debian/tmp/micronaut-native/import:/import -v /home/debian/tmp/micronaut-native/done:/done cr.gitlab.fhnw.ch/ip5-24vt/fileimporter/micronaut_native:micronaut-native-image-simplified)
  sudo docker start "$container_id" > /dev/null 2>&1
  log "Starting container: $container_id (Iteration $((read_success + 1)))"
  
  max_retries=10
  retry_count=0

  # Versuche, die Logs zu lesen, bis es klappt oder die maximale Anzahl an Versuchen erreicht ist
  while true; do
    container_log=$(sudo docker logs "$container_id" 2>&1)
    startup_line=$(echo "$container_log" | grep -oP '.*Startup completed in \d+ms.*')
  
    # Wenn die Startup-Zeit gefunden wurde, logge nur diese Zeile und verlasse die Schleife
    if [[ -n "$startup_line" ]]; then
      log "$startup_line"
      startup_time=$(echo "$startup_line" | grep -oP '(?<=Startup completed in )\d+ms' | awk '{print $1}')
      startup_time_ms=$(echo "$startup_time" | tr -d 'ms')
      log "Startup time found: $startup_time_ms"
      total_startup_time=$((total_startup_time + startup_time_ms))
      startup_times+=("$startup_time_ms")  
      read_success=$((read_success + 1))
      break
    else
      log "No startup time found. Retrying..."
      sleep 1
      retry_count=$((retry_count + 1))

      # Wenn die maximale Anzahl an Versuchen erreicht ist, breche ab
      if (( retry_count >= max_retries )); then
        log "Max retries reached. Aborting this container..."
        break
      fi
    fi
  done

  sudo docker stop "$container_id" > /dev/null 2>&1
  sudo docker rm "$container_id" > /dev/null 2>&1
  log "Removing container: $container_id"

done

# Berechnung des Durchschnitts
average_startup_time=$(echo "scale=2; $total_startup_time / $read_success" | bc)

# Berechnung des Medians
echo "${startup_times[@]}" | tr ' ' '\n' | sort -n > $times_file

median_startup_time=$(awk '
  { a[i++]=$1 }
  END {
    n = i
    if (n % 2 == 1) {
      print a[int(n/2)]
    } else {
      mid = n / 2
      print (a[mid-1] + a[mid]) / 2
    }
  }
' $times_file)

log "Sorted startup times (for median calculation):"
cat $times_file

log "Total startup time for $read_success iterations: $total_startup_time ms"
log "Average startup time for $read_success iterations: $average_startup_time ms"
log "Median startup time for $read_success iterations: $median_startup_time ms"

# Schreibe die letzten Logs (total, average, median) in eine lokale Datei
{
  echo "$(date +'%Y-%m-%d %H:%M:%S') [INFO]: Total startup time for $read_success iterations: $total_startup_time ms using micronaut_native"
  echo "$(date +'%Y-%m-%d %H:%M:%S') [INFO]: Average startup time for $read_success iterations: $average_startup_time ms using micronaut_native"
  echo "$(date +'%Y-%m-%d %H:%M:%S') [INFO]: Median startup time for $read_success iterations: $median_startup_time ms using micronaut_native"
} >> "$log_file"