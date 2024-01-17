#!/bin/bash
#
kubectl apply -f mysql-secret.yaml
kubectl apply -f mysql-pv.yaml
kubectl apply -f mysql.yaml
kubectl apply -f wordpress-pv.yaml
kubectl apply -f wordpress-deployment.yaml