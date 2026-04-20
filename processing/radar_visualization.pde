import processing.serial.*;

Serial myPort;
String data = "";
float distance, angle;
int maxDist = 40;

float lastDetectedAngle = -1;
float lastDetectedDist = -1;
int detectedTimer = 0;
int dotLifetime = 90;

// Trail effect
float[] trailAngles = new float[60];
int trailIndex = 0;

void setup() {
  size(800, 600);
  smooth();
  myPort = new Serial(this, "/dev/cu.usbserial-A5069RR4", 9600);
  myPort.bufferUntil('\n');
  
  // Fill trail with 0
  for (int i = 0; i < trailAngles.length; i++) {
    trailAngles[i] = 0;
  }
}

void draw() {
  background(0);
  
  // Title
  fill(0, 255, 0);
  textSize(22);
  textAlign(CENTER);
  text("RADAR SYSTEM", width / 2, 35);
  
  // Status bar at bottom
  fill(0, 200, 0);
  textSize(14);
  textAlign(LEFT);
  text("ANGLE: " + int(angle) + "°", 20, height - 15);
  textAlign(RIGHT);
  if (distance > 0 && distance < maxDist) {
    text("DISTANCE: " + int(distance) + " cm", width - 20, height - 15);
  } else {
    text("DISTANCE: -- cm", width - 20, height - 15);
  }
  
  // Object detected warning
  if (distance > 0 && distance < maxDist) {
    textAlign(CENTER);
    textSize(18);
    if (frameCount % 20 < 10) { // flashing effect
      fill(255, 0, 0);
      text("⚠ OBJECT DETECTED", width / 2, height - 15);
    }
  }

  pushMatrix();
  translate(width / 2, height - 60);
  drawTrail();
  drawRadar();
  drawDetected();
  popMatrix();
}

void drawTrail() {
  // Store current angle in trail
  trailAngles[trailIndex] = angle;
  trailIndex = (trailIndex + 1) % trailAngles.length;

  // Draw fading trail lines
  int radius = (height - 120);
  for (int i = 0; i < trailAngles.length; i++) {
    int age = (trailIndex - i + trailAngles.length) % trailAngles.length;
    float alpha = map(age, 0, trailAngles.length, 150, 0);
    stroke(0, 255, 0, alpha);
    strokeWeight(1.5);
    float tx = radius * cos(radians(trailAngles[i]));
    float ty = radius * sin(radians(trailAngles[i]));
    line(0, 0, -tx, -ty);
  }
}

void drawRadar() {
  noFill();
  strokeWeight(1);

  // Range arcs + labels
  stroke(0, 200, 0);
  int radius = (height - 120);
  for (int r = 1; r <= 4; r++) {
    int arcRadius = r * radius / 4;
    arc(0, 0, arcRadius * 2, arcRadius * 2, PI, TWO_PI);
    
    // Range labels
    fill(0, 180, 0);
    noStroke();
    textSize(11);
    textAlign(CENTER);
    text((maxDist / 4 * r) + "cm", 5, -(arcRadius + 4));
    noFill();
    stroke(0, 200, 0);
  }

  // Angle lines
  for (int a = 0; a <= 180; a += 30) {
    float x = radius * cos(radians(a));
    float y = radius * sin(radians(a));
    line(0, 0, -x, -y);
    
    // Angle labels
    fill(0, 180, 0);
    noStroke();
    textSize(11);
    textAlign(CENTER);
    float lx = (radius + 18) * cos(radians(a));
    float ly = (radius + 18) * sin(radians(a));
    text(a + "°", -lx, -ly);
    noFill();
    stroke(0, 200, 0);
  }

  // Sweep line
  stroke(0, 255, 0);
  strokeWeight(2);
  float sx = radius * cos(radians(angle));
  float sy = radius * sin(radians(angle));
  line(0, 0, -sx, -sy);
}

void drawDetected() {
  if (distance > 0 && distance < maxDist) {
    lastDetectedAngle = angle;
    lastDetectedDist = distance;
    detectedTimer = dotLifetime;
  }

  if (detectedTimer > 0 && lastDetectedAngle >= 0) {
    int radius = (height - 120);
    float mapped = map(lastDetectedDist, 0, maxDist, 0, radius);
    float x = mapped * cos(radians(lastDetectedAngle));
    float y = mapped * sin(radians(lastDetectedAngle));

    float alpha = map(detectedTimer, 0, dotLifetime, 0, 255);

    // Pulsing outer ring
    noFill();
    stroke(255, 0, 0, alpha * 0.5);
    strokeWeight(1.5);
    float pulse = map(sin(frameCount * 0.2), -1, 1, 20, 35);
    ellipse(-x, -y, pulse, pulse);

    // Main dot
    noStroke();
    fill(255, 0, 0, alpha);
    ellipse(-x, -y, 18, 18);

    // Distance label next to dot
    fill(255, 255, 0, alpha);
    textSize(12);
    textAlign(LEFT);
    text(int(lastDetectedDist) + "cm", -x + 12, -y - 5);

    detectedTimer--;
  }
}

void serialEvent(Serial p) {
  data = p.readStringUntil('\n');
  if (data != null) {
    data = trim(data);
    String[] vals = split(data, ',');
    if (vals.length == 2) {
      angle = float(vals[0]);
      distance = float(vals[1]);
    }
  }
}
