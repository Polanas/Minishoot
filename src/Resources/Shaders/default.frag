#version 450 core

#define PI 3.14159265359

layout (location = 0) out vec4 outColor;

in vec2 v_TexCoord;
in float v_TexIndex;

uniform sampler2D u_Textures[32];
uniform float time;

float screenWidth;

vec2 hash( vec2 p ) // replace this by something better
{
	p = vec2( dot(p,vec2(127.1,311.7)), dot(p,vec2(269.5,183.3)) );
	return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}

float noise( in vec2 p )
{
    const float K1 = 0.366025404; // (sqrt(3)-1)/2;
    const float K2 = 0.211324865; // (3-sqrt(3))/6;

	vec2  i = floor( p + (p.x+p.y)*K1 );
    vec2  a = p - i + (i.x+i.y)*K2;
    float m = step(a.y,a.x); 
    vec2  o = vec2(m,1.0-m);
    vec2  b = a - o + K2;
	vec2  c = a - 1.0 + 2.0*K2;
    vec3  h = max( 0.5-vec3(dot(a,a), dot(b,b), dot(c,c) ), 0.0 );
	vec3  n = h*h*h*h*vec3( dot(a,hash(i+0.0)), dot(b,hash(i+o)), dot(c,hash(i+1.0)));
    return dot( n, vec3(70.0) );
}

float simplex(in vec2 uv)
{
    float f = 0.0;
    uv *= 5.0;
    
    mat2 m = mat2( 1.6,  1.2, -1.2,  1.6 );
    f  = 0.5000*noise( uv ); uv = m*uv;
    f += 0.2500*noise( uv ); uv = m*uv;
    f += 0.1250*noise( uv ); uv = m*uv;
    f += 0.0625*noise( uv ); uv = m*uv;
	f = 0.5 + 0.5*f;
    
    return f;
}

vec3 palette(in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d)
{
    return a + b*cos( 6.28318*(c*t+d) );
}

vec3 rainbow(in vec2 p, in float t)
{
    return cos(t + p.xyx + vec3(0, 2, 4))*.5+.5;
}

void main()
{
    int index = int(v_TexIndex);

    vec4 texCol = texture(u_Textures[index], v_TexCoord);
    vec2 size = textureSize(u_Textures[index], 0);
    vec2 fragCoord = v_TexCoord * size;
    vec2 uv = (floor((fragCoord - size * .5) / 1.) * 1.) / size.y;

    vec4 col = texCol;

	screenWidth = size.x; 

    float noise = simplex(uv + vec2(time*.25,0));
//    float mnoise = noise / 1.7;
//    float palleteLength = 1000;
//    float currentSize = 80;
//    float coefficient = 
//    (time * .1) 
//    + ((palleteLength - currentSize) / palleteLength)
//    + (mnoise * (currentSize/palleteLength));
    vec3 col1 = vec3(1,0,0);
    vec3 col2 = vec3(1, .5, 0);
    vec3 noiseCol = mix(col1, col2, vec3(noise * 2.));

//    vec3 noiseCol = palette(
//      coefficient,
//      vec3(.5, .5, .5),
//      vec3(1., 1., 1.),
//      vec3(1., 1., 1.),
//      vec3(0, 0.333, 0.667));
	//col.rgb = vec3(noise);
    //noiseCol = vec3(mnoise);
    
    if (index == 0 && col.rgb.x == 0)
    {
        col.rgb = mix(vec3(0), noiseCol, .3);
    }
    else if (index == 1 && col.x == 1)
    {
         col.rgb = noiseCol;
    }

    outColor = col;
}