/**
* The tile editor. Define the color palette, create layers of pixels (one color per layer),
* then create "pages" of those layers and save that condensed spritesheet as an "Album" 
* Each page is a subset of the pixel layers in the Album, and each pixel layer can be in many pages. 
* This lets you easily make changes that cascade to all pages that share layers. 
* And restricting colors to a palette allows you change it for all sprites/pages at once. 
* You can use up/down to move between layers or pages depending on which list is shown
* and pressing control + up/down lets you reorder list items. 
*
* Still light on features, and could use a rewrite
* Used to be called EditorWindow (EDitor WINdow, Edwin, get it?)
* "Albums with Pages" used be to "Symbols with Expressions"
*
*/
public class AlbumEditor extends DraggableWindow {
    ArrayList<PixelLayer> pixelLayers;
    ArrayList<EditablePage> editablePages;
    PixelLayer selectedLayer, utilityLayer;
    EditablePage selectedPage;
    PalettePicker palette;
    GridButtons toolMenu;
    Album layerButtonAlbum;
    XYWH editBounds, previewBounds, layerListBounds;
    BoundedInt brushSize, zoomLevel; 
    BoundedFloat previewZoomLevel;
    String currentBrush, openFilepath;
    boolean showPages, showGrid;
    int spriteW, spriteH;
    final int LIH = 10; //list item height - height of layer list items, and width of its buttons
    //here I'm hardcoding page names from the albums
    //so don't rename the pages if you edit the buttons
    public static final String WINDOW_TITLE = "Album Editor ~ ",
    //main editor menu buttons
    BUTTON_FILENAME = "editorButtons.alb",
    BLANK = "blank",
    BRUSH = "brush", 
    LINE = "line",
    BRUSH_SMALLER = "brushSmaller", 
    BRUSH_BIGGER = "brushBigger", 
    RECTANGLE = "rectangle", 
    PERIMETER = "perimeter",
    ZOOM_IN = "zoomIn", 
    ZOOM_OUT = "zoomOut", 
    OPEN = "open", 
    SAVE = "save",
    ADD_LAYER = "addLayer",
    PALETTE_PICKER = "palettePicker",
    SET_SIZE = "setSize",
    LIST_TOGGLE = "listToggle",
    GRID_TOGGLE = "gridToggle",
    //layer list item buttons
    LAYER_BUTTON_FILENAME = "layerButtons.alb",
    DELETE = "delete",
    IS_VISIBLE = "isVisible",
    IS_NOT_VISIBLE = "isNotVisible",
    MOVE_DOWN = "moveDown",
    EDIT_COLOR = "editColor",
    EDIT_NAME = "editName";

    AlbumEditor() { this(true); }
    AlbumEditor(boolean initiallyVisible) {
        super(); //initialize DraggableWindow stuff
        isVisible = initiallyVisible;
        int margin = 20; //optional, can be 0 to take up the whole screen
        body.set(margin, margin, max(width - margin * 2, 600), max(height - margin * 2, 400));
        dragBar.w = body.w - UI_PADDING * 2;
        setWindowTitle("");
        spriteW = spriteH = 50;
        currentBrush = BRUSH;
        showPages = false;
        showGrid = true;
        openFilepath = null; //stays null until a new file is opened, at which point it will be loaded the next time draw() is called
        zoomLevel = new BoundedInt(1, 30, 6);
        previewZoomLevel = new BoundedFloat(0.5, 4, 1, 0.5);
        brushSize = new BoundedInt(1, 20, 3);
        layerButtonAlbum = new Album(LAYER_BUTTON_FILENAME);
        Album brushMenuAlbum = new Album(BUTTON_FILENAME);
        int menuColumns = 4; //can be changed but 4 seems best
        int menuW = menuColumns * (int)brushMenuAlbum.w;
        XY ui = new XY(dragBar.x, dragBar.yh() + UI_PADDING); //anchor for current UI body
        previewBounds = new XYWH(ui.x, ui.y, menuW, menuW, body);
        editBounds = new XYWH(ui.x + menuW + UI_PADDING, ui.y, body.w - menuW - UI_PADDING * 3, body.h - dragBar.h - UI_PADDING * 3, body);
        ui.y += previewBounds.h + UI_PADDING;
        toolMenu = new GridButtons(body, ui.x, ui.y, menuColumns, brushMenuAlbum, new String[] {
            BRUSH, LINE, BRUSH_SMALLER, BRUSH_BIGGER,
            RECTANGLE, PERIMETER, ZOOM_OUT, ZOOM_IN,
            PALETTE_PICKER, SET_SIZE, GRID_TOGGLE, BLANK,
            OPEN, SAVE, LIST_TOGGLE, ADD_LAYER
        });
        ui.y += toolMenu.body.h + UI_PADDING + LIH; //LIH here for the utility layer
        layerListBounds = new XYWH(ui.x, ui.y, menuW, body.h - ui.y - UI_PADDING, body);
        pixelLayers = new ArrayList<PixelLayer>();
        utilityLayer = new PixelLayer(-1, 0, new BitSet(spriteW * spriteH), new String[] { IS_VISIBLE, EDIT_COLOR }); //isVisible used for bgd vis, layer color for bgd color, pixels for the brush preview, and it has a custom GridButtons
        editablePages = new ArrayList<EditablePage>();
        selectedPage = new EditablePage(0, "first page", new int[] { 0 });
        editablePages.add(selectedPage);
        selectedLayer = new PixelLayer(0, 0, null);
        palette = new PalettePicker(new int[] { #FFFFFF, #000000 }, "Album colors", false) {
            void colorSelected(int paletteIndex) {
                selectedLayer.paletteIndex = paletteIndex;
            }
        };
        addPixelLayer(); 

        println("AlbumEditor (press e to toggle UI)");
    }

    void setWindowTitle(String text) { //TODO use more liberally to give feedback
        windowTitle = WINDOW_TITLE + text;
    }

    void addPixelLayer() { addPixelLayer(new BitSet(spriteW * spriteH), 1); }
    void addPixelLayer(BitSet pxls, int paletteIndex) {
        selectedLayer = new PixelLayer(pixelLayers.size(), paletteIndex, pxls);
        pixelLayers.add(selectedLayer);
        useLayer(pixelLayers.size() - 1);
    }

    /** Input layer index, receive color from palette */
    int colr(int index) { return colr(pixelLayers.get(index)); }
    int colr(PixelLayer layer) {
        return palette.colors.get(layer.paletteIndex);
    }

    // big methods ============================================================================================================================================
    void draw(PGraphics canvas) { // ======================================================================================================================
        //canvas.beginDraw() has already been called in Edwin
        if (!isVisible) return;
        super.draw(canvas); //draw DraggableWindow - the box bgd and the dragBar

        //This is so that we can't use the new Album from openFile() while the old one is still being drawn
        //openFilepath stays null until a new Album file is opened
        if (openFilepath != null) digestFile();
        
        //This must be called before translations, and popMatrix() reverses them
        canvas.pushMatrix();
        canvas.translate(body.x, body.y);

        //blank bgds
        canvas.noStroke();
        canvas.fill(EdColors.UI_DARKEST);
        canvas.rect(editBounds.x, editBounds.y, editBounds.w, editBounds.h);
        canvas.fill(EdColors.UI_DARK);
        canvas.rect(previewBounds.x, previewBounds.y, previewBounds.w, previewBounds.h);
        canvas.rect(layerListBounds.x, layerListBounds.y, layerListBounds.w, layerListBounds.h);

        canvas.fill(colr(utilityLayer));
        if (utilityLayer.isVisible) { //sprite bgds
            canvas.rect(editBounds.x, editBounds.y, min(editBounds.w, spriteW * zoomLevel.value), min(editBounds.h, spriteH * zoomLevel.value));
            canvas.rect(previewBounds.x, previewBounds.y, min(previewBounds.w, spriteW * previewZoomLevel.value), min(previewBounds.h, spriteH * previewZoomLevel.value));
        }
        canvas.rect(utilityLayer.listBody.x, utilityLayer.listBody.y, utilityLayer.listBody.w, utilityLayer.listBody.h);
        utilityLayer.buttons.draw(canvas); 
        listLabel(canvas, selectedPage.name, -1);

        //draw each layer scaled at zoomLevel
        PixelLayer thisLayer;
        float pixelX, pixelY;
        XYWH scaledPixel = new XYWH();
        for (int i = 0; i <= pixelLayers.size(); i++) {
            if (i == pixelLayers.size()) {
                thisLayer = utilityLayer;
                canvas.fill(EdColors.UI_EMPHASIS); //brush preview color
            }
            else if (!pixelLayers.get(i).isVisible) {
                continue;
            }
            else {
                thisLayer = pixelLayers.get(i);
                canvas.fill(colr(i));
            }

            //loop through BitSet, draw each pixel for this layer factoring in zoomLevel
            for (int j = 0; j < thisLayer.dots.size(); j++) {
                if (!thisLayer.dots.get(j)) continue; //if pixel isn't set, skip loop iteration
                
                //calculate coords based on the dot's index
                pixelY = floor(j / spriteW);
                pixelX = j - (pixelY * spriteW);

                //draw pixel in top left preview
                canvas.rect(
                    previewBounds.x + pixelX * previewZoomLevel.value, 
                    previewBounds.y + pixelY * previewZoomLevel.value, 
                    ceil(previewZoomLevel.value), 
                    ceil(previewZoomLevel.value));

                //determine rectangle to draw that represents the current pixel with current zoom level
                //and clipped at the edges if necessary
                scaledPixel.set(
                    editBounds.x + pixelX * zoomLevel.value,
                    editBounds.y + pixelY * zoomLevel.value,
                    min(zoomLevel.value, editBounds.w - pixelX * zoomLevel.value), 
                    min(zoomLevel.value, editBounds.h - pixelY * zoomLevel.value));
                //finally if we're in the pane, draw the zoomed pixel
                if (editBounds.intersects(scaledPixel)) {
                    canvas.rect(scaledPixel.x, scaledPixel.y, scaledPixel.w, scaledPixel.h);
                }
            }
        }

        //pixel grid lines
        if (showGrid && zoomLevel.value >= 6) {
            XY gridPt0 = new XY();
            XY gridPt1 = new XY();
            //vertical lines
            gridPt0.x = editBounds.x;
            gridPt1.x = editBounds.insideX(editBounds.x + spriteW * zoomLevel.value);
            for (int _y = 1; _y < spriteH; _y++) {
                if (_y % 10 == 0) canvas.stroke(EdColors.UI_EMPHASIS, 200);
                else if (zoomLevel.value < 12) continue;
                else canvas.stroke(EdColors.UI_DARK, 100);
                gridPt0.y = gridPt1.y = editBounds.insideY(editBounds.y + _y * zoomLevel.value);
                canvas.line(gridPt0.x, gridPt0.y, gridPt1.x, gridPt1.y);
            }
            //horizontal lines
            gridPt0.y = editBounds.y;
            gridPt1.y = editBounds.insideY(editBounds.y + spriteH * zoomLevel.value);
            for (int _x = 1; _x < spriteW; _x++) {
                if (_x % 10 == 0) canvas.stroke(EdColors.UI_EMPHASIS, 200);
                else if (zoomLevel.value < 12) continue;
                else canvas.stroke(EdColors.UI_DARK, 100);
                gridPt0.x = gridPt1.x = editBounds.insideX(editBounds.x + _x * zoomLevel.value);
                canvas.line(gridPt0.x, gridPt0.y, gridPt1.x, gridPt1.y);
            }
            canvas.noStroke();
        }

        //layer list items/menus
        if (showPages) {
            int selectedPageIndex = editablePages.indexOf(selectedPage);
            for (int i = 0; i < editablePages.size(); i++) {
                canvas.fill((i % 2 == 0) ? EdColors.ROW_EVEN : EdColors.ROW_ODD);
                canvas.rect(
                    layerListBounds.x, 
                    layerListBounds.y + (LIH * i), 
                    layerListBounds.w, 
                    LIH);
                //if this is the selected item, display extra wide body
                if (i == selectedPageIndex || editablePages.get(i).listBody.isMouseOver()) {
                    canvas.rect(
                        layerListBounds.x - UI_PADDING,
                        layerListBounds.y + (LIH * i), 
                        layerListBounds.w + UI_PADDING * 2, 
                        LIH);
                }
                listLabel(canvas, editablePages.get(i).name, i);
                editablePages.get(i).buttons.draw(canvas);
            }
        }
        else {
            int selectedLayerIndex = pixelLayers.indexOf(selectedLayer);
            for (int i = 0; i < pixelLayers.size(); i++) {
                canvas.fill(colr(i));
                canvas.rect(
                    layerListBounds.x, 
                    layerListBounds.y + (LIH * i), 
                    layerListBounds.w, 
                    LIH);
                //if this is the selected item, display extra wide body and name
                if (i == selectedLayerIndex || pixelLayers.get(i).listBody.isMouseOver()) {
                    canvas.rect(
                        layerListBounds.x - UI_PADDING,
                        layerListBounds.y + (LIH * i), 
                        layerListBounds.w + UI_PADDING * 2, 
                        LIH);
                    listLabel(canvas, pixelLayers.get(i).name, i);
                }
                pixelLayers.get(i).buttons.draw(canvas);
            }
        }

        //draw menus
        toolMenu.draw(canvas); //brushes, zoom, open/save and other buttons
        canvas.popMatrix(); //undo translate()
        palette.draw(canvas); //standalone draggable window
    } // end draw() =======================================================================================================================================
    // ========================================================================================================================================================

    /** convenience method */
    void listLabel(PGraphics canvas, String label, int index) {
        canvas.fill(EdColors.UI_LIGHT);
        canvas.rect(layerListBounds.x, layerListBounds.y + LIH * index, canvas.textWidth(label) + 1, LIH);
        canvas.fill(EdColors.UI_DARKEST);
        canvas.text(label, layerListBounds.x, layerListBounds.y + (LIH * (index + 1)) - 2);
    }

    String mouse() {
        if (!isVisible) return "";
        if (palette.mouse() != "" || super.mouse() != "") { //if the palette handles the event, or the window is being dragged
            return HELLO;
        }

        if (edwin.mouseBtnBeginHold != 0 || edwin.mouseBtnReleased != 0) {
            utilityLayer.dots.clear(); //clear brush preview
        }

        if (!body.isMouseOver()) {
            return "";
        }

        if (previewBounds.isMouseOver()) {
            if (edwin.mouseWheelValue == -1) {
                previewZoomLevel.increment();
            }
            else if (edwin.mouseWheelValue == 1) {
                previewZoomLevel.decrement();
            }
        }

        //now for determining which area/menu was clicked and how to handle it
        //I use switches for menus to make it easier to distinguish from other logic
        if (editBounds.isMouseOver()) {
            if (edwin.mouseHovering) { 
                switch (currentBrush) {
                    case BRUSH:
                        //hovering brush preview
                        utilityLayer.dots.clear();
                        applyBrush(utilityLayer, true);
                        break;
                }
            }
            else if (edwin.mouseBtnHeld == LEFT || edwin.mouseBtnHeld == RIGHT) {
                switch (currentBrush) {
                    case BRUSH:
                        applyBrush(selectedLayer, (edwin.mouseBtnHeld == LEFT)); // ? true : false
                        break;
                    case LINE:
                    case RECTANGLE:
                    case PERIMETER:
                        //brush preview
                        utilityLayer.dots.clear();
                        applyBrush(utilityLayer, true);
                        break;
                }
            }
            else if (edwin.mouseBtnReleased == LEFT || edwin.mouseBtnReleased == RIGHT) {
                switch (currentBrush) {
                    case LINE:
                    case RECTANGLE:
                    case PERIMETER:
                        applyBrush(selectedLayer, (edwin.mouseBtnReleased == LEFT));
                        break;
                }
            }
            return HELLO; //?
        }
        else if (edwin.mouseBtnReleased != LEFT) {
            utilityLayer.dots.clear(); //clear brush preview
            return ""; //otherwise if the mouse event wasn't a left click release then leave because we're not interested anymore
        }

        String buttonPage = toolMenu.mouse(); //primary menu buttons below preview
        switch (buttonPage) {
            case BRUSH:
            case LINE:
            case RECTANGLE:
            case PERIMETER:
                currentBrush = buttonPage;
                break;
            case ZOOM_IN: 
                zoomLevel.increment();
                break;
            case ZOOM_OUT: 
                zoomLevel.decrement();
                break;
            case BRUSH_BIGGER:
                brushSize.increment();
                break;
            case BRUSH_SMALLER:
                brushSize.decrement();
                break;
            case ADD_LAYER:
                if (showPages) {
                    String newName = JOptionPane.showInputDialog("Enter new page name\nPress X to toggle layer menu", "newpage");
                    if (newName == null) return "";
                    //check for duplicate name
                    for (EditablePage page : editablePages) {
                        if (page.name.equals(newName)) {
                            JOptionPane.showMessageDialog(null, "Duplicate name found", "Hey", JOptionPane.ERROR_MESSAGE);
                            return "";
                        }
                    }
                    int lastIndex = editablePages.size();
                    selectedPage = new EditablePage(lastIndex, newName, new int[] { });
                    editablePages.add(selectedPage);
                    usePage(lastIndex);
                }
                else {
                    addPixelLayer();
                    selectedPage.layerIndicies.add(pixelLayers.size() - 1); //add new layer to current page
                }
                break;
            case PALETTE_PICKER: 
                palette.toggleVisibility();
                palette.body.set(mouseX, mouseY);
                break;
            case SAVE:
                selectOutput("Save Album .alb", "saveFile", null, this);
                break;
            case OPEN:
                selectInput("Open Album .alb", "openFile", null, this);
                break;
            case LIST_TOGGLE:
                showPages = !showPages;
                break;
            case SET_SIZE:
                String newSize = JOptionPane.showInputDialog("Enter new sprite size as w,h", spriteW + "," + spriteH);
                if (newSize == null) return ""; //canceled
                String[] sizes = newSize.split(",");
                int newWidth = 0, newHeight = 0;
                try {
                    newWidth = Integer.parseInt(sizes[0].trim());
                    newHeight = Integer.parseInt(sizes[1].trim());
                }
                catch (Exception e) {
                    JOptionPane.showMessageDialog(null, "\"" + newSize + "\" does not fit the format of w,h", "Hey", JOptionPane.ERROR_MESSAGE);
                    return "";
                }
                //new bounds parsed, now we change the BitSets of the PixelLayers
                for (PixelLayer layer : pixelLayers) {
                    layer.updateBounds(newWidth, newHeight);
                }
                spriteW = newWidth;
                spriteH = newHeight;
                break;
            case GRID_TOGGLE:
                showGrid = !showGrid;
                break;
            case BLANK:
                //stupid hack to shift my layer's pixels to the right
                // for (int i = selectedLayer.dots.size() - 1; i > 0; i--) {
                //  if (selectedLayer.dots.get(i -1)) {
                //      selectedLayer.dots.set(i, true);
                //      selectedLayer.dots.set(i - 1, false);
                //  }
                // }
                break;
        }
        if (buttonPage != "") {
            return HELLO;
        }

        buttonPage = utilityLayer.buttons.mouse();
        if (buttonPage == IS_VISIBLE || buttonPage == IS_NOT_VISIBLE) {
            utilityLayer.toggleVisibility();
            return "bgd color toggled";
        }
        else if (buttonPage == EDIT_COLOR) {
            utilityLayer.paletteIndex = palette.selectedColor.value;
            return "bgd color chosen";
        }
        else if (!layerListBounds.isMouseOver() || editBounds.containsPoint(edwin.mouseHoldInitial)) {
            return "";
        }
        else if (showPages) {
            int index = -1;
            //loop through the list of pages and check to see if any were clicked
            for (int i = 0; i < editablePages.size(); i++) {
                buttonPage = editablePages.get(i).buttons.mouse();
                if (buttonPage != "") {
                    index = i;
                    break;
                }
                else if (editablePages.get(i).listBody.isMouseOver()) {
                    usePage(i);
                    return "page selected";
                }
            }
            if (index == -1) {
                return "";
            }
            usePage(index);
            switch (buttonPage) {
                case DELETE:
                    if (editablePages.size() == 1) {
                        JOptionPane.showMessageDialog(null, "Can't delete page when it's the only one", "Hey", JOptionPane.INFORMATION_MESSAGE);
                        break;
                    }
                    int choice = JOptionPane.showConfirmDialog(null, "Really delete page \"" + selectedPage.name + "\"?", "Delete Page?", JOptionPane.YES_NO_OPTION, JOptionPane.WARNING_MESSAGE);
                    if (choice != JOptionPane.YES_OPTION) return "";
                    editablePages.remove(index);
                    if (index > 0) {
                        for (int i = index; i < editablePages.size(); i++) {
                            editablePages.get(i).buttons.body.y -= LIH;
                            editablePages.get(i).listBody.y -= LIH;
                        }
                    }
                    usePage(min(index, editablePages.size() - 1));
                    break;
                case EDIT_NAME:
                    String newName = JOptionPane.showInputDialog("Enter new page name", selectedPage.name);
                    if (newName == null || newName.equals(selectedPage.name)) return "";
                    //check for duplicate name
                    for (EditablePage page : editablePages) {
                        if (page.name.equals(newName)) {
                            JOptionPane.showMessageDialog(null, "Duplicate name found", "Hey", JOptionPane.ERROR_MESSAGE);
                            return "";
                        }
                    }
                    selectedPage.name = newName;
                    break;
                case MOVE_DOWN:
                    movePageDown(index);
                    break;
            }
            return HELLO;
        }
        //else: layer list items are visible and that area was clicked

        int index = -1;
        //loop through the list of layers and check to see if any were clicked
        for (int i = 0; i < pixelLayers.size(); i++) {
            buttonPage = pixelLayers.get(i).buttons.mouse();
            if (buttonPage != "") {
                index = i;
                break;
            }
            else if (pixelLayers.get(i).listBody.isMouseOver()) {
                useLayer(i);
                return "layer selected";
            }
        }
        if (index == -1) {
            return "";
        }
        useLayer(index);
        switch (buttonPage) {
            case DELETE:
                if (pixelLayers.size() == 1) {
                    JOptionPane.showMessageDialog(null, "Can't delete layer when it's the only one", "Hey", JOptionPane.INFORMATION_MESSAGE);
                    break;
                }
                int deleteChoice = JOptionPane.showConfirmDialog(null, "Really delete layer \"" + selectedLayer.name + "\"?", "Delete Layer?", JOptionPane.YES_NO_OPTION, JOptionPane.WARNING_MESSAGE);
                if (deleteChoice != JOptionPane.YES_OPTION) return "";
                pixelLayers.remove(index);
                if (pixelLayers.indexOf(selectedLayer) == -1) {
                    useLayer(0);
                }
                for (int i = index; i < pixelLayers.size(); i++) {
                    pixelLayers.get(i).buttons.body.y -= LIH; //gotta shift the GridButtons manually for now...
                    pixelLayers.get(i).listBody.y -= LIH; 
                }
                for (EditablePage page : editablePages) {
                    page.deleteLayer(index);
                }
                break;
            case EDIT_NAME:
                String newName = JOptionPane.showInputDialog("Enter new layer name", selectedLayer.name);
                if (newName != null) selectedLayer.name = newName;
                break;
            case MOVE_DOWN:
                moveLayerDown(index);
                break;
            case IS_VISIBLE:
            case IS_NOT_VISIBLE:
                selectedLayer.toggleVisibility();
                selectedPage.setLayerVisibility(index, selectedLayer.isVisible);
                break;
        }
        return HELLO;
    } // end mouse() ==========================================================================================================================================
    // ========================================================================================================================================================

    String keyboard(KeyEvent event) {
        int kc = event.getKeyCode();
        if (!isVisible && kc != Keycodes.E) {
            return "";
        }
        else if (kc == Keycodes.Z) {
            zoomLevel.increment();
        }
        else if (kc == Keycodes.A) {
            zoomLevel.decrement();
        }
        else if (event.getAction() != KeyEvent.RELEASE) { //the keys above react to any event, below only to RELEASE
            return "";
        }
        else if (kc == Keycodes.X) {
            showPages = !showPages;
        }
        else if (kc == Keycodes.E) {
            toggleVisibility();
        }
        else if (kc == Keycodes.C) {
            palette.toggleVisibility();
        }
        else if (kc == Keycodes.V) {
            selectedLayer.toggleVisibility();
            selectedPage.setLayerVisibility(pixelLayers.indexOf(selectedLayer), selectedLayer.isVisible);
        }
        else if (kc == Keycodes.UP) {
            int selLayer = pixelLayers.indexOf(selectedLayer);
            int selPage = editablePages.indexOf(selectedPage);
            if (showPages) {
                if (event.isControlDown()) {
                    if (selPage > 0) movePageDown(selPage - 1);
                }
                else {
                    if (selPage > 0) usePage(selPage - 1);
                }
            }
            else if (event.isControlDown()) {
                if (selLayer > 0) moveLayerDown(selLayer - 1);
            }
            else {
                if (selLayer > 0) useLayer(selLayer - 1);
            }
        }
        else if (kc == Keycodes.DOWN) {
            int selLayer = pixelLayers.indexOf(selectedLayer);
            int selPage = editablePages.indexOf(selectedPage);
            if (showPages) {
                if (event.isControlDown()) {
                    if (selPage < editablePages.size() - 1) movePageDown(selPage);
                }
                else {
                    if (selPage < editablePages.size() - 1) usePage(selPage + 1);
                }
            }
            else if (event.isControlDown()) {
                if (selLayer < pixelLayers.size() - 1) moveLayerDown(selLayer);
            }
            else {
                if (selLayer < pixelLayers.size() - 1) useLayer(selLayer + 1);
            }
        }
        else if (kc == Keycodes.O && event.isControlDown()) {
            selectInput("Open Album .alb", "openFile", null, this);
        }
        else if (kc == Keycodes.S && event.isControlDown()) {
            selectOutput("Save Album .alb", "saveFile", null, this);
        }
        else {
            return "";
        }
        return HELLO;
    }// end keyboard() and big methods ========================================================================================================================
    // ========================================================================================================================================================

    void useLayer(int index) {
        selectedLayer = pixelLayers.get(index);
        palette.selectedColor.set(selectedLayer.paletteIndex);
    }

    void moveLayerDown(int index) {
        //TODO make cleaner...
        if (index >= pixelLayers.size() - 1) return; //can't move the last layer down
        pixelLayers.get(index).buttons.body.y += LIH;
        pixelLayers.get(index).listBody.y += LIH;
        pixelLayers.get(index + 1).buttons.body.y -= LIH;
        pixelLayers.get(index + 1).listBody.y -= LIH;
        Collections.swap(pixelLayers, index, index + 1);
        //now we'll check each page for either PixelLayer being swapped and adjust their index value
        int indexItem, indexBelowItem;
        for (EditablePage page : editablePages) {
            indexItem = page.layerIndicies.indexOf(index);
            indexBelowItem = page.layerIndicies.indexOf(index + 1);
            if (indexItem != -1) page.layerIndicies.set(indexItem, index + 1);
            if (indexBelowItem != -1) page.layerIndicies.set(indexBelowItem, index);
        }
    }

    void usePage(int index) {
        selectedPage = editablePages.get(index);
        //turn all layers off
        for (int i = 0; i < pixelLayers.size(); i++) {
            if (pixelLayers.get(i).isVisible) {
                pixelLayers.get(i).toggleVisibility();
            }
        }
        //turn on layers selectively
        int selLayer = 0;
        for (int l : selectedPage.layerIndicies) {
            pixelLayers.get(l).toggleVisibility();
            selLayer = l;
        }
        useLayer(selLayer);
    }

    void movePageDown(int index) {
        //TODO make cleaner...
        if (index >= editablePages.size() - 1) { //can't move the last layer down
            return;
        }
        editablePages.get(index).buttons.body.y += LIH; 
        editablePages.get(index).listBody.y += LIH;
        editablePages.get(index + 1).buttons.body.y -= LIH;
        editablePages.get(index + 1).listBody.y -= LIH;
        Collections.swap(editablePages, index, index + 1);
    }

    /**
    * brushVal == true means setting pixels
    * brushVal == false means removing pixels
    */
    void applyBrush(PixelLayer pixelLayer, boolean brushVal) {
        //these figures are aimed at consistency while zoomed
        XY mouseTranslated = new XY(round((mouseX - body.x - editBounds.x - (zoomLevel.value * .4)) / zoomLevel.value), 
            round((mouseY - body.y - editBounds.y - (zoomLevel.value * .4)) / zoomLevel.value));
        XY mouseInitialTranslated = new XY(round(edwin.mouseHoldInitial.x - body.x - editBounds.x) / zoomLevel.value, 
            round(edwin.mouseHoldInitial.y - body.y - editBounds.y) / zoomLevel.value);

        if (!pixelLayer.isVisible && pixelLayer != utilityLayer) return; //can't draw on layers that aren't visible, except 0 is a special case

        if (currentBrush == BRUSH) {
            //square of size brushSize
            pixelLayer.pixelRectangle(brushVal, mouseTranslated.x, mouseTranslated.y, (float)brushSize.value, (float)brushSize.value);
        }
        else if (currentBrush == RECTANGLE) {
            //just a solid block
            pixelLayer.pixelRectangle(brushVal, 
                min(mouseInitialTranslated.x, mouseTranslated.x),
                min(mouseInitialTranslated.y, mouseTranslated.y),
                abs(mouseInitialTranslated.x - mouseTranslated.x),
                abs(mouseInitialTranslated.y - mouseTranslated.y));
        }
        else if (currentBrush == PERIMETER) {
            //perimeter is the outline of a rectangle
            //so we will be adding in a rectangle of points for each side
            XYWH rectArea = new XYWH(
                min(mouseInitialTranslated.x, mouseTranslated.x),
                min(mouseInitialTranslated.y, mouseTranslated.y),
                abs(mouseInitialTranslated.x - mouseTranslated.x),
                abs(mouseInitialTranslated.y - mouseTranslated.y));
            //left
            pixelLayer.pixelRectangle(brushVal, 
                rectArea.x, 
                rectArea.y, 
                min(brushSize.value, rectArea.w), 
                rectArea.h);
            //top
            pixelLayer.pixelRectangle(brushVal, 
                rectArea.x, 
                rectArea.y, 
                rectArea.w, 
                min(brushSize.value, rectArea.h));
            //right
            pixelLayer.pixelRectangle(brushVal, 
                max(rectArea.xw() - brushSize.value, rectArea.x),
                rectArea.y, 
                min(brushSize.value, rectArea.w),
                rectArea.h);
            //bottom
            pixelLayer.pixelRectangle(brushVal, 
                rectArea.x, 
                max(rectArea.yh() - brushSize.value, rectArea.y),
                rectArea.w, 
                min(brushSize.value, rectArea.h));
        }
        else if (currentBrush == LINE) {
            //line of brushSize width
            //math.stackexchange.com/a/2109383
            float segmentIncrement = 1;
            float lineDist = mouseInitialTranslated.distance(mouseTranslated);
            XY newPoint = new XY();
            pixelLayer.pixelRectangle(brushVal, 
                mouseTranslated.x, 
                mouseTranslated.y, 
                brushSize.value, 
                brushSize.value);
            for (float segDist = 0; segDist <= lineDist; segDist += segmentIncrement) {
                newPoint.set(
                    mouseInitialTranslated.x - (segDist * (mouseInitialTranslated.x - mouseTranslated.x)) / lineDist, 
                    mouseInitialTranslated.y - (segDist * (mouseInitialTranslated.y - mouseTranslated.y)) / lineDist);
                pixelLayer.pixelRectangle(brushVal, newPoint.x, newPoint.y, brushSize.value - 1, brushSize.value - 1);
            }
        }
    }
    
    void openFile(File file) {
        if (file == null) return; //user hit cancel or closed
        setWindowTitle(file.getName());
        openFilepath = file.getAbsolutePath();
        //Next time draw() is called it'll call digestFile() so we don't screw with variables potentially in use 
        //since we might be in the middle of drawing at this time. Then openFilepath becomes null.
    }

    /** Load file into editor variables */
    void digestFile() {
        JSONObject json = loadJSONObject(openFilepath);
        openFilepath = null;
        spriteW = json.getInt(EdFiles.PX_WIDTH);
        spriteH = json.getInt(EdFiles.PX_HEIGHT);
        palette.resetColors(json);
        pixelLayers.clear();
        editablePages.clear();

        //colors
        if (json.isNull(EdFiles.BGD_COLOR)) {
            if (utilityLayer.isVisible) utilityLayer.toggleVisibility();
            utilityLayer.paletteIndex = 0;
        }
        else {
            if (!utilityLayer.isVisible) utilityLayer.toggleVisibility();
            utilityLayer.paletteIndex = json.getInt(EdFiles.BGD_COLOR);
        }

        //pixel layers
        JSONArray jsonLayers = json.getJSONArray(EdFiles.PIXEL_LAYERS);
        for (int i = 0; i < jsonLayers.size(); i++) {
            JSONObject thisLayer = jsonLayers.getJSONObject(i);
            BitSet pxls = new BitSet(spriteW * spriteH);
            for (int v : thisLayer.getJSONArray(EdFiles.DOTS).getIntArray()) {
                pxls.set(v);
            }
            addPixelLayer(pxls, thisLayer.getInt(EdFiles.PALETTE_INDEX)); 
            pixelLayers.get(i).name = thisLayer.getString(EdFiles.PIXEL_LAYER_NAME);
        }
        useLayer(0);

        //pages of the album
        JSONArray jsonPages = json.getJSONArray(EdFiles.ALBUM_PAGES);
        for (int i = 0; i < jsonPages.size(); i++) {
            JSONObject page = jsonPages.getJSONObject(i);
            editablePages.add(new EditablePage(i, page.getString(EdFiles.PAGE_NAME), page.getJSONArray(EdFiles.LAYER_NUMBERS).getIntArray()));
        }
        usePage(0);
    }

    /**
    * So unfortunately for me the default toString() methods for JSONObject and JSONArray that were provided by 
    * the wonderful Processing devs give each value their own line. So the dump I'm trying to take is too big for that, 
    * and this is my attempt at significantly fewer newline characters and having a sorted readable format.
    * Also I don't know how to work with binary files.
    */
    void saveFile(File file) {
        if (file == null) return; //user closed window or hit cancel
        ArrayList<String> fileLines = new ArrayList<String>();
        fileLines.add("{"); //opening bracket
        fileLines.add(jsonKV(EdFiles.PX_WIDTH, spriteW));
        fileLines.add(jsonKV(EdFiles.PX_HEIGHT, spriteH));
        fileLines.add(palette.asJsonKV());
        fileLines.add(jsonKV(EdFiles.BGD_COLOR, (utilityLayer.isVisible ? String.valueOf(utilityLayer.paletteIndex) : "null")));
        fileLines.add("");
        fileLines.add(jsonKVNoComma(EdFiles.PIXEL_LAYERS, "[{")); //array of objects
        BitSet pxls;
        String line;
        int valueCount;
        for (int i = 0; i < pixelLayers.size(); i++) {
            if (i > 0) fileLines.add("},{"); //separation between layer objects in this array
            fileLines.add(TAB + jsonKVString(EdFiles.PIXEL_LAYER_NAME, pixelLayers.get(i).name));
            fileLines.add(TAB + jsonKV(EdFiles.PALETTE_INDEX, pixelLayers.get(i).paletteIndex));
            fileLines.add(TAB + jsonKVNoComma(EdFiles.DOTS, "[")); 
            pxls = pixelLayers.get(i).dots;
            line = "";
            valueCount = -1;
            for (int j = 0; j < pxls.size(); j++) {
                if (!pxls.get(j)) continue;
                if (++valueCount == 25) {
                    valueCount = 0;
                    fileLines.add(TAB + TAB + line);
                    line = "";
                }
                line += j + ", ";
            }
            fileLines.add(TAB + TAB + line);
            fileLines.add(TAB + "]"); //close DOTS
        }
        fileLines.add("}],"); //close last layer and array
        fileLines.add("");
        fileLines.add(jsonKVNoComma(EdFiles.ALBUM_PAGES, "[{"));
        for (int i = 0; i < editablePages.size(); i++) {
            if (i > 0) fileLines.add("},{"); //separation between layer objects in this array
            EditablePage page = editablePages.get(i);
            Collections.sort(page.layerIndicies);
            fileLines.add(TAB + jsonKVString(EdFiles.PAGE_NAME, page.name));
            fileLines.add(TAB + jsonKV(EdFiles.LAYER_NUMBERS, page.layerIndicies.toString()));
        }
        fileLines.add("}]"); //close last page and array
        fileLines.add("}"); //final closing bracket
        saveStrings(file.getAbsolutePath(), fileLines.toArray(new String[0]));
        setWindowTitle(file.getName());
    }

    private class PixelLayer {
        XYWH listBody;
        GridButtons buttons;
        BitSet dots;
        String name;
        int paletteIndex;
        boolean isVisible;

        PixelLayer(int index, int colorPaletteIndex, BitSet pxls) {
            this(index, colorPaletteIndex, pxls, new String[] { IS_VISIBLE, MOVE_DOWN, EDIT_NAME, DELETE });
        }

        PixelLayer(int index, int colorPaletteIndex, BitSet pxls, String[] buttonNames) {
            paletteIndex = colorPaletteIndex;
            dots = pxls;
            isVisible = true;
            name = "newlayer";
            buttons = new GridButtons(body, 
                layerListBounds.xw() - layerButtonAlbum.w * buttonNames.length, 
                layerListBounds.y + layerButtonAlbum.h * index, 
                buttonNames.length, 
                layerButtonAlbum, 
                buttonNames
            );
            listBody = new XYWH(
                layerListBounds.x, 
                layerListBounds.y + index * LIH,
                layerListBounds.w,
                LIH,
                body
            );
        }

        /** requires that the is_visible page is the first item in the array */
        void toggleVisibility() {
            isVisible = !isVisible;
            buttons.buttonPages[0] = (isVisible ? IS_VISIBLE : IS_NOT_VISIBLE);
        }

        /**
        * brushVal == true means setting pixels
        * brushVal == false means removing pixels
        */
        void pixelRectangle(boolean brushVal, float _x, float _y, float _w, float _h) {
            //if rectangle isn't in bounds, leave
            if (_x >= spriteW || _y >= spriteH ||
                _x + _w < 0 || _y + _h < 0) {
                return;
            }
            //clamp boundaries
            _x = max(_x, 0);
            _y = max(_y, 0);
            _w = min(_w, spriteW - _x);
            _h = min(_h, spriteH - _y);
            //finally, loop through each pixel in rect and set it
            for (int y = (int)_y; y < _y + _h; y++) {
                for (int x = (int)_x; x < _x + _w; x++) {
                    dots.set(y * spriteW + x, brushVal);
                }
            }
        }

        /** Create new BitSet for the pixels and copy old dots over */
        void updateBounds(int _w, int _h) {
            BitSet newDots = new BitSet(_w * _h);
            XY point = new XY();
            for (int i = 0; i < dots.size(); i++) {
                if (!dots.get(i)) continue; //if pixel isn't set, skip loop
                point.y = floor(i / (float)spriteW);
                point.x = i - (point.y * spriteW);
                if (point.x >= _w || point.y >= _h) continue;
                newDots.set((int)(point.y * _w + point.x)); //find new index with the new width
            }
            dots = newDots;
        }
    }

    private class EditablePage {
        XYWH listBody;
        GridButtons buttons;
        ArrayList<Integer> layerIndicies;
        String name;

        EditablePage(int index, String pageName, int[] layerIds) {
            name = pageName;
            layerIndicies = new ArrayList<Integer>(); //visible PixelLayers
            for (int i = 0; i < layerIds.length; i++) {
                layerIndicies.add(layerIds[i]);
            }
            String[] buttonNames = new String[] { MOVE_DOWN, EDIT_NAME, DELETE };
            buttons = new GridButtons(body, 
                layerListBounds.xw() - layerButtonAlbum.w * buttonNames.length, 
                layerListBounds.y + layerButtonAlbum.h * index, 
                buttonNames.length, 
                layerButtonAlbum, 
                buttonNames
            );
            listBody = new XYWH(
                layerListBounds.x, 
                layerListBounds.y + index * LIH,
                layerListBounds.w,
                LIH,
                body
            );
        }

        void setLayerVisibility(int index, boolean visible) {
            int existing = -1;
            for (int i = 0; i < layerIndicies.size(); i++) {
                if (layerIndicies.get(i) == index) {
                    existing = i;
                    break;
                }
            }
            if (visible && existing == -1) { //if we want to set it and it doesn't exist
                layerIndicies.add(index);
            }
            else if (!visible && existing != -1) { //if we want to remove it and it does exist
                layerIndicies.remove(existing);
            }
        }

        void deleteLayer(int index) {
            int existing = -1;
            for (int i = 0; i < layerIndicies.size(); i++) {
                if (layerIndicies.get(i) == index) {
                    existing = i;
                }
                else if (layerIndicies.get(i) > index) {
                    layerIndicies.set(i, layerIndicies.get(i) - 1); //shift other layers up a value
                }
            } 
            if (existing != -1) {
                layerIndicies.remove(existing);
            }
        }
    }

} //end AlbumEditor


/** 
* A kind of sprite sheet that is made by my tile editor AlbumEditor.
* Albums have one set of pixel layers, and another set of "pages" that use 
* any number of those pixel layers to create an image. Also requires a 
* color palette so each pixel layer uses only one color. This allows you to
* reuse layers and quickly change the color scheme of all images fast and uniformly. 
* Files are typically saved with a .alb extension and are plain text (json)
* Just use its page() function to get a single image from the album
*/
class Album {
    PGraphics[] pages; //images or frames
    IntDict tableOfContents;
    int pixelW, pixelH;
    float w, h, scale;
    String filename;

    Album(String filename) { this(filename, 1.0); }
    Album(String filename, float scale) {
        this.filename = filename;
        this.scale = scale;
        reload();
    }

    void reload() { 
        JSONObject json = loadJSONObject(EdFiles.DATA_FOLDER + filename);
        JSONArray jsonPages = json.getJSONArray(EdFiles.ALBUM_PAGES);
        JSONArray jsonLayers = json.getJSONArray(EdFiles.PIXEL_LAYERS);
        JSONArray colorPalette = json.getJSONArray(EdFiles.COLOR_PALETTE);
        pixelW = json.getInt(EdFiles.PX_WIDTH);
        pixelH = json.getInt(EdFiles.PX_HEIGHT);
        w = pixelW * scale;
        h = pixelH * scale;
        tableOfContents = new IntDict();
        pages = new PGraphics[jsonPages.size()];
        int x = 0, y = 0; //x is calculated using y
        //loop through each page and draw it
        for (int i = 0; i < jsonPages.size(); i++) {
            JSONObject jsonPage = jsonPages.getJSONObject(i);
            PGraphics sheet = createGraphics((int)w, (int)h);
            sheet.beginDraw();
            sheet.noStroke();
            if (!json.isNull(EdFiles.BGD_COLOR)) {
                sheet.background(colorPalette.getInt(json.getInt(EdFiles.BGD_COLOR)));
            }
            //loop through each pixel layer used by the page
            for (int visibleLayerIndex : jsonPage.getJSONArray(EdFiles.LAYER_NUMBERS).getIntArray()) {
                JSONObject thisLayer = jsonLayers.getJSONObject(visibleLayerIndex);
                sheet.fill(colorPalette.getInt(thisLayer.getInt(EdFiles.PALETTE_INDEX)));
                //draw layer to current page
                for (int pixelIndex : thisLayer.getJSONArray(EdFiles.DOTS).getIntArray()) {
                    //translate pixel index (from BitSet) to its xy coord
                    y = pixelIndex / pixelW;
                    x = pixelIndex - (y * pixelW);
                    sheet.rect(x * scale, y * scale, ceil(scale), ceil(scale));
                    //sheet.point(x, y);
                }
            }
            sheet.endDraw();
            pages[i] = sheet;
            tableOfContents.set(jsonPage.getString(EdFiles.PAGE_NAME), i);
        }
    }

    /**
    * Return the image associated with the pageName.
    * If it doesn't exist return the image at index 0 (the first defined page)
    */
    PGraphics page(String pageName) {
        return pages[tableOfContents.get(pageName, 0)];
    }

    PGraphics randomPage() {
        return pages[(int)random(pages.length)];
    }
}


/**
* Not done... 
*/
class AlbumAnimator implements Kid {
    Album album;
    BoundedInt frame, delay;
    XY offset;
    final String prefix = "torch";

    AlbumAnimator() { this(2.0); }
    AlbumAnimator(float scale) {
        // album = new Album("tiles/platformer_flame.alb", scale);
        offset = new XY();
        frame = new BoundedInt(0, 5);
        frame.loops = true;
        delay = new BoundedInt(0, 3);
        delay.loops = true;
    }

    void draw(PGraphics canvas) {
        if (delay.increment() == delay.maximum) frame.increment();
        // canvas.image(album.page(prefix + frame.value), offset.x, offset.y);
    }

    String mouse() {
        if (edwin.mouseBtnHeld == CENTER) {
            offset.set(mouseX, mouseY);
        }
        return "";
    }

    String keyboard(KeyEvent event) {
        if (event.getAction() != KeyEvent.RELEASE) {
            return "";
        }
        int kc = event.getKeyCode();
        if (kc == Keycodes.S) {
            offset.x += 1;
        }
        else if (kc == Keycodes.X) {
            offset.x += album.scale;
        }
        else if (kc == Keycodes.A) {
            offset.y += 1;
        }
        else if (kc == Keycodes.Z) {
            offset.y += album.scale;
        }
        return "";
    }
}
