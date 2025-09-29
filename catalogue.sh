#!/bin/bash
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

USERID=$(id -u)

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$(basename "$0" .sh)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" 
MONGODB_HOST=practicedev.shop

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

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop  &>>$LOG_FILE
VALIDATE $? "Adding system User"

mkdir /app &>>$LOG_FILE
VALIDATE $? "Creating App Direactory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE    
VALIDATE $? "Getting catalogue repo"

cd /app 
VALIDATE $? "Changing to app direactory"

unzip /tmp/catalogue.zip  &>>$LOG_FILE
VALIDATE $? "Unzipping catalogue"

npm install  &>>$LOG_FILE
VALIDATE $? "NPM Installed"

systemctl daemon-reload  &>>$LOG_FILE
VALIDATE $? "Deemon-Reload"

systemctl enable catalogue  &>>$LOG_FILE
VALIDATE $? "Enabling catalogue"

cp catalogue.service /etc/systemd/system/catalogue.service  &>>$LOG_FILE
VALIDATE $? "Copied Systemd Catalogue.service"

dnf install mongodb-mongosh -y  &>>$LOG_FILE
VALIDATE $? "Installed mongodb-mongosh"

mongosh --host $MONGODB_HOST </app/db/master-data.js  &>>$LOG_FILE
VALIDATE $? "Load Catalogue Products"

systemctl restart catalogue  &>>$LOG_FILE
VALIDATE $? "Restarted"

