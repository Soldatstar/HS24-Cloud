#!/bin/bash

log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') [INFO]: $1"
}

total_startup_time=0
read_success=0
startup_times=()
log_file="startup_times_log.txt"
times_file="sorted_startup_times_spring_jvm.txt"

# Wiederhole den Vorgang
while (( read_success < 100 ))
do
  container_id=$(sudo docker create -v /home/debian/tmp/spring-jvm/import:/import -v /home/debian/tmp/spring-jvm/done:/done cr.gitlab.fhnw.ch/ip5-24vt/fileimporter/spring_jvm:spring-native-image-simplified)
  sudo docker start "$container_id" > /dev/null 2>&1
  log "Starting container: $container_id (Iteration $((read_success + 1)))"
  
  max_retries=20
  retry_count=0

  # Versuche, die Logs zu lesen, bis es klappt oder die maximale Anzahl an Versuchen erreicht ist
  while true; do
    container_log=$(sudo docker logs "$container_id" 2>&1)
    startup_line_log=$(echo "$container_log" | grep -oP '.*Started FileimporterApplication in \d+(\.\d+)? seconds.*')
    startup_line=$(echo "$container_log" | grep -oP 'Started FileimporterApplication in \d+(\.\d+)? seconds')

    # Wenn die vollständige Startup-Zeile gefunden wurde, logge diese und verlasse die Schleife
    if [[ -n "$startup_line" ]]; then
      log "$startup_line_log"  # Ganze Zeile loggen
      startup_time_sec=$(echo "$startup_line" | grep -oP '\d+(\.\d+)?' | head -n 1)
      startup_time_ms=$(echo "$startup_time_sec * 1000 / 1" | bc)
      log "Startup time found: $startup_time_ms ms"
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
  echo "$(date +'%Y-%m-%d %H:%M:%S') [INFO]: Total startup time for $read_success iterations: $total_startup_time ms using spring_jvm"
  echo "$(date +'%Y-%m-%d %H:%M:%S') [INFO]: Average startup time for $read_success iterations: $average_startup_time ms using spring_jvm"
  echo "$(date +'%Y-%m-%d %H:%M:%S') [INFO]: Median startup time for $read_success iterations: $median_startup_time ms using spring_jvm"
} >> "$log_file"
