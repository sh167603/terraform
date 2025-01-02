#!/bin/bash

export terraform_test_ip=$(terraform output -raw public_ip)
curl $terraform_test_ip:4000

if [ $? == 0 ]
  then echo sucess
fi
