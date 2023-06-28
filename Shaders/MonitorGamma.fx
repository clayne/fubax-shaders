/** Monitor Gamma Correction PS, version 1.1.0

This code © 2023 Jakub Maksymilian Fober

This work is licensed under the Creative Commons,
Attribution-ShareAlike 3.0 Unported License.
To view a copy of this license, visit
http://creativecommons.org/licenses/by-sa/3.0/.

*/

	/* MACROS */

#ifndef GAMMA_TEX_FILE
	#define GAMMA_TEX_FILE "GammaTex.png"
#endif
#ifndef GAMMA_TEX_SIZE
	#define GAMMA_TEX_SIZE 256
#endif

	/* COMMONS */

#include "ReShade.fxh"
#include "ReShadeUI.fxh"
#include "ColorAndDither.fxh"

	/* MENU */

uniform float Gamma < __UNIFORM_DRAG_FLOAT1
	ui_text = "Make logo disappear:";
	ui_label = "Monitor gamma";
	ui_tooltip =
		"Adjust until logo disappears.\n"
		"You may need to squint your eyes.";
	ui_min = 1f; ui_max = 3f;
> = 1f;

uniform float GammaRedShift < __UNIFORM_DRAG_FLOAT1
	ui_category = "color shift";
	ui_text = "If the logo has some color tint:";
	ui_label = "Red gamma";
	ui_tooltip =
		"Adjust until logo disappears.\n"
		"You may need to squint your eyes.";
	ui_min = 0.5; ui_max = 1.5;
> = 1f;

uniform float GammaGreenShift < __UNIFORM_DRAG_FLOAT1
	ui_category = "color shift";
	ui_label = "Green gamma";
	ui_tooltip =
		"Adjust until logo disappears.\n"
		"You may need to squint your eyes.";
	ui_min = 0.5; ui_max = 1.5;
> = 1f;

uniform float GammaBlueShift < __UNIFORM_DRAG_FLOAT1
	ui_category = "color shift";
	ui_label = "Blue gamma";
	ui_tooltip =
		"Adjust until logo disappears.\n"
		"You may need to squint your eyes.";
	ui_min = 0.5; ui_max = 1.5;
> = 1f;

uniform bool Debug < __UNIFORM_INPUT_BOOL1
	ui_text = "Debug options:";
	ui_label = "Show logo permanently";
> = false;

uniform uint hovered_variable < source = "overlay_hovered"; >;
uniform uint active_variable  < source = "overlay_active"; >;

	/* TEXTURES */

texture GammaTex
<
	source = GAMMA_TEX_FILE;
	pooled = true;
>{
	Width = GAMMA_TEX_SIZE;
	Height = GAMMA_TEX_SIZE;
	Format = R8;
};
// Sampler for blue noise texture
sampler GammaTexSmp
{ Texture = GammaTex; };

	/* SHADERS */

// Vertex shader generating a triangle covering the entire screen
void MonitorGamma_VS(
	in  uint   vertexId  : SV_VertexID,
	out float4 vertexPos : SV_Position)
{
	// Define vertex position
	const float2 vertexPosList[3] =
	{
		float2(-1f, 1f), // Top left
		float2(-1f,-3f), // Bottom left
		float2( 3f, 1f)  // Top right
	};
	// Export  vertex position,
	vertexPos.xy = vertexPosList[vertexId];
	vertexPos.zw = float2(0f, 1f); // Export vertex position
}

// Horizontal luminosity blur pass
void MonitorGamma_PS(
	in  float4 pixCoord : SV_Position,
	out float3    color : SV_Target)
{
	// Get current pixel coordinates
	uint2 texelPos = uint2(pixCoord.xy);

	if (bool(hovered_variable) || bool(active_variable) || Debug) // display calibration image
	{
		uint2 screenCenterOffset = uint2(BUFFER_SCREEN_SIZE-GAMMA_TEX_SIZE)/2u;
		color = lerp(texelPos.y % 2u, 0.5, tex2Dfetch(GammaTexSmp, texelPos-screenCenterOffset).r);
	}
	else // gamma correct back buffer
	{
		// Get current pixel color value
		color = tex2Dfetch(ReShade::BackBuffer, texelPos).rgb;

		// Convert to linear gamma
		color = to_linear_gamma(color);
	}

	// Apply correction gamma
	color = pow(abs(color), rcp(Gamma));

	if (GammaRedShift == 1f || GammaGreenShift == 1f || GammaBlueShift == 1f) // apply gamma color tint
		color = pow(abs(color), rcp(float3(GammaRedShift, GammaGreenShift, GammaBlueShift)));

	// Apply color dither
	color = BlueNoise::dither(texelPos, color);
}

	/* OUTPUT */

technique MonitorGamma
<
	ui_label = "Monitor Gamma";
	ui_tooltip =
		"Calibrate your monitor gamma.\n"
		"\n"
		"This effect © 2023 Jakub Maksymilian Fober\n"
		"Licensed under CC BY-SA 3.0";
>
{
	pass
	{
		VertexShader = MonitorGamma_VS;
		PixelShader  = MonitorGamma_PS;
	}
}
