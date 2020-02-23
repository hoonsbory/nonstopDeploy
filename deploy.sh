#!/bin/bash


BASE_PATH=/home/ubuntu/app/travis/build
BUILD_PATH=$(ls $BASE_PATH/target/*.jar)
JAR_NAME=$(basename $BUILD_PATH)

 # 현재 실행중인 서버의 포트를 조회. 추가로 실행할 서버의 포트 선정            $
    runPortCount=$(netstat -anp | grep LISTEN | grep 8444)
    runPortCount2=$(netstat -anp | grep LISTEN | grep 8443)
if [ $runPortCount -z ] && [ $runPortCount2 -z ]; then
        echo "실행중인 포트가 없습니다."
        SET=set1
        IDLE_PORT=8443
elif [ $runPortCount -z ]; then
        echo "8443포트로 실행중입니다."
        SET=set2
        IDLE_PORT=8444
elif [ $runPortCount2 -z ]; then
        echo "8444포트로 실행중입니다."
        SET=set1
        IDLE_PORT=8443
fi

echo "port == $SET"

IDLE_APPLICATION=$SET-springboot-webservice.jar
IDLE_APPLICATION_PATH=$BASE_PATH/$IDLE_APPLICATION

echo "> $IDLE_APPLICATION"

ln -Tfs $BUILD_PATH $IDLE_APPLICATION_PATH


echo "> $IDLE_PROFILE 에서 구동중인 애플리케이션 pid 확인"
IDLE_PID=$(pgrep -f $IDLE_APPLICATION)

if [ -z $IDLE_PID ]
then
  echo "> 현재 구동중인 애플리케이션이 없으므로 종료하지 않습니다."
else
  echo "> kill -15 $IDLE_PID"
  kill -15 $IDLE_PID
  sleep 5
fi

echo "> $IDLE_PROFILE 배포"
nohup java -jar -Dspring.profiles.active=$SET $IDLE_APPLICATION_PATH > /dev/null 2> /dev/null < /dev/null &


echo "> $IDLE_PROFILE 10초 후 Health check 시작"
echo "> curl -s http://localhost:$IDLE_PORT/health "
sleep 10

for retry_count in {1..10}
do
  response=$(curl -s http://localhost:$IDLE_PORT/profile)
  up_count=$(echo $response | grep 'set' | wc -l)

  if [ $up_count -ge 1 ]
  then # $up_count >= 1 ("set" 문자열이 있는지 검증)
      echo "> Health check 성공"
      break
  else
      echo "> Health check의 응답을 알 수 없거나 혹은 status가 UP이 아닙니다."
      echo "> Health check: ${response}"

 if [ $retry_count -eq 10 ]
  then
    echo "> Health check 실패. "
    echo "> Nginx에 연결하지 않고 배포를 종료합니다."
    exit 1
  fi

  echo "> Health check 연결 실패. 재시도..."
  sleep 10
done

echo "> 스위칭"
sleep 10

echo "set \$service_url http://127.0.0.1:${IDLE_PORT};" |sudo tee /etc/nginx/conf.d/service-url.inc


echo "> Nginx Reload"
sudo service nginx reload

sleep 10

 if [ $IDLE_PORT = "8444" ]
 then
    echo "8443포트를 종료합니다"
    IDLE_PID=$(pgrep -f set1-springboot-webservice.jar)
    kill -15 $IDLE_PID
 else
    echo "8444포트를 종료합니다"
    IDLE_PID=$(pgrep -f set2-springboot-webservice.jar)
    kill -15 $IDLE_PID
 fi

