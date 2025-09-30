R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

USERID=$(id -u)

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$(basename "$0" .sh)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" 

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

dnf module disable redis -y &>>$LOG_FILE
VALIDATE $? "Disiabling"

dnf module enable redis:7 -y &>>$LOG_FILE
VALIDATE $? "Enabling redis:7"

dnf install redis -y &>>$LOG_FILE
VALIDATE $? "Intalled redis"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf
VALIDATE $? "allowing remote connections to redis"

systemctl enable mongod &>>$LOG_FILE
VALIDATE $? "Enable redis"

systemctl start redis &>>$LOG_FILE
VALIDATE $? "Start redis"