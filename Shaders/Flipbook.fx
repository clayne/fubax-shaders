/*
Flipbook Animation PS (c) 2018 Jacob Maximilian Fober

This work is licensed under the Creative Commons 
Attribution-ShareAlike 4.0 International License. 
To view a copy of this license, visit 
http://creativecommons.org/licenses/by-sa/4.0/.
*/

  ////////////////////
 /////// MENU ///////
////////////////////

#ifndef flipbook
	#define flipbook "waow.png" // Texture file name
#endif
#ifndef flipbookX
	#define flipbookX 2570 // Texture horizontal resolution
#endif
#ifndef flipbookY
	#define flipbookY 1728 // Texture vertical resolution
#endif

uniform int3 Size <
	ui_label = "X frames, Y frames, FPS";
	ui_tooltip = "Adjust flipbook texture dimensions and framerate\nTo change texture resolution and name,\nadd following preprocessor definition:\n  flipbook 'name.png'\n  flipbookX [ResolutionX]\n  flipbookY [ResolutionY]";
	ui_type = "drag";
	ui_min = 1; ui_max = 30; ui_step = 0.2;
> = int3(10, 9, 30);

uniform float3 Position <
	ui_label = "X position, Y position, Scale";
	ui_tooltip = "Adjust flipbook texture size and position";
	ui_type = "drag";
	ui_min = float3(0.0, 0.0, 0.1); ui_max = float3(1.0, 1.0, 1.0); ui_step = 0.002;
> = float3(1.0, 1.0, 1.0);

// Get time in milliseconds from start
uniform float timer < source = "timer"; >;


  //////////////////////
 /////// SHADER ///////
//////////////////////

texture FlipbookTex < source = flipbook; > {Width = flipbookX; Height = flipbookY;};
sampler FlipbookSampler { Texture = FlipbookTex; };

#include "ReShade.fxh"

float Mask(float2 Coord)
{
	Coord = abs(Coord*2-1);
	float2 Pixel = fwidth(Coord);
	float2 Borders = 1.0 - smoothstep(1.0-Pixel, 1.0+Pixel, Coord);
	return min(Borders.x, Borders.y);
}

float3 FlipbookPS(float4 vois : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float ScreenAspect = ReShade::AspectRatio;
	// Screen aspect divided by animation frame aspect
	float AspectDifference = (ScreenAspect*float(Size.x*flipbookY))/float(Size.y*flipbookX);

	// Scale coordinates
	float2 Scale = 1.0/Position.z;
	float2 ScaledCoord = texcoord * Scale;

	// Adjust aspect ratio
	if(AspectDifference > 1.0)
	{
		ScaledCoord.x *= AspectDifference;
		Scale.x *= AspectDifference;
	}
	else if(AspectDifference < 1.0)
	{
		ScaledCoord.y /= AspectDifference;
		Scale.y /= AspectDifference;
	}

	// Offset coordinates
	ScaledCoord += (1.0-Scale)*Position.xy;

	float BorderMask = Mask(ScaledCoord);
	// Frame time in milliseconds
	float FramerateInMs = 1000.0 / Size.z;
	float2 AnimationCoord = ScaledCoord / Size.xy;
	// Sample UVs for horizontal and vertical frames
	AnimationCoord.x += frac(floor(timer / FramerateInMs) / Size.x);
	AnimationCoord.y += frac(floor( timer / (FramerateInMs * Size.x) )/Size.y);

	// Sample display image
	float3 Display = tex2D(ReShade::BackBuffer, texcoord).rgb;
	// Sample flipbook texture
	float4 AnimationTexture = tex2D(FlipbookSampler, AnimationCoord);

	return lerp(Display, AnimationTexture.rgb, AnimationTexture.a * BorderMask);
}


technique Flipbook
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = FlipbookPS;
	}
}
