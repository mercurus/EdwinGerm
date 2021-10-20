#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif
#define PROCESSING_TEXTURE_SHADER
#define PI 3.14159265358979323846
#define TWO_PI 6.28318530717958647692

//stuff passed from vertex shader
varying vec4 vertPos;
varying vec4 vertColor;
varying vec4 vertTexCoord;
varying vec2 _texCoord;
varying mat4 _texMatrix;
// varying vec4 color;
// uniform vec4 viewport;
uniform sampler2D texture; //PGraphics being drawn 

uniform vec2 gameSize;

void main() {
    // vec2 v_uv = vec2(vertPos.x / gameSize.x, vertPos.y / gameSize.y);
    // vec4 currentPixel = texture2D(texture, v_uv);


    vec4 currentPixel = texture(texture, vertTexCoord.xy);
    vec2 pixelSize = vec2(1.0 / gameSize.x, 1.0 / gameSize.y);
    vec4 neighborPixels = vec4(0, 0, 0, 0);

    float leftX = vertTexCoord.x - pixelSize.x;
    float rightX = vertTexCoord.x + pixelSize.x;


    // if (_texCoord.x < 0.5) {
    // if (leftX < pixelSize.x) {
    if (leftX < 0) {
        // if (vertPos.x <= 1) {
        // if (vertTexCoord.x < pixelSize.x) {
        // if (vertTexCoord.x == 0) {
        // rightX = pixelSize.x * 0.8;
        // vec4 newPos = _texMatrix * vec4(1 - pixelSize.x, vertTexCoord.y, 1.0, 1.0);
        // leftX = fract(leftX)
        // leftX = newPos.x;
        // leftX = 1 - pixelSize.x;
        // leftX = 1 - pixelSize.x * 0.5;
        // leftX = 1;
        // gl_FragColor = vec4(1, 0, 1, 1);  //magenta
        // return;
    }
    // if (rightX > 1.0 - pixelSize.x) {
    if (rightX > 1) {
        // if (vertPos.x >= gameSize.x - 1) {
        // if (vertTexCoord.x >= 1 - pixelSize.x) {
        // if (vertTexCoord.x > 1 - pixelSize.x) {
        // if (vertTexCoord.x >= 1) {
        // if (_texCoord.x > 1 - pixelSize.x) {
        // leftX = 1 - pixelSize.x * 0.5;
        // vec4 newPos = _texMatrix * vec4(pixelSize.x, vertTexCoord.y, 1.0, 1.0);
        // rightX = newPos.x;
        // rightX = pixelSize.x;
        // rightX = pixelSize.x * 0.5;
        // rightX = 0;
        // gl_FragColor = vec4(1, 1, 0, 1);  //yellow
        // return;
    }

    //thanks to World of Zero https://www.youtube.com/watch?v=ItPTBSeGjdM
    // neutral y
    neighborPixels += texture(texture, vec2(leftX, vertTexCoord.y));
    neighborPixels += texture(texture, vec2(rightX, vertTexCoord.y));
    // +y
    if (vertPos.y > 1) {
        neighborPixels += texture(texture, vec2(rightX, vertTexCoord.y + pixelSize.y));
        neighborPixels += texture(texture, vec2(vertTexCoord.x, vertTexCoord.y + pixelSize.y));
        neighborPixels += texture(texture, vec2(leftX, vertTexCoord.y + pixelSize.y));
    }
    // -y
    if (vertPos.y < gameSize.y - 1) {
        neighborPixels += texture(texture, vec2(rightX, vertTexCoord.y - pixelSize.y));
        neighborPixels += texture(texture, vec2(vertTexCoord.x, vertTexCoord.y - pixelSize.y));
        neighborPixels += texture(texture, vec2(leftX, vertTexCoord.y - pixelSize.y));
    }


    // +y
    // if (vertPos.y < gameSize.y - 1) {
    // if (vertPos.y > 1) {
    //   neighborPixels += texture(texture, vec2(rightX, vertTexCoord.y + pixelSize.y));
    //   neighborPixels += texture(texture, vec2(vertTexCoord.x, vertTexCoord.y + pixelSize.y));
    //   neighborPixels += texture(texture, vec2(leftX, vertTexCoord.y + pixelSize.y));
    // }
    // else {
    //   // gl_FragColor = vec4(1, 0, 1, 1);  //magenta
    //   // return;
    // }
    // // neutral y
    // neighborPixels += texture(texture, vec2(leftX, vertTexCoord.y));
    // neighborPixels += texture(texture, vec2(rightX, vertTexCoord.y));
    // // -y
    // // if (vertPos.y > 1) {
    // if (vertPos.y < gameSize.y - 1) {
    //   neighborPixels += texture(texture, vec2(rightX, vertTexCoord.y - pixelSize.y));
    //   neighborPixels += texture(texture, vec2(vertTexCoord.x, vertTexCoord.y - pixelSize.y));
    //   neighborPixels += texture(texture, vec2(leftX, vertTexCoord.y - pixelSize.y));
    // }
    // else {
    //   // gl_FragColor = vec4(1, 1, 0, 1);  //yellow
    //   // return;
    // }

    //determine fate of cgol cell
    if (currentPixel.r > 0.5) { //if is alive
        if (neighborPixels.r > 1.5 && neighborPixels.r < 3.5) { //between 2 and 3
            gl_FragColor = vec4(1, 1, 1, 1);
        }
        else {
            gl_FragColor = vec4(0, 0, 0, 1);
        }
    }
    else { //he's dead jim
        if (neighborPixels.r > 2.5 && neighborPixels.r < 3.5) { // == 3
            gl_FragColor = vec4(1, 1, 1, 1);
        }
        else {
            gl_FragColor = vec4(0, 0, 0, 1);
        }
    }

}
