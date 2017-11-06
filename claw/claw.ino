#include <Wire.h>
#include <Adafruit_PWMServoDriver.h>
#include <Servo.h>

Adafruit_PWMServoDriver pwm = Adafruit_PWMServoDriver(0x40);

//Servo base;
#define arr_len( x )  ( sizeof( x ) / sizeof( *x ) )
#define Min1 110
#define Max1 490
//430
uint16_t maxes[7] = {-1, 490, 450, 480, 490, 510, 340};
uint16_t mins[7] = {-1, 110, 450, 160, 120, 110, 260};
uint16_t currents[arr_len(mins)];
uint16_t incs[9] = {-1,1,1,1,1,1,1,1,1};
void setup() {
  // put your setup code here, to run once:
  //base.write(0);
  Serial.begin(9600);
  pwm.begin();
  pwm.setPWMFreq(50);
  Serial.println(mins[1]);
  Serial.println(maxes[1]);
  for (int i = 0; i < arr_len(mins); i++) {
    currents[i] = mins[i];
  }
  //pwm.setPWM(3,0, 160);
}

void increment(int i) {
  currents[i] += incs[i];
  if (currents[i] > maxes[i]) {
    currents[i] = maxes[i] - abs(incs[i]);
    incs[i] *= -1;
  } else if (currents[i] < mins[i]) {
    currents[i] = mins[i] + abs(incs[i]);
    incs[i] *= -1;
  }

}

int d = 15;
int clawMinDeg = 0;
int clawMaxDeg = 60;
int baseMinDeg = 0;
int baseMaxDeg = 180;


int basePos = 0;
int baseInc = 1;
int clawPos = 0;
int clawInc = 1;

//int i = 6;

void loop() {
  for (int i = 1; i < arr_len(mins); i++) {
    increment(i);
    //pwm.setPWM(i, 0, (mins[i] + maxes[i])/2);
    pwm.setPWM(i, 0, currents[i]);
  }
  delay(10);
  // put your main code here, to run repeatedly:
  //for (uint16_t pulselen = mins[i]; pulselen < maxes[i]; pulselen++) {
   // delay(10);
    //pwm.setPWM(i, 0, pulselen);
  //}
  //for (uint16_t pulselen = maxes[i]; pulselen > mins[i]; pulselen--) {
    //delay(10);
    //pwm.setPWM(i, 0, pulselen);
  //}
  
}

void incClaw() {
  clawPos += clawInc;
  if (clawPos > clawMaxDeg) {
    clawPos = clawMaxDeg - abs(clawInc);
    clawInc *= -1;
  } else if (clawPos < clawMinDeg) {
    clawPos = clawMinDeg + abs(clawInc);
    clawInc *= -1;
  }
  //claw.write(clawPos);
}

