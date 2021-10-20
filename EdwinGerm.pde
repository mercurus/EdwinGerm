Edwin edwin;
Ouroboros o;

void setup() {
    //fullScreen();
    size(1200, 1000, P2D);
    edwin = new Edwin(EdColors.DX_BROWN);
    edwin.useSmooth = false;

    // edwin.addKid(new StarBackdrop());
    // edwin.addKid(new PixelStarBackdrop(200));
    // edwin.addKid(new Ricochet());
    
    edwin.addKid(new ArcAttractor());
    o = new Ouroboros("firstSkin.oro");
    edwin.addKid(o);
    // edwin.addKid(new GSigil());
    
    // edwin.addKid(new MinesweeperGame());
    // edwin.addKid(new ReferenceImagePositioner());
    // edwin.addKid(new StarWebPositioner());
    // edwin.addKid(new LaserboltPositioner()); 

    // edwin.addKid(new AlbumEditor(false)); 
}

void draw() {
    edwin.think();
    image(edwin.canvas, 0, 0);
}
