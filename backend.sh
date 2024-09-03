#!/bin/bash

USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOGFILE=/tmp/$SCRIPT_NAME-$TIMESTAMP.log
R="\e[31m"
G="\e[32m"
N="\e[0m"
echo "please enter DB password:"
read -s mysql_root_password 


VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2.....$R FAILIRE $N"
        exit 1
    else
        echo -e "$2.....$G SUCCESS $N"
    fi
}
if [ $USERID -ne 0 ]
then 
     echo "please run this script with root access."
     exit 1
else
     echo "you are super user."
fi

dnf module disable nodejs -y &>>$LOGFILE
VALIDATE $? "disabling nodejs"

dnf module enable nodejs:20 -y &>>$LOGFILE
VALIDATE $? "enabling nodejs:20"

dnf install nodejs -y &>>$LOGFILE
VALIDATE $? "Installing nodejs"

id expense &>>$LOGFILE
if [ $? -ne 0 ]
then
    useradd expense &>>$LOGFILE
    VALIDATE $? "creating expense user"
else
    echo -e "Expense user is already created....$Y SKIPPING $N"
fi

mkdir  -p /app &>>$LOGFILE
VALIDATE $? "creating app directory"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOGFILE
VALIDATE $? "download backend file"

cd /app
rm -rf /app/*
unzip /tmp/backend.zip &>>$LOGFILE
VALIDATE $? "unzip backend file"

npm install &>>$LOGFILE
VALIDATE $? "Installing npm dependencies"

cp /home/ec2-user/expense-shell/backend.service /etc/systemd/system/backend.service &>>$LOGFILE
VALIDATE $? "copied backend.service"

systemctl daemon-reload &>>$LOGFILE
VALIDATE $? "deamon-reloading"

systemctl start backend &>>$LOGFILE
VALIDATE $? "starting backend"

systemctl enable backend &>>$LOGFILE
VALIDATE $? "enabling backend"

dnf install mysql -y &>>$LOGFILE
VALIDATE $? "Installing mysql"

mysql -h 172.31.22.129 -uroot -p${mysql_root_password} < /app/schema/backend.sql &>>$LOGFILE
VALIDATE $? "setting up DB password"

systemctl restart backend &>>$LOGFILE
VALIDATE $? "restarting backend"




