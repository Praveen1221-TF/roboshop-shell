#!/bin/bash

AMI_ID='ami-09c813fb71547fc4f'
SG_ID='sg-08223f8b4a8582c4a'

for instance in $@

do
    INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type t3.micro --count 2 --subnet-id subnet-051e2fce18c732083 --security-group-ids $SG_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" --query 'Instances[0].InstanceId' --output text)

    if [$instance != "frontend"]; then
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)
    else
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)
    fi

   echo "$instance : $ip" 
           
done