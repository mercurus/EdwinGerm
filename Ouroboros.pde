/*
* The Ouroboros is a serpent eating its own tail
* and is an ancient symbol for the eternal cycle of death and rebirth
* https://occult-world.com/ouroboros/
*
* On its skin I'm drawing multiple layers of Conway's Game of Life (CGOL)
* which is a simple set of rules that creates complex patterns
* https://conwaylife.com/wiki/2-glider_collision
*
*/
public class Ouroboros implements Kid { 
    //PShader cgolRender, cgolCompute; At first I tried very hard to use a shader to draw the body instead...
    PImage head;
    PGraphics body1, body2;
    SerpentSkin[] serpentSkins;
    PatternWindow patternWindow;
    PalettePicker palette;

    BoundedInt headColumn;
    float lastSec, delaySec;
    boolean play, step, nuke, eat, wrapY;
    boolean useBody1, drawing;
    String openFilepath;

    final int 
    COLUMN_COUNT = 240,
    ROW_COUNT = 20,
    GAME_SIZE = COLUMN_COUNT * ROW_COUNT,
    OUTER_R = 440, 
    INNER_R = 260; //radii

    Ouroboros() { this(null); }
    Ouroboros(String filepath) {
        body1 = createGraphics(width, height);
        body1.noSmooth();
        body1.beginDraw(); //initialize the pixels array
        body1.endDraw();
        body2 = createGraphics(width, height);
        body2.noSmooth();
        body2.beginDraw();
        body2.endDraw();

        //set some properties
        headColumn = new BoundedInt(COLUMN_COUNT - 1, true);
        lastSec = 0;
        delaySec = 0.25; //speed of execution
        useBody1 = true; //gets flipped back and forth depending on which buffer is in use
        drawing = false; //only true when the next frame is being drawn
        play = true; //hit the space key to start/stop the show
        step = false; //hit the right arrow key to move one frame at a time
        nuke = false; //blanks out all current cgol data
        wrapY = true; //cells can move/react past the vertical bounds
        eat = true; //head will blank out any cells it touches
        openFilepath = filepath; //stays null until a .oro file is opened

        head = loadImage("serpentHead.png");

        //initialize skins;
        serpentSkins = new SerpentSkin[5];
        for (int i = 0; i < serpentSkins.length; i++) {
            serpentSkins[i] = new SerpentSkin(i);
        }

        patternWindow = new PatternWindow(false);
        palette = new PalettePicker() {
            void colorSelected(int paletteIndex) {
                serpentSkins[patternWindow.selectedSkin.value].skinColorIndex = paletteIndex;
            }
        };
        palette.isVisible = false;


        println("Ouroboros (press o to toggle UI)");
        thread("flipSerpentBody");
    }

    void draw(PGraphics canvas) {
        //open new pattern
        if (openFilepath != null) {
            //wait for frame to finish drawing before rewriting skin variables
            while (drawing) { }
            digestFile();
        }

        //serpent body
        canvas.image((useBody1 ? body2 : body1), 0, 0);

        //head
        float angle = headColumn.value / (float)COLUMN_COUNT * TWO_PI;
        canvas.pushMatrix();
        canvas.translate(width * 0.5, height * 0.5);
        //starting line
        // canvas.stroke(#ff00ff);
        // canvas.strokeWeight(1);
        // canvas.line(INNER_R, 0, OUTER_R, 0);
        //draw head
        canvas.translate(cos(angle) * OUTER_R, sin(angle) * OUTER_R);
        canvas.rotate(angle + HALF_PI);
        canvas.image(head, 0, -2);
        canvas.popMatrix();

        //UI
        patternWindow.draw(canvas);

        //flip buffers if its time
        float nowSec = millis() / 1000.0;
        if (nowSec - lastSec >= delaySec && play && !drawing) {
            thread("flipSerpentBody");
        }
    }

    String mouse() {
        if (patternWindow.mouse() != "") return "window stuff";
        return "";
    }

    String keyboard(KeyEvent event) {
        if (event.getAction() == KeyEvent.RELEASE) {
            int kc = event.getKeyCode();
            if (kc == Keycodes.SPACE) {
                play = !play;
            }
            else if (kc == Keycodes.O) {
                patternWindow.isVisible = !patternWindow.isVisible;
            }
            else if (kc == Keycodes.RIGHT) {
                step = true;
                play = true;
            }
            else if (kc == Keycodes.DOWN) {
                delaySec += 0.05;
                println(delaySec);
            }
            else if (kc == Keycodes.UP) {
                delaySec = max(0, delaySec - 0.05);
                println(delaySec);
            }
        }
        return "";
    }

    void openFile() {
        //called from the PatternWindow
        selectInput("Open pattern .oro", "openFile", null, this);
    }

    void openFile(File file) {
        if (file == null) return; //user hit cancel or closed
        openFilepath = file.getAbsolutePath();
        //Next time draw() is called it'll call digestFile() so we don't screw with variables potentially in use 
        //since we might be in the middle of drawing at this time. Then openFilepath becomes null.
    }

    /** Load file into editor variables */
    void digestFile() {
        JSONObject json = loadJSONObject(openFilepath);
        openFilepath = null;
        palette.resetColors(json);

        for (SerpentSkin skin : serpentSkins) {
            skin.frames.clear();
            skin.currentFrameIndex.reset(0, 0);
        }

        //skin patterns
        SerpentSkin skin;
        JSONArray jsonPatterns = json.getJSONArray("patterns");
        for (int i = 0; i < jsonPatterns.size(); i++) {
            if (i >= 5) break; //capped
            JSONObject thisPattern = jsonPatterns.getJSONObject(i);
            skin = serpentSkins[i];
            skin.skinColorIndex = thisPattern.getInt("paletteIndex");
            skin.isVisible = thisPattern.getBoolean("isVisible");
            
            //populate frame cells
            JSONArray jsonFrames = thisPattern.getJSONArray("frames");
            for (int j = 0; j < jsonFrames.size(); j++) {
                int[] indicies = jsonFrames.getJSONArray(j).getIntArray();
                int[] frame = skin.addFrame();
                for (int k = 0; k < indicies.length; k++) {
                    frame[indicies[k]] = 1;
                }
                if (j > 0) skin.currentFrameIndex.incrementMax();
            }
        }
        
        nuke = true;
        //TODO update PatternWindow to match
    }


    void saveFile() {
        //called from the PatternWindow
        selectOutput("Save pattern .oro", "saveFile", null, this);
    }

    //I'm still manually serializing my stuff for now...
    void saveFile(File file) {
        if (file == null) return; //user closed window or hit cancel
        ArrayList<String> fileLines = new ArrayList<String>();
        fileLines.add("{"); //opening bracket
        fileLines.add(palette.asJsonKV());
        fileLines.add(jsonKVNoComma("patterns", "[{")); //array of objects
        int[] cells;
        SerpentSkin skin;
        for (int i = 0; i < serpentSkins.length; i++) {
            if (i > 0) fileLines.add("},{"); //separation between layer objects in this array
            skin = serpentSkins[i];
            fileLines.add(TAB + jsonKV("paletteIndex", skin.skinColorIndex));
            fileLines.add(TAB + jsonKV("isVisible", skin.isVisible));
            fileLines.add(TAB + jsonKVNoComma("frames", "[")); //array of arrays
            for (int j = 0; j < skin.frames.size(); j++) {
                String indicies = "";
                int[] frame = skin.frames.get(j);
                for (int k = 0; k < skin.FRAME_SIZE; k++) {
                    if (frame[k] == 1) indicies += k + ",";
                }
                fileLines.add(TAB + TAB + "[" + indicies + "],"); 
            }
            fileLines.add(TAB + "]"); //end frames
        }
        fileLines.add("}]"); //close last frame and pattern
        fileLines.add("}"); //final closing bracket
        saveStrings(file.getAbsolutePath(), fileLines.toArray(new String[0]));
        patternWindow.windowTitle = file.getName();
    }

    private class SerpentSkin {
        ArrayList<int[]> frames;
        BoundedInt currentFrameIndex;
        int[] gameState1, gameState2;
        int skinColorIndex;
        boolean isVisible;
        final int FRAME_SIZE = 20 * 20;

        SerpentSkin(int skinColorIndex) {
            this.skinColorIndex = skinColorIndex;
            gameState1 = new int[GAME_SIZE];
            gameState2 = new int[GAME_SIZE];
            for (int i = 0; i < GAME_SIZE; i++) {
                gameState1[i] = 0;
                gameState2[i] = 0;
            }

            isVisible = true;
            currentFrameIndex = new BoundedInt(0, true);
            frames = new ArrayList<int[]>();
            addFrame();
        }

        int[] addFrame() {
            int[] newFrame = new int[FRAME_SIZE];
            for (int i = 0; i < FRAME_SIZE; i++) {
                newFrame[i] = 0;
            }
            frames.add(newFrame);
            return newFrame;
        }

        int skinColor() {
            return palette.colors.get(skinColorIndex);
        }

        void update() {
            if (nuke) {
                for (int i = 0; i < GAME_SIZE; i++) {
                    gameState1[i] = 0;
                    gameState2[i] = 0;
                }
                currentFrameIndex.minimize();
                return;
            }

            int[] now, then;
            if (useBody1) {
                now = gameState1;
                then = gameState2;
            }
            else {
                now = gameState2;
                then = gameState1;
            }
            
            boolean eastMost, westMost;
            int neighbourCount;
            int n, s, e, w, ne, nw, se, sw;
            n = s = e = w = ne = nw = se = sw = 0;
            for (int i = 0; i < GAME_SIZE; i++) {
                neighbourCount = 0;
                
                //determine index of neighbors
                n = i - COLUMN_COUNT;
                if (n < 0) {
                    if (wrapY) n += GAME_SIZE;
                    else n = -1;
                }

                s = i + COLUMN_COUNT;
                if (s >= GAME_SIZE) {
                    if (wrapY) s -= GAME_SIZE;
                    else s = -1;
                }

                //always wrap on X axis
                eastMost = (i % COLUMN_COUNT == COLUMN_COUNT - 1);
                westMost = (i % COLUMN_COUNT == 0);
                e = (eastMost ? i - COLUMN_COUNT + 1 : i + 1);
                w = (westMost ? i + COLUMN_COUNT - 1 : i - 1);

                //these won't be used if wrapY is false and the cell being checked is at the top/bottom
                ne = (eastMost ? n - COLUMN_COUNT + 1 : n + 1);
                nw = (westMost ? n + COLUMN_COUNT - 1 : n - 1);
                se = (eastMost ? s - COLUMN_COUNT + 1 : s + 1);
                sw = (westMost ? s + COLUMN_COUNT - 1 : s - 1);
                
                //count neighbors
                if (n > -1) {
                    if (then[n] == 1) neighbourCount += 1;
                    if (then[ne] == 1) neighbourCount += 1;
                    if (then[nw] == 1) neighbourCount += 1;
                }
                if (s > -1) {
                    if (then[s] == 1) neighbourCount += 1;
                    if (then[se] == 1) neighbourCount += 1;
                    if (then[sw] == 1) neighbourCount += 1;
                }
                if (then[e] == 1) neighbourCount += 1;
                if (then[w] == 1) neighbourCount += 1;

                //determine fate of cell
                if (then[i] == 1) { //if current cell is alive
                    if (neighbourCount == 2 || neighbourCount == 3) now[i] = 1;
                    else now[i] = 0;
                }
                else { //if current cell is dead
                    if (neighbourCount == 3) now[i] = 1;
                    else now[i] = 0;
                }
            } //end for

            //translate the frame coordinates to where the headColumn is
            //and draw relevant pixels from the frame
            int[] frame = frames.get(currentFrameIndex.value);
            for (int i = 0; i < FRAME_SIZE; i++) {
                if (frame[i] == 0) continue;
                int x = headColumn.value - 20 + (i % 20);
                int y = i / 20;
                if (x < 0) x += COLUMN_COUNT;
                int index = y * COLUMN_COUNT + x;
                now[index] = 1;
            }

            if (eat) { //destroy cells inside head
                for (int x = 0; x < 3; x++) {
                    for (int y = 0; y < ROW_COUNT; y++) {
                        int index = (headColumn.value + y * COLUMN_COUNT + x) % GAME_SIZE; //wrap on X axis
                        now[index] = 0;
                    }
                }
            }

            currentFrameIndex.increment();
        } //end update

    }

    private class PatternWindow extends DraggableWindow {
        ButtonSet[] buttonSets;
        XYWH cellEditBox;
        BoundedInt selectedFrame, selectedSkin;

        PatternWindow() { this(true); }
        PatternWindow(boolean initiallyVisible) {
            super(width / 2 - 115, height / 2 - 200, 230, 400, "Ouroboros");
            isVisible = initiallyVisible;
            cellEditBox = new XYWH(UI_PADDING, dragBar.h + UI_PADDING * 2, 200, 200, body);
            selectedFrame = new BoundedInt(0, true);
            selectedSkin = new BoundedInt(serpentSkins.length - 1, true);

            Album basicButtons = new Album(GadgetPanel.BUTTON_FILENAME);
            XY currentPos = new XY(UI_PADDING, cellEditBox.yh() + UI_PADDING);
            buttonSets = new ButtonSet[6];

            buttonSets[0] = new ButtonSet("Frame Selected",
                new GridButtons(body, currentPos.x, currentPos.y, 2, basicButtons, 
                    new String[] { GadgetPanel.ARROW_W, GadgetPanel.ARROW_E }
                ),
                new Command() {
                    void execute(String arg) {
                        if (arg == GadgetPanel.ARROW_W) {
                            selectedFrame.decrement();
                        }
                        else if (arg == GadgetPanel.ARROW_E) {
                            selectedFrame.increment();
                        }
                        standardWindowTitle();
                    }
                }
            );

            currentPos.y += basicButtons.h;
            buttonSets[1] = new ButtonSet("Frame Count",
                new GridButtons(body, currentPos.x, currentPos.y, 2, basicButtons, 
                    new String[] { GadgetPanel.MINUS, GadgetPanel.PLUS }
                ),
                new Command() {
                    void execute(String arg) {
                        if (arg == GadgetPanel.MINUS) {
                            int size = currentSkin().frames.size();
                            if (size > 1) {
                                currentSkin().frames.remove(size - 1);
                                currentSkin().currentFrameIndex.decrementMax();
                                selectedFrame.decrementMax();
                            }
                        }
                        else if (arg == GadgetPanel.PLUS) {
                            currentSkin().addFrame();
                            currentSkin().currentFrameIndex.incrementMax();
                            selectedFrame.incrementMax();
                        }
                        standardWindowTitle();
                    }
                }
            );

            currentPos.y += basicButtons.h;
            buttonSets[2] = new ButtonSet("Skin Selected",
                new GridButtons(body, currentPos.x, currentPos.y, 2, basicButtons, 
                    new String[] { GadgetPanel.ARROW_W, GadgetPanel.ARROW_E }
                ),
                new Command() {
                    void execute(String arg) {
                        if (arg == GadgetPanel.ARROW_W) {
                            selectedSkin.decrement();
                        }
                        else if (arg == GadgetPanel.ARROW_E) {
                            selectedSkin.increment();
                        }
                        selectedFrame.setMax(currentSkin().frames.size() - 1);
                        buttonSets[3].buttons.setCheck(currentSkin().isVisible);
                        standardWindowTitle();
                    }
                }
            );

            currentPos.x += basicButtons.w;
            currentPos.y += basicButtons.h;
            buttonSets[3] = new ButtonSet("Palette|Visible",
                new GridButtons(body, currentPos.x, currentPos.y, 2, basicButtons, 
                    new String[] { GadgetPanel.COLOR_WHEEL, GadgetPanel.BLANK }, new String[] { GadgetPanel.COLOR_WHEEL, GadgetPanel.BIGX }
                ),
                new Command() {
                    void execute(String arg) {
                        if (arg == GadgetPanel.COLOR_WHEEL) {
                            palette.isVisible = !palette.isVisible;
                        }
                        else {
                            currentSkin().isVisible = !currentSkin().isVisible;
                            buttonSets[3].buttons.toggleImage(1);
                        }
                    }
                }
            );
            buttonSets[3].buttons.toggleImage(1);

            currentPos.x -= basicButtons.w;
            currentPos.y += basicButtons.h;
            buttonSets[4] = new ButtonSet("Open|Save",
                new GridButtons(body, currentPos.x, currentPos.y, 2, basicButtons, 
                    new String[] { GadgetPanel.OPEN, GadgetPanel.SAVE }
                ),
                new Command() {
                    void execute(String arg) {
                        if (arg == GadgetPanel.OPEN) {
                            openFile();
                        }
                        else if (arg == GadgetPanel.SAVE) {
                            saveFile();
                        }
                    }
                }
            );

            currentPos.y += basicButtons.h;
            buttonSets[5] = new ButtonSet("Kill all live cells",
                new GridButtons(body, currentPos.x, currentPos.y, 1, basicButtons, 
                    new String[] { GadgetPanel.NO }
                ),
                new Command() {
                    void execute(String arg) {
                        nuke = true; //clears all current live pixels on all skins
                    }
                }
            );

        }

        void standardWindowTitle() {
            windowTitle = "Skin: " + (selectedSkin.value + 1) + "/" + (selectedSkin.maximum + 1) + " -- " +
                          "Frame: " + (selectedFrame.value + 1) + "/" + (selectedFrame.maximum + 1);
        }

        void draw(PGraphics canvas) {
            if (!isVisible) return;
            super.draw(canvas); //window background
            canvas.pushMatrix();
            canvas.translate(body.x, body.y);
            //arrow to help with understanding what the grid means
            canvas.noStroke();
            canvas.fill(EdColors.UI_DARKEST);
            canvas.triangle(
                cellEditBox.xw() + 5, cellEditBox.y + 20, 
                cellEditBox.xw() + 5, cellEditBox.yh() - 20,
                cellEditBox.xw() + 20, cellEditBox.y + 100
            );
            //grid background
            canvas.fill(EdColors.UI_DARK);
            canvas.rect(cellEditBox.x, cellEditBox.y, cellEditBox.w, cellEditBox.h);

            //filled cells (cells are 10 pixels square, grid is 20x20)
            canvas.fill(currentSkin().skinColor());
            int[] frame = currentFrame();
            int x, y;
            for (int i = 0; i < frame.length; i++) {
                if (frame[i] == 1) {
                    y = i / 20;
                    x = i % 20;
                    canvas.rect(cellEditBox.x + x * 10, cellEditBox.y + y * 10, 10, 10);
                }
            }

            //grid lines
            canvas.stroke(EdColors.UI_DARKEST);
            for (int i = 0; i < 21; i++) {
                if (i % 5 == 0) canvas.strokeWeight(2);
                else canvas.strokeWeight(1);
                canvas.line(
                    cellEditBox.x + i * 10, 
                    cellEditBox.y, 
                    cellEditBox.x + i * 10, 
                    cellEditBox.yh()
                );
                canvas.line(
                    cellEditBox.x, 
                    cellEditBox.y + i * 10, 
                    cellEditBox.xw(), 
                    cellEditBox.y + i * 10
                );
            }

            //cell highlight
            if (cellEditBox.isMouseOver()) {
                canvas.stroke(EdColors.UI_EMPHASIS);
                canvas.strokeWeight(3);
                canvas.noFill();
                x = (mouseX - (int)cellEditBox.screenX() - 1) / 10 * 10;
                y = (mouseY - (int)cellEditBox.screenY() - 1) / 10 * 10;
                canvas.rect(cellEditBox.x + x + 1, cellEditBox.y + y + 1, 8, 8);
            }

            //skin color
            canvas.noStroke();
            canvas.fill(serpentSkins[selectedSkin.value].skinColor());
            canvas.rect(buttonSets[3].buttons.body.x - 24, buttonSets[3].buttons.body.y, 24, 24);

            //buttons and labels
            canvas.fill(EdColors.UI_DARKEST);
            for (ButtonSet set : buttonSets) {
                set.buttons.draw(canvas);
                canvas.text(set.label, set.labelPos.x, set.labelPos.y);
            }
            canvas.popMatrix();

            //don't forget the palette
            palette.draw(canvas);
        }
 
        String mouse() {
            if (!isVisible) return "";
            else if (super.mouse() != "") return "dragging";
            else if (palette.mouse() != "") return "color stuff";
            else if (edwin.mouseBtnHeld != 0) {
                if (cellEditBox.isMouseOver()) {
                    //toggle cell
                    int x = mouseX - (int)cellEditBox.screenX() - 1;
                    int y = mouseY - (int)cellEditBox.screenY() - 1;
                    int index = (y / 10) * 20 + (x / 10);
                    int val = (edwin.mouseBtnHeld == LEFT ? 1 : 0);
                    currentFrame()[index] = val;
                }
            }
            else if (edwin.mouseBtnReleased == LEFT) {
                for (ButtonSet set : buttonSets) {
                    String response = set.buttons.mouse();
                    if (response != "") {
                        set.command.execute(response);
                        break;
                    }
                }
            }
            return "";
        }

        SerpentSkin currentSkin() {
            return serpentSkins[selectedSkin.value];
        }

        int[] currentFrame() {
            return currentSkin().frames.get(selectedFrame.value);
        }

        private class ButtonSet {
            Command command;
            GridButtons buttons;
            XY labelPos;
            String label;

            ButtonSet(String text, GridButtons gridButtons, Command cmd) {
                label = text;
                buttons = gridButtons;
                command = cmd;
                labelPos = new XY(buttons.body.xw() + UI_PADDING, buttons.body.yh() - 9);
            }
        }
    }

}


void flipSerpentBody() {
    //this function is ran in its own thread so it doesn't tie up the main draw loop
    //requires that the Ouroboros object is declared globally as o
    o.drawing = true;
    o.headColumn.increment();
    for (Ouroboros.SerpentSkin skin : o.serpentSkins) {
        skin.update();
    }

    PGraphics body = o.useBody1 ? o.body1 : o.body2;
    body.beginDraw();
    body.noStroke();
    body.clear(); //things could be arranged where we don't need to draw all the empty cells every time...

    XY center = new XY(width * 0.5, height * 0.5);
    int[] gameData;
    int x, y, r, g, b;
    int countAlive, cellColor;
    int grey = color(255 * 0.2, 255 * 0.2, 255 * 0.2);
    float angle, placementRadius, cellSize;
    float yDist = (o.OUTER_R - o.INNER_R) / (float)o.ROW_COUNT;
    float xDist = TWO_PI / (float)o.COLUMN_COUNT;
    for (int i = 0; i < o.GAME_SIZE; i++) {
        r = g = b = countAlive = 0;

        //see if this cell is alive in any of the skins
        for (Ouroboros.SerpentSkin skin : o.serpentSkins) {
            gameData = (o.useBody1 ? skin.gameState1 : skin.gameState2);
            if (!skin.isVisible || gameData[i] == 0) continue;
            //Fastest way of getting colors https://processing.org/reference/rightshift.html
            // int a = (colors[i] >> 24) & 0xFF;  
            r += (skin.skinColor() >> 16) & 0xFF;
            g += (skin.skinColor() >> 8) & 0xFF;
            b += skin.skinColor() & 0xFF;
            countAlive++;
        }

        if (countAlive > 0) cellColor = color(r / countAlive, g / countAlive, b / countAlive);
        else cellColor = grey;

        //calculate position
        x = i % o.COLUMN_COUNT;
        y = i / o.COLUMN_COUNT;
        cellSize = yDist - (y * 0.07); //cells shrink as they get closer to the center
        angle = (x * xDist) + (xDist * 0.5);
        placementRadius = o.OUTER_R - (y * yDist) - (yDist * 0.5);

        //draw cell
        body.fill(cellColor);
        body.ellipse(
            center.x + cos(angle) * placementRadius, 
            center.y + sin(angle) * placementRadius, 
            cellSize, 
            cellSize
        );
    }

    body.endDraw();

    //reset some variables
    if (o.step) {
        o.play = false;
        o.step = false;
    }
    o.nuke = false;
    o.drawing = false;
    o.lastSec = millis() / 1000.0;
    o.useBody1 = !o.useBody1;
}


