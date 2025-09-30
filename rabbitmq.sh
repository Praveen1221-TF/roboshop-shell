R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

USERID=$(id -u)

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$(basename "$0" .sh)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" 

mkdir -p $LOGS_FOLDER
SCRIPT_DIR=$(PWD)
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

cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
VALIDATE $? "Adding rabbitMQ repo"

dnf install rabbitmq-server -y &>>$LOG_FILE
VALIDATE $? "Installing"

systemctl enable rabbitmq-server &>>$LOG_FILE
VALIDATE $? "enabling rabbitMQ"

systemctl start rabbitmq-server &>>$LOG_FILE
VALIDATE $? "RabbitMQ Started"

rabbitmqctl add_user roboshop roboshop123
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"
VALIDATE $? "settingup permissions"