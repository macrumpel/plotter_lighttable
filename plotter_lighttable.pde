import java.util.List;
import java.util.ArrayList;

List<String> gcode; // Stores the original G-code
List<String> modifiedGcode; // Stores the modified G-code
float xOffset = 0, yOffset = 0; // Offsets for X and Y coordinates
float scale = 2; // Scale factor (1 mm = 2 pixels)
boolean showA3 = true, showA4 = true, showA5 = true; // Toggle boundaries
String gcodeFilename = ""; // Name of the loaded G-code file

// DIN page dimensions (mm)
final float A3_WIDTH = 420, A3_HEIGHT = 297; // A3 landscape
final float A4_WIDTH = 210, A4_HEIGHT = 297; // A4 portrait
final float A5_WIDTH = 148, A5_HEIGHT = 210; // A5 portrait

void settings() {
  size(int(550 * scale), int(450 * scale)); // 55 cm x 45 cm viewer
}

void setup() {
  selectInput("Select a G-code file:", "loadGcodeFile");
  textSize(12);
}

void draw() {
  background(255);
  drawPageBoundaries(); // Draw A3, A4, A5 boundaries
  if (modifiedGcode != null) {
    drawGcodePreview(); // Draw the G-code preview
  }
  drawRulers(); // Draw rulers
  drawOffsetInfo(); // Display current offsets
  drawMouseCoordinates(); // Display mouse position coordinates
}

void loadGcodeFile(File file) {
  if (file == null) return;
  gcode = new ArrayList<String>();
  modifiedGcode = new ArrayList<String>();
  String[] lines = loadStrings(file.getAbsolutePath());
  for (String line : lines) {
    gcode.add(line);
    modifiedGcode.add(line);
  }
  gcodeFilename = file.getName(); // Store the filename
  applyOffsets(); // Initialize modifiedGcode
}

void applyOffsets() {
  List<String> newGcode = new ArrayList<String>();
  for (String line : gcode) {
    if (line.startsWith("G0") || line.startsWith("G1")) {
      String[] parts = line.split(" ");
      for (int i = 0; i < parts.length; i++) {
        if (parts[i].startsWith("X")) {
          float x = float(parts[i].substring(1)) + xOffset;
          parts[i] = "X" + x;
        } else if (parts[i].startsWith("Y")) {
          float y = float(parts[i].substring(1)) + yOffset;
          parts[i] = "Y" + y;
        }
      }
      line = String.join(" ", parts);
    }
    newGcode.add(line);
  }
  modifiedGcode = newGcode; // Atomic update
}

void drawGcodePreview() {
  pushMatrix();
  translate(50, height - 50); // Lower-left origin
  scale(scale, -scale); // Flip Y-axis

  float lastX = 0, lastY = 0; // Track previous position
  boolean isDrawing = false; // True during G1 moves

  for (String line : modifiedGcode) {
    if (line.startsWith("G0") || line.startsWith("G1")) {
      float x = lastX, y = lastY; // Default to last position
      String[] parts = line.split(" ");
      for (String part : parts) {
        if (part.startsWith("X")) x = float(part.substring(1));
        if (part.startsWith("Y")) y = float(part.substring(1));
      }

      if (line.startsWith("G1")) {
        // Draw a solid line for G1 (drawing)
        stroke(0); // Black for drawing
        line(lastX, lastY, x, y);
        isDrawing = true;
      } else if (line.startsWith("G0")) {
        // Draw a dashed line for G0 (rapid move)
        stroke(255, 204, 0); // Yellow
        drawDashedLine(lastX, lastY, x, y, 5); // Dashed line with 5mm segments
        isDrawing = false;
      }

      lastX = x;
      lastY = y;
    }
  }
  popMatrix();
}

void drawDashedLine(float x1, float y1, float x2, float y2, float dashLength) {
  float dx = x2 - x1;
  float dy = y2 - y1;
  float distance = dist(x1, y1, x2, y2);
  float dashCount = distance / dashLength;

  for (int i = 0; i < dashCount; i++) {
    float t1 = i / dashCount;
    float t2 = (i + 0.5) / dashCount; // Half dash length for gaps
    if (t2 > 1) t2 = 1; // Clamp to end of line

    float startX = lerp(x1, x2, t1);
    float startY = lerp(y1, y2, t1);
    float endX = lerp(x1, x2, t2);
    float endY = lerp(y1, y2, t2);

    line(startX, startY, endX, endY);
  }
}

void drawPageBoundaries() {
  pushMatrix();
  translate(50, height - 50); // Lower-left origin
  scale(scale, -scale); // Flip Y-axis

  pushStyle();
  stroke(200);
  noFill();
  if (showA3) rect(0, 0, A3_WIDTH, A3_HEIGHT); // A3 landscape
  if (showA4) rect(0, 0, A4_WIDTH, A4_HEIGHT); // A4 portrait
  if (showA5) rect(0, 0, A5_WIDTH, A5_HEIGHT); // A5 portrait
  popStyle();
  popMatrix();
}

void drawRulers() {
  // Horizontal ruler (X-axis)
  float rulerStartX = 50;
  float rulerEndX = 50 + 550 * scale; // Extended to 550mm
  float rulerY = height - 30;

  stroke(0);
  line(rulerStartX, rulerY, rulerEndX, rulerY);

  // X-axis ticks
  for (int mm = 0; mm <= 550; mm += 10) {
    float x = rulerStartX + mm * scale;
    if (mm % 50 == 0) {
      line(x, rulerY, x, rulerY + 10);
      fill(0);
      textAlign(CENTER, TOP);
      text(mm, x, rulerY + 12);
    } else {
      line(x, rulerY, x, rulerY + 5);
    }
  }

  // Vertical ruler (Y-axis)
  float rulerStartY = height - 50 - 450 * scale; // Extended to 450mm
  float rulerX = 30;

  line(rulerX, height - 50, rulerX, rulerStartY);

  // Y-axis ticks
  for (int mm = 0; mm <= 450; mm += 10) {
    float y = height - 50 - mm * scale;
    if (mm % 50 == 0) {
      line(rulerX, y, rulerX - 10, y);
      fill(0);
      textAlign(RIGHT, CENTER);
      text(mm, rulerX - 15, y);
    } else {
      line(rulerX, y, rulerX - 5, y);
    }
  }
}

void drawOffsetInfo() {
  fill(0);
  textSize(16);
  textAlign(LEFT, TOP);
  text("G-code File: " + gcodeFilename, 10, 10);
  text("X Offset: " + xOffset + " mm", 10, 30);
  text("Y Offset: " + yOffset + " mm", 10, 50);
  text("Press 'S' to save modified G-code", 10, 70);
  text("Press '3', '4', '5' to toggle A3/A4/A5 boundaries", 10, 90);
}

void drawMouseCoordinates() {
  // Convert mouse position to millimeters
  float mouseXmm = (mouseX - 50) / scale;
  float mouseYmm = (height - 50 - mouseY) / scale;

  // Display coordinates
  fill(0);
  textSize(16);
  textAlign(LEFT, TOP);
  text("Mouse X: " + nf(mouseXmm, 0, 1) + " mm", width - 200, 10);
  text("Mouse Y: " + nf(mouseYmm, 0, 1) + " mm", width - 200, 30);
}

void keyPressed() {
  if (key == CODED) {
    if (keyCode == LEFT) xOffset--;
    if (keyCode == RIGHT) xOffset++;
    if (keyCode == UP) yOffset++;
    if (keyCode == DOWN) yOffset--;
    applyOffsets();
  } else if (key == 's' || key == 'S') {
    saveModifiedGcode();
  } else if (key == '3') {
    showA3 = !showA3;
  } else if (key == '4') {
    showA4 = !showA4;
  } else if (key == '5') {
    showA5 = !showA5;
  }
}

void saveModifiedGcode() {
  if (modifiedGcode == null) return;
  saveStrings("modified_gcode.nc", modifiedGcode.toArray(new String[0]));
}