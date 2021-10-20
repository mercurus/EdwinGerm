/** 
* Random stars that fill the screen
* While running hit S to generate new stars
*/
class StarBackdrop implements Kid {
	PGraphics backdrop;
	int[] palette = new int[] { #D1CAA1, #66717E, #383B53, #32213A, #110514 }; 
	int starCount;
	//XY[] stars;
	//BoundedInt timer, fadingStar;

	StarBackdrop() { this(250); }
	StarBackdrop(int numStars) {
		backdrop = createGraphics(width, height);
		newStarCount(numStars);
		//random star blinking (only works when we draw every frame rather than drawing to a PGraphics)
		// timer = new BoundedInt(50);
		// fadingStar = new BoundedInt(stars.length - 1);
		// fadingStar.loops = true;
	}

	void newStarCount(int numStars) {
		starCount = numStars;
		XY[] stars = new XY[starCount];
		for (int i = 0; i < stars.length; i++) {
			stars[i] = new XY(random(width), random(height));
		}
		//draw each star
		float tip = 6;
		float mid = tip / 3;
		//backdrop.noSmooth();
		backdrop.beginDraw();
		backdrop.clear();
		for (int i = 0; i < stars.length; i++) {
			backdrop.stroke(palette[i % palette.length]);
			if (i % 3 == 0) { //cross
				backdrop.line(stars[i].x - mid, stars[i].y, stars[i].x + mid, stars[i].y);
				backdrop.line(stars[i].x, stars[i].y - mid, stars[i].x, stars[i].y + mid);
			}
			else if (i % 8 == 0) { //diamond
				backdrop.fill(palette[i % palette.length]);
				backdrop.noStroke();
				backdrop.beginShape();
				backdrop.vertex(stars[i].x, stars[i].y - tip); 
				backdrop.vertex(stars[i].x + mid, stars[i].y - mid);
				backdrop.vertex(stars[i].x + tip, stars[i].y);
				backdrop.vertex(stars[i].x + mid, stars[i].y + mid);
				backdrop.vertex(stars[i].x, stars[i].y + tip);
				backdrop.vertex(stars[i].x - mid, stars[i].y + mid);
				backdrop.vertex(stars[i].x - tip, stars[i].y);
				backdrop.vertex(stars[i].x - mid, stars[i].y - mid);
				backdrop.endShape(CLOSE);
			}
			else { //single dot
				backdrop.point(stars[i].x, stars[i].y);
			}
		}
		backdrop.endDraw();
	}

	void draw(PGraphics canvas) {
		canvas.image(backdrop, 0, 0);

		/*
		//random star blinking (only works when we draw every frame rather than drawing to a PGraphics)
		timer.increment();
		if (timer.atMax()) {
			timer.randomize();
			stars[fadingStar.increment()].set(random(width), random(height));
		}

		//draw each star
		float tip = 6;
		float mid = tip / 3;
		for (int i = 0; i < stars.length; i++) {
			stroke(palette[i % palette.length]);
			if (i % 3 == 0) { //cross
				line(stars[i].x - mid, stars[i].y, stars[i].x + mid, stars[i].y);
				line(stars[i].x, stars[i].y - mid, stars[i].x, stars[i].y + mid);
			}
			else if (i % 8 == 0) { //diamond
				fill(palette[i % palette.length]);
				noStroke();
				beginShape();
				vertex(stars[i].x, stars[i].y - tip); 
				vertex(stars[i].x + mid, stars[i].y - mid);
				vertex(stars[i].x + tip, stars[i].y);
				vertex(stars[i].x + mid, stars[i].y + mid);
				vertex(stars[i].x, stars[i].y + tip);
				vertex(stars[i].x - mid, stars[i].y + mid);
				vertex(stars[i].x - tip, stars[i].y);
				vertex(stars[i].x - mid, stars[i].y - mid);
				endShape(CLOSE);
			}
			else { //single dot
				point(stars[i].x, stars[i].y);
			}
		}
		*/
	}

	String keyboard(KeyEvent event) {
		if (event.getAction() == KeyEvent.RELEASE && event.getKeyCode() == Keycodes.S) { 
			newStarCount(starCount); //redraw
			return HELLO;
		}
		return "";
	}

	String mouse() {
		return "";
	}
}



/** 
* Random stars that fill the screen
* While running hit S to generate new stars
*/
class PixelStarBackdrop implements Kid {
	PGraphics backdrop;
	Album albumStars;
	int starCount;

	PixelStarBackdrop() { this(250); }
	PixelStarBackdrop(int numStars) { this(numStars, 1.0); }
	PixelStarBackdrop(int numStars, float albumScale) {
		backdrop = createGraphics(width, height);
		albumStars = new Album("tiles\\stars.alb", albumScale);
		newStarCount(numStars);
	}

	void newStarCount(int numStars) {
		starCount = numStars;
		backdrop.beginDraw();
		backdrop.clear();
		float x, y;
		for (int i = 0; i < numStars; i++) {
			//make position inline with other star's pixels for when the scale isn't 1.0
			x = random(width) / albumStars.scale * albumStars.scale;
			y = random(height) / albumStars.scale * albumStars.scale;
			backdrop.image(albumStars.randomPage(), (int)x, (int)y);
			//backdrop.image(albumStars.randomPage(), random(width), random(height));
		}
		backdrop.endDraw();
	}

	void draw(PGraphics canvas) {
		//newStarCount(starCount);
		canvas.image(backdrop, 0, 0);
	}

	String keyboard(KeyEvent event) {
		if (event.getAction() == KeyEvent.RELEASE && event.getKeyCode() == Keycodes.S) { 
			newStarCount(starCount); //redraw
			return HELLO;
		}
		return "";
	}

	String mouse() {
		return "";
	}
}
