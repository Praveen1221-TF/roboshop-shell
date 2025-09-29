#!/bin/bash
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

USERID=$(id -u)

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$(basename "$0" .sh)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" 
MONGODB_HOST=mongodb.practicedev.shop
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo "script started excuted at : $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then        
    echo "Error: please run the script with root user"
    exit 1
fi

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$R .... $2  failure $N" | tee -a $LOG_FILE
         exit 1
    else        
        echo -e "$G .... $2 success $N" | tee -a $LOG_FILE

    fi
}   

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disiabling"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling NJ20"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Intalled NDJS"
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop  &>>$LOG_FILE
    VALIDATE $? "Adding system User"
else        
    echo -e "$G skipping....$N"
fi        

mkdir -p /app &>>$LOG_FILE
VALIDATE $? "Creating App Direactory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE    
VALIDATE $? "Getting catalogue repo"

cd /app 
VALIDATE $? "Changing to app direactory"

rm -rf /app/*
VALIDATE $? "removing existing code"

unzip /tmp/catalogue.zip  &>>$LOG_FILE
VALIDATE $? "Unzipping catalogue"

npm install  &>>$LOG_FILE
VALIDATE $? "NPM Installed"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service  &>>$LOG_FILE
VALIDATE $? "Copied Systemd Catalogue.service"

systemctl daemon-reload  &>>$LOG_FILE
systemctl enable catalogue  &>>$LOG_FILE
VALIDATE $? "Enabling catalogue"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "COPY mongo repo"

dnf install mongodb-mongosh -y  &>>$LOG_FILE
VALIDATE $? "Installed mongodb-mongosh"

INDEX=$(mongosh mongodb.practicedev.shop --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")
if [ $INDEX -le 0 ]; then
    mongosh --host $MONGODB_HOST </app/db/master-data.js  &>>$LOG_FILE
    VALIDATE $? "Load Catalogue Products"
else 
    echo -e "catalogue products already loaded $G......Skipping $N"
fi

systemctl restart catalogue  &>>$LOG_FILE
VALIDATE $? "Restarted"

