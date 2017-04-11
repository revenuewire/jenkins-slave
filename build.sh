#!/bin/bash

docker build --pull -t revenuewire/jenkins-slave:latest .
docker push revenuewire/jenkins-slave:latest