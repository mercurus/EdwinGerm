#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif
#define PROCESSING_TEXTURE_SHADER

//stuff passed automatically by Processing
uniform mat4 transform;
uniform mat4 texMatrix;
// uniform mat4 modelview;
// uniform mat3 normalMatrix;
// uniform vec4 lightPosition;
// attribute vec3 normal;
attribute vec4 position;
attribute vec4 color;
attribute vec2 texCoord;

// uniform int[] cgolData0;
// uniform int[] cgolDataaa1;
// uniform int[] cgolDataaa2;
// uniform int[] cgolDataaa3;
// uniform int[] cgolDataaa4;

//stuff being passed to the fragment shader
varying vec4 vertPos;
varying vec4 vertColor;
varying vec4 vertTexCoord;
varying vec2 _texCoord;
varying mat4 _texMatrix;

void main() {
    gl_Position = transform * position;
    vertPos = position;
    vertColor = color;
    vertTexCoord = texMatrix * vec4(texCoord, 1.0, 1.0);
    // vertTexCoord = vec4(texCoord, 1.0, 1.0);
    _texCoord = texCoord;
    _texMatrix = texMatrix;
}
