#include <SPI.h>
#include <mcp2515.h>

#define SLAVE_ID 0x0F6
#define PIN_OUT 3
#define CUSTOM_DELAY 100               // 측정 주기 [ms]
#define WHEEL_CIRCUMFERENCE_CM 20.083 // 바퀴 둘레 [cm]
#define PULSES_PER_REV 20             // 회전당 펄스 수

MCP2515 mcp2515(9);
volatile unsigned int pulseCount = 0;
struct can_frame canMsg;

// 펄스 카운팅 인터럽트 함수
void isrCount() {
  pulseCount++;
}

void setup() {
  Serial.begin(115200);

  // CAN 초기화
  mcp2515.reset();
  mcp2515.setBitrate(CAN_1000KBPS, MCP_16MHZ);
  mcp2515.setNormalMode();

  // 펄스 입력 핀 및 인터럽트 설정
  pinMode(PIN_OUT, INPUT);
  attachInterrupt(digitalPinToInterrupt(PIN_OUT), isrCount, RISING);

  // CAN 메시지 초기화
  canMsg.can_id = SLAVE_ID;
  canMsg.can_dlc = 8;
  memset(canMsg.data, 0x00, 8);
}

void loop() {
  // 무한 반복
  while (true) {
    unsigned long startTime = millis();
    delay(CUSTOM_DELAY);  // 일정 주기 대기

    // 측정 구간 동안 펄스 수 복사 및 리셋
    noInterrupts();
    unsigned int pulses = pulseCount;
    pulseCount = 0;
    interrupts();

    // 시간 간격 계산
    float intervalSec = CUSTOM_DELAY / 1000.0;

    // 회전수 및 속도 계산
    float revs = pulses / (float)PULSES_PER_REV;
    float rpm = (revs / intervalSec) * 60;
    float speed = revs * WHEEL_CIRCUMFERENCE_CM / intervalSec;

    // 속도값 분해 (CAN 전송용)
    int int1_spd = speed;
    int int2_spd = round((speed - int1_spd) * 100);

    canMsg.data[0] = int1_spd / 256;
    canMsg.data[1] = int1_spd % 256;
    canMsg.data[2] = int2_spd;

    // 디버깅 출력
    Serial.print("Pulses: ");
    Serial.print(pulses);
    Serial.print(" | RPM: ");
    Serial.print(rpm);
    Serial.print(" | Speed: ");
    Serial.print(speed);
    Serial.println(" cm/s");

    Serial.print("CAN Data: ");
    for (int i = 0; i < canMsg.can_dlc; i++) {
      Serial.print("0x");
      if (canMsg.data[i] < 0x10) Serial.print("0");
      Serial.print(canMsg.data[i], HEX);
      Serial.print(" ");
    }
    Serial.println();

    // CAN 메시지 전송
    mcp2515.sendMessage(&canMsg);
  }
}
