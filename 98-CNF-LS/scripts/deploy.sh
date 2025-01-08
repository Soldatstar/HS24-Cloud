#!/bin/bash

# Docker Login
echo "Logging into Docker registry..."
sudo docker login -u damjan.mlinar@students.fhnw.ch cr.gitlab.fhnw.ch

# Docker Pull Befehle
echo "Pulling Docker images..."

sudo docker pull cr.gitlab.fhnw.ch/ip5-24vt/fileimporter/quarkus_jvm:quarkus-native-image-simplified
sudo docker pull cr.gitlab.fhnw.ch/ip5-24vt/fileimporter/quarkus_native_micro:quarkus-native-image-simplified

sudo docker pull cr.gitlab.fhnw.ch/ip5-24vt/fileimporter/micronaut_jvm:micronaut-native-image-simplified
sudo docker pull cr.gitlab.fhnw.ch/ip5-24vt/fileimporter/micronaut_native:micronaut-native-image-simplified

sudo docker pull cr.gitlab.fhnw.ch/ip5-24vt/fileimporter/spring_jvm:spring-native-image-simplified
sudo docker pull cr.gitlab.fhnw.ch/ip5-24vt/fileimporter/spring_native:spring-native-image-simplified

echo "Docker images pulled successfully."
