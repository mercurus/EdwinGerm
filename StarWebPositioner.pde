/**
* Adjustable starwebs
*/
public class StarWebPositioner implements Kid {
	ArrayList<StarWeb> starWebs;
	StarWeb selectedWeb;
	GadgetPanel gPanel;
	PalettePicker palette;

	StarWebPositioner() { this(true); }
	StarWebPositioner(boolean gadgetPanelVisible) {
		starWebs = new ArrayList<StarWeb>();
		int[] plt = EdColors.dxPalette();
		palette = new PalettePicker(plt, "StarWeb Colors", false);
		selectedWeb = new StarWeb(palette);
		starWebs.add(selectedWeb);

		gPanel = new GadgetPanel(200, 200, "(S) StarWebs!");
		gPanel.isVisible = gadgetPanelVisible;
		String[] minusPlus = new String[] { GadgetPanel.MINUS, GadgetPanel.PLUS };
		
		gPanel.addItem("open|save", new String[] { GadgetPanel.OPEN, GadgetPanel.SAVE }, new Command() {
			void execute(String arg) {
				if (arg == GadgetPanel.OPEN) {
					//selectInput("Open Lasers...", "openFile", null, LaserboltPositioner.this);
				}
				else { // GadgetPanel.SAVE
					//selectOutput("Save Lasers...", "saveFile", null, LaserboltPositioner.this);
				}
			}
		});

		gPanel.addItem("colors", new String[] { GadgetPanel.COLOR_WHEEL, GadgetPanel.ARROW_N, GadgetPanel.ARROW_E }, new Command() {
			void execute(String arg) {
				if (arg == GadgetPanel.COLOR_WHEEL) {
					palette.toggleVisibility();
					palette.body.set(mouseX, mouseY);
				}
				else if (arg == GadgetPanel.ARROW_N) {
					selectedWeb.vPaletteColor = palette.selectedColor.value; //index
				}
				else { // if (arg == GadgetPanel.ARROW_E) {
					selectedWeb.hPaletteColor = palette.selectedColor.value;
				}
			}
		});

		gPanel.addItem("selected", new String[] { GadgetPanel.ARROW_W, GadgetPanel.ARROW_E }, new Command() {
			void execute(String arg) {
				int selIndex = starWebs.indexOf(selectedWeb);
				if (arg == GadgetPanel.ARROW_W) {
					if (selIndex > 0) {
						selIndex--;
						selectedWeb = starWebs.get(selIndex);
					}
				}
				else { //GadgetPanel.ARROW_E
					if (selIndex < starWebs.size() - 1) {
						selIndex++;
						selectedWeb = starWebs.get(selIndex);
					}
				}
				gPanel.windowTitle = "selected index:" + selIndex;
				// gPanel.getButtons(PERFECT_ZZ).setCheck(selectedLaser.perfectZigZag); //set checkboxes of newly selected laser
				// gPanel.getButtons(JOLTS).setCheck(selectedLaser.jolts); //it's a little awkward right now
				// gPanel.getButtons(IS_VISIBLE).setCheck(selectedLaser.isVisible); 
			}
		});

		gPanel.addItem("New web", GadgetPanel.OK, new Command() {
			void execute(String arg) {
				StarWeb newWeb = new StarWeb(palette);
				starWebs.add(newWeb);
				selectedWeb = newWeb;
				gPanel.windowTitle = "Web Created:" + starWebs.indexOf(selectedWeb);
			}
		});

		gPanel.addItem("HORIZONTAL Lines", minusPlus, new Command() {
			void execute(String arg) {
				if (arg == GadgetPanel.MINUS) selectedWeb.hLineCount.decrement();
				else selectedWeb.hLineCount.increment();
				gPanel.windowTitle = "H Line Count:" + selectedWeb.hLineCount.value;
			}
		});

		gPanel.addItem("Thickness", minusPlus, new Command() {
			void execute(String arg) {
				if (arg == GadgetPanel.MINUS) selectedWeb.hStrokeWeight.decrement();
				else selectedWeb.hStrokeWeight.increment();
				gPanel.windowTitle = "H Thickness:" + selectedWeb.hStrokeWeight.value;
			}
		});

		gPanel.addItem("Padding", minusPlus, new Command() {
			void execute(String arg) {
				if (arg == GadgetPanel.MINUS) selectedWeb.hPadding.decrement();
				else selectedWeb.hPadding.increment();
				gPanel.windowTitle = "H Padding:" + selectedWeb.hPadding.value;
			}
		});

		gPanel.addItem("Pad Step", minusPlus, new Command() {
			void execute(String arg) {
				if (arg == GadgetPanel.MINUS) selectedWeb.hPadPartial.decrement();
				else selectedWeb.hPadPartial.increment();
				gPanel.windowTitle = "H Pad Step:" + selectedWeb.hPadPartial.value;
			}
		});

		gPanel.addItem("Center|BgdColor", new String[] { GadgetPanel.START_LIGHT, GadgetPanel.COLOR_WHEEL }, new Command() {
			void execute(String arg) {
				if (arg == GadgetPanel.START_LIGHT) selectedWeb.center.set(width / 2, height / 2);
				else edwin.bgdColor = palette.selectedColor();
			}
		});

		gPanel.addItem("VERTICAL Lines", minusPlus, new Command() {
			void execute(String arg) {
				if (arg == GadgetPanel.MINUS) selectedWeb.vLineCount.decrement();
				else selectedWeb.vLineCount.increment();
				gPanel.windowTitle = "v Line Count:" + selectedWeb.vLineCount.value;
			}
		});

		gPanel.addItem("Thickness", minusPlus, new Command() {
			void execute(String arg) {
				if (arg == GadgetPanel.MINUS) selectedWeb.vStrokeWeight.decrement();
				else selectedWeb.vStrokeWeight.increment();
				gPanel.windowTitle = "V Thickness:" + selectedWeb.vStrokeWeight.value;
			}
		});

		gPanel.addItem("Padding", minusPlus, new Command() {
			void execute(String arg) {
				if (arg == GadgetPanel.MINUS) selectedWeb.vPadding.decrement();
				else selectedWeb.vPadding.increment();
				gPanel.windowTitle = "V Padding:" + selectedWeb.vPadding.value;
			}
		});

		gPanel.addItem("Pad Step", minusPlus, new Command() {
			void execute(String arg) {
				if (arg == GadgetPanel.MINUS) selectedWeb.vPadPartial.decrement();
				else selectedWeb.vPadPartial.increment();
				gPanel.windowTitle = "V Pad Step:" + selectedWeb.vPadPartial.value;
			}
		});


	}

	void draw(PGraphics canvas) {
		for (StarWeb web : starWebs) {
			canvas.image(web.web, 0, 0);
		}
		if (!gPanel.isVisible) return;
		selectedWeb.draw(canvas);
		gPanel.draw(canvas);
		palette.draw(canvas);
	}

	String mouse() {
		if (gPanel.mouse() != "" || palette.mouse() != "") return HELLO;
		if ((gPanel.body.isMouseOver() && gPanel.isVisible) || 
			(palette.body.isMouseOver() && palette.isVisible)) return HELLO;
		if (edwin.mouseBtnHeld == LEFT) {
			float padding = abs(selectedWeb.center.y - mouseY) / 5.0;
			selectedWeb.vPadding.set(padding);
			selectedWeb.hPadding.set(padding);
		}
		else if (edwin.mouseBtnHeld == RIGHT) {
			selectedWeb.center.set(mouseX, mouseY);
		}
		return "";
	}

	String keyboard(KeyEvent event) {
		int kc = event.getKeyCode();
		if (event.getAction() == KeyEvent.PRESS) {
			switch (kc) {
				case Keycodes.SPACE: selectedWeb.commit = true; break;
			}
		}
		else if (event.getAction() == KeyEvent.RELEASE) {
			if (kc == Keycodes.SPACE) selectedWeb.commit = false;
			else if (kc == Keycodes.BACK_SPACE) selectedWeb.clear = true;
			else if (kc == Keycodes.S) gPanel.toggleVisibility();
		}
		return "";
	}

}

/**
* A bunch of staggered triangles
*/
class StarWeb implements Kid {
	PGraphics web;
	PalettePicker palette;
	XY center, anchorDist;
	BoundedInt vLineCount, vStrokeWeight; 
	BoundedInt hLineCount, hStrokeWeight;
	BoundedFloat vPadding, vPadPartial;
	BoundedFloat hPadding, hPadPartial;
	int hPaletteColor, vPaletteColor;
	boolean clear, commit;

	StarWeb(PalettePicker picker) {
		palette = picker;
		web = createGraphics(width, height);
		center = new XY(width / 2, height / 2);
		anchorDist = new XY(0, 0);
		//anchorDist = new XY(-50, -50);
		clear = commit = false;
		hLineCount = new BoundedInt(0, 20, 10);
		vLineCount = new BoundedInt(0, 20, 10);
		hStrokeWeight = new BoundedInt(1, 10);
		vStrokeWeight = new BoundedInt(1, 10);
		hPadding = new BoundedFloat(0, 200, 20, 2);
		vPadding = new BoundedFloat(0, 200, 20, 2);
		hPadPartial = new BoundedFloat(0, 3.0, 0.7, 0.05);
		vPadPartial = new BoundedFloat(0, 3.0, 0.7, 0.05);
		hPaletteColor = vPaletteColor = 0;
	}

	void draw(PGraphics canvas) {
		PGraphics drawOn = canvas;
		if (commit) {
			drawOn = web;
		}

		web.beginDraw();
		if (clear) {
			clear = false;
			web.clear();
		}
		
		//horizontal lines
		float pad, padPartial;
		drawOn.stroke(palette.colors.get(hPaletteColor));
		drawOn.strokeWeight(hStrokeWeight.value);
		for (int i = 0; i < hLineCount.value; i++) {
			pad = hPadding.value * i;
			padPartial = pad * hPadPartial.value;
			//lower
			drawOn.line(
				anchorDist.x + padPartial,
				center.y, 
				center.x, 
				center.y + pad
			);
			drawOn.line(
				center.x, 
				center.y + pad,
				width - anchorDist.x - padPartial,
				center.y
			);
			//upper
			drawOn.line(
				anchorDist.x + padPartial, 
				center.y, 
				center.x, 
				center.y - pad
			);
			drawOn.line(
				center.x, 
				center.y - pad,
				width - anchorDist.x - padPartial, 
				center.y
			);
		}

		//vertical lines
		drawOn.stroke(palette.colors.get(vPaletteColor));
		drawOn.strokeWeight(vStrokeWeight.value);
		for (int i = 0; i < vLineCount.value; i++) {
			pad = vPadding.value * i;
			padPartial = pad * vPadPartial.value;
			//left
			drawOn.line(
				center.x, 
				anchorDist.y + padPartial, 
				center.x - pad, 
				center.y
			);
			drawOn.line(
				center.x - pad, 
				center.y,
				center.x, 
				height - anchorDist.y - padPartial
			);
			//right
			drawOn.line(
				center.x, 
				anchorDist.y + padPartial,
				center.x + pad, 
				center.y
			);
			drawOn.line(
				center.x + pad, 
				center.y,
				center.x,
				height - anchorDist.y - padPartial
			);
		}
		web.endDraw();
		//canvas.image(web, 0, 0);
	}

	String mouse() { return ""; }
	String keyboard(KeyEvent event) { return ""; }
}
