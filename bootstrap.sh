#!/bin/bash

kubectl apply -f bootstrap/ --namespace=kube-system
helm init --service-account deployer
