import java.io.Serializable;

class Cell implements Serializable {
  static final boolean WALL = true;
  static final boolean OPEN = false;
  // look yes I do comparisons to these and not just straight boolean ifs but what if I want to change it to an enum
  
  int downSum = 0;
  int rightSum = 0;
  boolean cellType;
  
  int value = 0;
  boolean[] possibilities;
  
  
  public Cell(boolean type) {
    cellType = type;
    if (type == OPEN) {
      possibilities = new boolean[9];
      for (int i = 0; i < possibilities.length; i++) possibilities[i] = false;
    }
  }
  
  public Cell(int down, int right) {
    cellType = WALL;
    downSum = down;
    rightSum = right;
  }
  
  void suggest(int i) {
    if (cellType == OPEN) possibilities[i] = !possibilities[i];
  }

}


int cellWidth = 40;

int rows;
int cols;

Cell[] cells;

boolean suggestMode = true;

// drawing variables
int xOffset;
int yOffset;
int textOffset = 4;
int textHeight = (cellWidth - (textOffset * 4))/3;
int keyOffset = 49;

boolean invertedNumbers = true;


int pX;
int pY;
color pointerColor = color(128, 128);
color wallColor = color(100);
color bgColor = color(255);

int getIdx(int x, int y) {
  return (y * rows) + x;
}

int getNextOpen(int x, int y, int d, boolean isX) throws NoNextCellException { // syntax: current x,y, increment (probably -1 or 1), x vs y axis
  for (x += (d * (isX ? 1 : 0)), y += (d * (isX ? 0 : 1)); x >= 0 && x < cols && y >= 0 && y < rows; x += (d * (isX ? 1 : 0)), y += (d * (isX ? 0 : 1))) if (cells[getIdx(x, y)].cellType == Cell.OPEN) return (x * (isX ? 1 : 0)) + (y * (isX ? 0 : 1));
  throw new NoNextCellException(); // no open cell found
}

void setup() {
  rows = 10;
  cols = 10;
  
  cells = new Cell[rows * cols];
  for (int i = 0; i < cells.length; i++) {
    cells[i] = new Cell(Math.random() < .5);
    if (cells[i].cellType == Cell.WALL && Math.random() < .5) cells[i].downSum = 1;
  }
  
  size(500, 500); //fuck hardcoding
  
  xOffset = (width - (cellWidth * cols))/2;
  yOffset = (height - (cellWidth * rows))/2;
  
  pX = 0;
  pY = 0;
  stroke(0);
  strokeWeight(1);
}

void draw() {
  background(255);
  for (int x = 0; x <= cols; x++) {
    line((x * cellWidth) + xOffset, yOffset, (x * cellWidth) + xOffset, yOffset + (cellWidth * cols));
  }
  for (int y = 0; y <= rows; y++) {
    line(xOffset, (y * cellWidth) + yOffset, xOffset + (cellWidth * rows), (y * cellWidth) + yOffset);
  }
  
  fill(pointerColor);
  rect((pX * cellWidth) + xOffset, (pY * cellWidth) + yOffset, cellWidth, cellWidth);
  
  for (int x = 0; x < cols; x++) {
    for (int y = 0; y < rows; y++) {
      Cell cell = cells[getIdx(x,y)];
      if (cell.cellType == Cell.WALL) { 
        fill(wallColor);
        rect((x * cellWidth) + xOffset, (y * cellWidth) + yOffset, cellWidth, cellWidth);
        if (cell.downSum > 0 || cell.rightSum > 0) { // there are sums to be defined
          line((x * cellWidth) + xOffset, (y * cellWidth) + yOffset, (x * cellWidth) + xOffset + cellWidth, (y * cellWidth) + xOffset + cellWidth);
        }
      } else if (cell.value < 1) {
        textSize(textHeight);
        fill(0);
        for (int i = 0 ; i < cell.possibilities.length; i++) {
          if (cell.possibilities[i]) {
            //println(i+1);
            int tx = i % 3;
            int ty = i / 3;
            if (invertedNumbers) ty = 2 - ty;
            text(i + 1, xOffset + (textOffset / 3) + (x * cellWidth) + ((tx + 1) * textOffset) + (tx * textHeight), yOffset + (y * cellWidth) + ((ty + 1) * (textOffset + textHeight)));
          }
        }
      } else {
        // draw value
      }
    }
  }
  
  if (keyPressed) {
    switch(key) {
      case CODED: switch(keyCode){ 
        case UP:  try { pY = getNextOpen(pX, pY, -1, false); }
                  catch(NoNextCellException e) { }
                  break;
        case RIGHT: try { pX = getNextOpen(pX, pY, 1, true); }
                    catch(NoNextCellException e) { }
                    break;
        case LEFT: try { pX = getNextOpen(pX, pY, -1, true); }
                   catch(NoNextCellException e) { }
                   break;
        case DOWN: try { pY = getNextOpen(pX, pY, 1, false); }
                   catch(NoNextCellException e) { }
                   break;
      }
      case '0': suggestMode = !suggestMode;
                break;
      case 'q': exit();
      default: try { 
                 int i = Integer.valueOf(key) - keyOffset; // lord only knows
                 if (i < 10 && i >= 0 && suggestMode) {
                 println(i);
                   cells[getIdx(pX, pY)].suggest(i);
                 }
               } catch (NumberFormatException e) { }
      
    }
    keyPressed = false;
  }
  
}