docker build -q -t xthl .
docker run --rm --name xthl -d -p 8080:8080 -e READ_MEMORY_API=http://localhost:8080/api/v1/debug/readMemory -e WRITE_MEMORY_API=http://localhost:8080/api/v1/debug/writeMemory xthl

sleep 5

RESULT=`curl -s --header "Content-Type: application/json" \
  --request POST \
  --data '{"id":"abcd", "opcode":227,"state":{"a":85,"b":170,"c":85,"d":170,"e":170,"h":119,"l":51,"flags":{"sign":false,"zero":false,"auxCarry":false,"parity":false,"carry":true},"programCounter":1660,"stackPointer":1729,"cycles":1,"interruptsEnabled":true}}' \
  http://localhost:8080/api/v1/execute`
EXPECTED='{"id":"abcd", "opcode":227,"state":{"a":85,"b":170,"c":85,"d":170,"e":170,"h":119,"l":17,"flags":{"sign":false,"zero":false,"auxCarry":false,"parity":false,"carry":true},"programCounter":1660,"stackPointer":1729,"cycles":19,"interruptsEnabled":true}}'

docker kill xthl

DIFF=`diff <(jq -S . <<< "$RESULT") <(jq -S . <<< "$EXPECTED")`

if [ $? -eq 0 ]; then
    echo -e "\e[32mXTHL Test Pass \e[0m"
    exit 0
else
    echo -e "\e[31mXTHL Test Fail  \e[0m"
    echo "$RESULT"
    echo "$DIFF"
    exit -1
fi