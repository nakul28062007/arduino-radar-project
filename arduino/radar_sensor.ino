#include <Servo.h>

Servo radarServo;

const int trigPin = 9;
const int echoPin = 10;
const int servoPin = 6;

int angle = 0;
int step = 1;

void setup() {
  Serial.begin(9600);
  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);
  radarServo.attach(servoPin);
  radarServo.write(angle);
  delay(1000);
}

long getDistance() {
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);

  long duration = pulseIn(echoPin, HIGH);
  return duration * 0.034 / 2;
}

void loop() {
  long dist = getDistance();

  Serial.print(angle);
  Serial.print(",");
  Serial.println(dist);

  delay(45);

  angle += step;
  if (angle >= 180 || angle <= 0) {
    step = -step;
    delay(150);
  }

  radarServo.write(angle);
}