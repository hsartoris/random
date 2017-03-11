import java.io.Serializable;
import java.io.BufferedReader;
import java.io.FileReader;

public enum CellState { SATISFIED, UNDERFULL, OVERFULL, CONFLICT }

class Cell implements Serializable {
  static final boolean WALL = true;
  static final boolean OPEN = false;
  // look yes I do comparisons to these and not just straight boolean ifs but what if I want to change it to an enum
  
  int downSum = 0;
  int downLength = 0;
  int rightSum = 0;
  int rightLength = 0;
  boolean cellType;
  CellState rightState;
  CellState downState;
  CellState state = CellState.SATISFIED;
  int value = 0;
  boolean[] possibilities;
  
  
  public Cell(boolean type) {
    cellType = type;
    if (type == OPEN) {
      downState = rightState = CellState.SATISFIED;
      possibilities = new boolean[9];
      for (int i = 0; i < possibilities.length; i++) possibilities[i] = false;
    }
    else downState = rightState = CellState.SATISFIED;
  }
  
  public Cell(int down, int dLength, int right, int rLength) {
    cellType = WALL;
    downSum = down;
    rightSum = right;
    downLength = dLength;
    rightLength = rLength;
    if (downSum > 0) downState = CellState.UNDERFULL;
    if (rightSum > 0) rightState = CellState.UNDERFULL;
  }
  
  public Cell(int down, int right) {
    cellType = WALL;
    downSum = down;
    rightSum = right;
    if (downSum > 0) downState = CellState.UNDERFULL;
    if (rightSum > 0) rightState = CellState.UNDERFULL;
  }
  
  void suggest(int i) {
    if (cellType == OPEN) possibilities[i] = !possibilities[i];
  }
  
  void setVal(int i) { //note: accepts ints assuming range 0-8 to be internally consistent
  if (value == i + 1) {
    value = 0;
    return;
  }
    value = i + 1;
  }
  
  void clearCell() {
    if (value > 0) value = 0;
    else for (int i = 0; i < possibilities.length; i++) possibilities[i] = false;
  }
  
  void setRight(int sum, int len) {
    rightSum = sum;
    rightLength = len;
    rightState = CellState.UNDERFULL;
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
int suggestTextHeight = (cellWidth - (textOffset * 4))/3;
int hintTextHeight = (cellWidth - (textOffset * 4))/2;
int displayTextHeight = (cellWidth - (textOffset * 2));
int keyOffset = 49;

boolean invertedNumbers = true;
boolean drawUnderfull = false;

int pX;
int pY;
color pointerColor = color(128, 128);
color wallColor = color(100);
color bgColor = color(255);

boolean solved;

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
    if (cells[i].cellType == Cell.WALL && Math.random() < .5) cells[i].setRight(14,2);
  }
  
  importPuzzle("70.ka");
  
  size(500, 500); //fuck hardcoding
  
  xOffset = (width - (cellWidth * cols))/2;
  yOffset = (height - (cellWidth * rows))/2;
  
  pX = 0;
  pY = 0;
  stroke(0);
  strokeWeight(1);
  textAlign(CENTER, CENTER);
}

void importPuzzle(String file) {
  String[] inputs;
  String lines[] = loadStrings(file);
  for (int j = 0; j < lines.length; j++) {
    inputs = lines[j].split("\\|");
    for (int i = 0; i < inputs.length; i++) {
      if (inputs[i].equals("o")) {
        cells[getIdx(i,j)] = new Cell(Cell.OPEN);
      } else if (inputs[i].equals("-")) {
        cells[getIdx(i,j)] = new Cell(Cell.WALL);
      } else {
        String[] temp = inputs[i].split("\\\\");
        for (String s : temp) print(s + "; ");
        int down = 0;
        int right = 0;
        if (!temp[0].equals("*")) down = Integer.parseInt(temp[0]);
        if (!temp[1].equals("*")) right = Integer.parseInt(temp[1]);
        cells[getIdx(i,j)] = new Cell(down, right);
      }
    }
  }
}

void checkWall(int x, int y) {
  // the way this method is done means that puzzles really need to be sanity checked before use
  // also it's dumb as fuck and could be soooooo much less code
  Cell c = cells[getIdx(x,y)];
  int temp = 0;
  boolean[] nums = new boolean[10];
  for (int i = 0; i < 10; i++) nums[i] = false;
  if (c.rightSum > 0) {
    c.rightState = CellState.SATISFIED;
    for (int i = x + 1; i < cols; i++) {
      int val = cells[getIdx(i,y)].value;
      if (cells[getIdx(i,y)].cellType == Cell.WALL) break;
      if (val == 0) {
        c.rightState = CellState.UNDERFULL;
        solved = false;
        break;
      }
      if (!nums[val-1]) {
        temp += val;
        nums[val-1] = true;
      } else { // number already used
        c.rightState = CellState.CONFLICT;
        solved = false;
        break;
      }
    }
    if (temp > c.rightSum) {
      c.rightState = CellState.OVERFULL;
      solved = false;
    } else if (temp < c.rightSum) {
      solved = false;
      c.rightState = CellState.UNDERFULL;
    }
  }
  
  temp = 0;
  for (int i = 0; i < 10; i++) nums[i] = false;
  if (c.downSum > 0) {
    c.downState = CellState.SATISFIED;
    for (int i = y + 1; i < rows; i++) {
      int val = cells[getIdx(x,i)].value;
      if (cells[getIdx(x,i)].cellType == Cell.WALL) break;
      if (val == 0) {
        c.downState = CellState.UNDERFULL;
        solved = false;
        break;
      }
      if (!nums[val-1]) {
        temp += val;
        nums[val-1] = true;
      } else { // number already used
        c.downState = CellState.CONFLICT;
        solved = false;
        break;
      }
    }
    if (temp > c.downSum) {
      solved = false;
      c.downState = CellState.OVERFULL;
    } else if (temp < c.downSum) {
      solved = false;
      c.downState = CellState.UNDERFULL;
    }
  }
}

void checkOpen(int x, int y) {
  Cell c = cells[getIdx(x,y)];
  c.state = CellState.SATISFIED;
  for (int t = 1; t < max(rows, cols); t++) {
    if (x + t < cols && cells[getIdx(x+t,y)].value == c.value) {
        c.state = CellState.CONFLICT;
        cells[getIdx(x+t,y)].state = CellState.CONFLICT;
    }
    if (x - t >= 0 && cells[getIdx(x-t,y)].value == c.value) {
        c.state = CellState.CONFLICT;
        cells[getIdx(x-t,y)].state = CellState.CONFLICT;
    }
    if (y + t < rows && cells[getIdx(x,y+t)].value == c.value) {
        c.state = CellState.CONFLICT;
        cells[getIdx(x,y+t)].state = CellState.CONFLICT;
    }
    if (y - t >= 0 && cells[getIdx(x,y-t)].value == c.value) {
        c.state = CellState.CONFLICT;
        cells[getIdx(x,y-t)].state = CellState.CONFLICT;
    }
  }
}

void checkCell(int x, int y) {
  Cell c = cells[getIdx(x,y)];
  if (c.cellType == Cell.WALL && (c.downSum > 0 || c.rightSum > 0)) checkWall(x,y);
  else if (c.cellType == Cell.OPEN) checkOpen(x,y);
}

void drawGrid() {
  for (int x = 0; x <= cols; x++) {
    line((x * cellWidth) + xOffset, yOffset, (x * cellWidth) + xOffset, yOffset + (cellWidth * cols));
  }
  for (int y = 0; y <= rows; y++) {
    line(xOffset, (y * cellWidth) + yOffset, xOffset + (cellWidth * rows), (y * cellWidth) + yOffset);
  }
}

void draw() {
  textAlign(CENTER, CENTER);
  background(255);
  drawGrid();
  solved = true;
  
  fill(pointerColor);
  rect((pX * cellWidth) + xOffset, (pY * cellWidth) + yOffset, cellWidth, cellWidth);
  
  for (int x = 0; x < cols; x++) {
    for (int y = 0; y < rows; y++) {
      Cell cell = cells[getIdx(x,y)];
      checkCell(x,y);
      if (cell.cellType == Cell.WALL) { 
        fill(wallColor);
        rect((x * cellWidth) + xOffset, (y * cellWidth) + yOffset, cellWidth, cellWidth);
        
        if (cell.downSum > 0 || cell.rightSum > 0) { // there are sums to be defined
          line((x * cellWidth) + xOffset, (y * cellWidth) + yOffset, (x * cellWidth) + xOffset + cellWidth, (y * cellWidth) + xOffset + cellWidth);
          fill(255);
          textSize(hintTextHeight);
          if (cell.downSum > 0) {
            if (cell.downState == CellState.OVERFULL || cell.downState == CellState.CONFLICT) fill(color(255,0,0));
            else if (cell.downState == CellState.UNDERFULL && drawUnderfull) fill(color(0,255,0));
            else fill(255);
            text(cell.downSum, xOffset + (x * cellWidth) + (cellWidth / 4) + (textOffset / 2), yOffset + (y * cellWidth) + (cellWidth * 3 / 4) - (textOffset / 2));
          }
          if (cell.rightSum > 0) {
            if (cell.rightState == CellState.OVERFULL || cell.rightState == CellState.CONFLICT) fill(color(255,0,0));
            else if (cell.rightState == CellState.UNDERFULL && drawUnderfull) fill(color(0,255,0));
            else fill(255);
            text(cell.rightSum, xOffset + (x * cellWidth) + (cellWidth * 3 / 4) - (textOffset / 2), yOffset + (y * cellWidth) + (cellWidth / 4));
          }
        }
      } else if (cell.value < 1) {
        textSize(suggestTextHeight);
        fill(0);
        for (int i = 0 ; i < cell.possibilities.length; i++) {
          if (cell.possibilities[i]) {
            //println(i+1);
            int tx = i % 3;
            int ty = i / 3;
            if (invertedNumbers) ty = 2 - ty;
            text(i + 1, xOffset + (x * cellWidth) + (cellWidth * (tx + 1)/4), yOffset + (y * cellWidth) + (cellWidth * (ty + 1)/4));
          }
        }
      } else {
        textSize(displayTextHeight);
        fill(0);
        if (cell.state == CellState.CONFLICT) fill(color(255,0,0));
        text(cell.value, xOffset + (x * cellWidth) + (cellWidth / 2), yOffset + (y * cellWidth) + (cellWidth / 2) - textOffset);
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
                 break;
      case '0': suggestMode = !suggestMode;
                break;
      case 'q': exit();
      case 'i': invertedNumbers = !invertedNumbers;
                break;
      case '-': cells[getIdx(pX, pY)].clearCell();
                break;
      default: try { 
                 int i = Integer.valueOf(key) - keyOffset; // lord only knows
                 if (i < 10 && i >= 0) {
                   if (suggestMode) cells[getIdx(pX, pY)].suggest(i);
                   else cells[getIdx(pX, pY)].setVal(i);
                 }
               } catch (NumberFormatException e) { }
      
    }
    keyPressed = false;
  }
  
  if (mousePressed) {
    pX = max(min((mouseX - xOffset) / cellWidth, cols - 1), 0);
    pY = max(min((mouseY - yOffset) / cellWidth, rows - 1), 0);
  }
  
  textSize(15);
  fill(0);
  textAlign(LEFT, TOP);
  text("Mode: " + (suggestMode ? "scratch" : "permanent") + (invertedNumbers ? ", inverted" : "") + (solved ? ", solved!" : ""), 10, 10);
  
}