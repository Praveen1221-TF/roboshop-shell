#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-08223f8b4a8582c4a"
ZONE_ID="Z0525756Y7HMXRRYAT2T"
DOMAIN_NAME="practicedev.shop"

for instance in $@

do
    INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type t3.micro --count 2 --subnet-id subnet-051e2fce18c732083 --security-group-ids $SG_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" --query 'Instances[0].InstanceId' --output text)

    if [ $instance != "frontend" ]; then
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)
        RECORD_NAME="$instance.$DOMAIN_NAME"
    else
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)
        RECORD_NAME="$DOMAIN_NAME"
    fi

   echo "$instance : $IP" 
           

aws route53 change-resource-record-sets \
  --hosted-zone-id Z0525756Y7HMXRRYAT2T	 \
  --change-batch '
  {
    "Comment": "Testing creating a record set"
    ,"Changes": [{
      "Action"              : "UPSERT"
      ,"ResourceRecordSet"  : {
        "Name"              : "'$RECORD_NAME'"
        ,"Type"             : "A"
        ,"TTL"              : 1
        ,"ResourceRecords"  : [{
            "Value"         : "'$IP'"
        }]
      }
    }]
  }
  '
  done