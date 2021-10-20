/**
* An early test to see how useful this whole thing is.
* You can drag it around using the middle mouse button
*/
class MinesweeperGame implements Kid {
    XYWH body;
    Album album;
    String[] gameState, displayState;
    int gameW, gameH, numBombs;
    //Album pages, and game/display states
    final String BOMB = "bomb",
    UNTOUCHED = "untouched", //unclicked tile
    EMPTY = "empty", //tile that was clicked and isn't a bomb or number
    FLAG = "flag",
    QUESTION = "question",
    ONE = "one",
    TWO = "two",
    THREE = "three",
    FOUR = "four",
    FIVE = "five",
    SIX = "six",
    SEVEN = "seven",
    EIGHT = "eight";

    MinesweeperGame() {
        //==============================================
        //Feel free to change up the game settings here:
        gameW = 30;
        gameH = 16;
        numBombs = 99;
        //Standard tile sizes:
        //Beginner      = W:9  H:9  B:10
        //Intermediate  = W:16 H:16 B:40
        //Expert        = W:30 H:16 B:99
        //==============================================
        album = new Album("minesweeper.alb");
        body = new XYWH(0, 0, gameW * album.w, gameH * album.h);
        gameState = new String[gameW * gameH];
        displayState = new String[gameW * gameH];
        resetGame();
    }

    void resetGame() {
        int randI, tempBombs, thisTileBombs;
        boolean north, east, south, west;
        //initialize
        for (int i = 0; i < gameState.length; i++) {
            gameState[i] = EMPTY;
            displayState[i] = UNTOUCHED;
        }
        //place bombs
        tempBombs = min(numBombs, gameW * gameH); //make sure we didn't set numBombs too high
        while (tempBombs > 0) {
            randI = (int)random(0, gameW * gameH);
            if (gameState[randI] == EMPTY) {
                gameState[randI] = BOMB;
                tempBombs--;
            }
        }
        //assign numbers
        for (int i = 0; i < gameState.length; i++) {
            if (gameState[i] == BOMB) continue;
            thisTileBombs = 0;
            north = east = south = west = false;
            //check the cardinal directions first so we can know which corners to check afterwards
            if (i / gameW >= 1) {
                north = true;
                if (gameState[i - gameW] == BOMB) thisTileBombs++;
            }
            if (i % gameW != gameW - 1) {
                east = true;
                if (gameState[i + 1] == BOMB) thisTileBombs++;
            }
            if (i < gameW * (gameH - 1)) {
                south = true;
                if (gameState[i + gameW] == BOMB) thisTileBombs++;
            }
            if (i % gameW > 0) {
                west = true;
                if (gameState[i - 1] == BOMB) thisTileBombs++;
            }
            if (north && west && gameState[i - gameW - 1] == BOMB) thisTileBombs++;
            if (north && east && gameState[i - gameW + 1] == BOMB) thisTileBombs++;
            if (south && west && gameState[i + gameW - 1] == BOMB) thisTileBombs++;
            if (south && east && gameState[i + gameW + 1] == BOMB) thisTileBombs++;
            
            String tileValue = EMPTY;
            if (thisTileBombs == 1) tileValue = ONE;
            else if (thisTileBombs == 2) tileValue = TWO;
            else if (thisTileBombs == 3) tileValue = THREE;
            else if (thisTileBombs == 4) tileValue = FOUR;
            else if (thisTileBombs == 5) tileValue = FIVE;
            else if (thisTileBombs == 6) tileValue = SIX;
            else if (thisTileBombs == 7) tileValue = SEVEN;
            else if (thisTileBombs == 8) tileValue = EIGHT;
            gameState[i] = tileValue;
            //displayState[i] = tileValue; //uncomment this to see all the numbers
        }
    }

    void draw(PGraphics canvas) {
        int x, y, mouseIndex = indexAtMouse();
        for (int i = 0; i < displayState.length; i++) {
            y = (int)(i / gameW);
            x = i - (y * gameW);
            //draw tile
            canvas.image(album.page(displayState[i]), body.x + x * album.w, body.y + y * album.h);
            //now we see if we need to show a button press, overdrawing what we just put down
            if (edwin.mouseBtnHeld == LEFT && displayState[i] == UNTOUCHED && i == mouseIndex) {
                canvas.image(album.page(EMPTY), body.x + x * album.w, body.y + y * album.h);
            }
        }
    }

    String keyboard(KeyEvent event) {
        if (event.getAction() == KeyEvent.RELEASE && event.getKeyCode() == Keycodes.R) { //not case sensitive
            resetGame();
            return HELLO;
        }
        return "";
    }

    String mouse() {
        if (edwin.mouseBtnHeld == CENTER) {
            body.set(mouseX, mouseY);
        }
        else if (!body.isMouseOver()) {
            return "";
        }
        int clickedIndex = indexAtMouse();
        if (edwin.mouseBtnReleased == RIGHT) {
            //cycle image from blank to flag to question and back
            if (displayState[clickedIndex] == FLAG) displayState[clickedIndex] = QUESTION;
            else if (displayState[clickedIndex] == QUESTION) displayState[clickedIndex] = UNTOUCHED;
            else if (displayState[clickedIndex] == UNTOUCHED) {
                displayState[clickedIndex] = FLAG;
                //see if the game is over
                int flagCount = 0, correctCount = 0;
                for (int i = 0; i < displayState.length; i++) {
                    if (displayState[i] == FLAG) {
                        flagCount++;
                        if (gameState[i] == BOMB) {
                            correctCount++;
                        }
                    }
                }
                if (flagCount > numBombs - 5) println(flagCount + "/" + numBombs + " bombs flagged");
                if (correctCount == numBombs && correctCount == flagCount) println("YOU WIN");
            }
        }
        else if (edwin.mouseBtnReleased == LEFT) {
            if (displayState[clickedIndex] == UNTOUCHED) {
                explore(clickedIndex);
                if (gameState[clickedIndex] == BOMB) println("BOOM! Press R to reset the game");
            }
        }
        return HELLO;
    }

    int indexAtMouse() {
        int yIndex = (int)((mouseY - body.y) / album.h);
        int xIndex = (int)((mouseX - body.x) / album.w);
        //println("x:" + xIndex + " y:" + yIndex);
        return yIndex * gameW + xIndex;
    }

    /** Reveal tile being clicked and if it's empty then recursively reveal neighbors until the edge hits numbers */
    void explore(int index) {
        displayState[index] = gameState[index];
        if (gameState[index] != EMPTY) {
            return;
        }
        boolean north, east, south, west;
        north = east = south = west = false;
        //check the cardinal directions first so we can know which corners to check afterwards
        if (index / gameW >= 1) {
            north = true;
            if (displayState[index - gameW] == UNTOUCHED) explore(index - gameW);
        }
        if (index % gameW != gameW - 1) {
            east = true;
            if (displayState[index + 1] == UNTOUCHED) explore(index + 1);
        }
        if (index < gameW * (gameH - 1)) {
            south = true;
            if (displayState[index + gameW] == UNTOUCHED) explore(index + gameW);
        }
        if (index % gameW > 0) {
            west = true;
            if (displayState[index - 1] == UNTOUCHED) explore(index - 1);
        }
        //corners
        if (north && west && displayState[index - gameW - 1] == UNTOUCHED) explore(index - gameW - 1);
        if (north && east && displayState[index - gameW + 1] == UNTOUCHED) explore(index - gameW + 1);
        if (south && east && displayState[index + gameW + 1] == UNTOUCHED) explore(index + gameW + 1);
        if (south && west && displayState[index + gameW - 1] == UNTOUCHED) explore(index + gameW - 1);
    }
}
