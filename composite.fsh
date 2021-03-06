#version 120

#define PI 3.14159
#define FALLOFF_FUN 8
#define NOISE_SAMPLE_SIZE 512

#define OVERWORLD_GROUND_HEIGHT 64


uniform mat4 gbufferProjectionInverse;
uniform vec3 upPosition;
uniform sampler2D texture;
uniform sampler2D depthtex0; //This one contains the clouds
uniform sampler2D depthtex1;
uniform float eyeAltitude;
uniform float far;
uniform float near;
uniform vec3 cameraPosition; 
uniform mat4 gbufferModelViewInverse;
uniform float viewWidth;
uniform float frameTimeCounter;
uniform float rainStrength;
uniform sampler2D colortex7;
uniform sampler2D colortex6;
uniform vec3 skyColor;

varying vec4 viewDir;
varying vec4 texcoord;
varying vec4 color;

void main(){
    vec4 sampledTexture = texture2D(texture, texcoord.st);
    float depth0 = texture2D(depthtex0, texcoord.st).r;
    float powedDepth0 = depth0;

    for(int i = 0; i < 8; i++){
        powedDepth0 = powedDepth0 * powedDepth0;
    }
    //powedDepth0 = clrmp(powedDepth0 + sin(depth0 * 16 + 3) / 8 * depth0, 0, 1);
    //float mixVal = powedDepth0 * 1 / exp(eyeAltitude * 0.01);

    //Compute view direction:
    //gbufferProjectionInverse
    

    
    float time = frameTimeCounter / 4;
    vec3 screenPos = vec3(texcoord.s, texcoord.t , depth0);
    vec3 clipPos = screenPos * 2.0 - 1.0;
    vec4 tmp = gbufferProjectionInverse * vec4(clipPos, 1.0);
    vec4 viewPos = tmp;
    viewPos.xyz /= viewPos.w;
    viewPos.w = 1.0;

    vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos.xyz;
    vec3 feetPlayerPos = eyePlayerPos + gbufferModelViewInverse[3].xyz;
    vec3 worldPos = feetPlayerPos + cameraPosition;

    float rndOffset = pow(texture2D(colortex7, (worldPos.xz + time) / NOISE_SAMPLE_SIZE).r, 0.5);
    rndOffset = rndOffset * 2 - 1;
    float feetRndOffset = pow(texture2D(colortex7, (cameraPosition.xz + time) / NOISE_SAMPLE_SIZE).r, 0.5);
    feetRndOffset = feetRndOffset * 2 - 1;


    float falloff = 0.01;
    float height = worldPos.y;//eyePlayerPos.y + eyeAltitude;
    //exp(-((height - OVERWORLD_GROUND_HEIGHT - rndOffset * 8) * FALLOFF_FUN) * falloff
    float heightFogAmount = clamp(exp(-((height - OVERWORLD_GROUND_HEIGHT - rndOffset * 8) * FALLOFF_FUN) * falloff), 0.0, 1.0); //This determines whether the eyes is inside the fog plane
    float eyeHeightFogAmount = clamp(exp(-((eyeAltitude - OVERWORLD_GROUND_HEIGHT - feetRndOffset * 8) * FALLOFF_FUN) * falloff), 0.0, 0.8);
    
    float fogAmount = clamp(heightFogAmount * powedDepth0, 0, 1);
    
    fogAmount = mix(fogAmount, powedDepth0, eyeHeightFogAmount);

    float fogLerpAmount = clamp(pow(eyeAltitude / 60, 2), 0, 1);
    fogLerpAmount *= fogLerpAmount;
    fogLerpAmount *= fogLerpAmount;
    vec4 fogColor = mix(vec4(0.1, 0.1, 0.2, 1.0), vec4(mix(skyColor, gl_Fog.color.rgb, powedDepth0), 1.0), fogLerpAmount);

    //float causticColor = texture2D(colortex6, (worldPos.xz + rndOffset * 4) / 4).r;



    //vec4 mixFogColor = mix(fogColor * 0.2, fogColor, skyBrightness);
    gl_FragData[0] = vec4(mix(sampledTexture * color, fogColor, fogAmount));
}
