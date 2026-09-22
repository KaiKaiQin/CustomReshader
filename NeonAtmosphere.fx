////////////////////////////////////////////////////////
// NeonAtmosphere
// Original shader: synthwave-inspired color grading with
// a magenta/cyan duotone push, soft neon glow bloom and a
// horizon-style gradient scanline overlay.
////////////////////////////////////////////////////////

uniform float3 ShadowTint <
	ui_type = "color";
	ui_label = "Shadow Tint";
	ui_tooltip = "Color applied to darker areas of the image.";
> = float3(0.10, 0.02, 0.25);

uniform float3 HighlightTint <
	ui_type = "color";
	ui_label = "Highlight Tint";
	ui_tooltip = "Color applied to brighter areas of the image.";
> = float3(0.15, 0.85, 1.0);

uniform float TintStrength <
	ui_type = "slider";
	ui_label = "Tint Strength";
	ui_min = 0.0; ui_max = 1.0;
> = 0.3;

uniform float GlowThreshold <
	ui_type = "slider";
	ui_label = "Glow Threshold";
	ui_min = 0.0; ui_max = 1.0;
> = 0.68;

uniform float GlowIntensity <
	ui_type = "slider";
	ui_label = "Glow Intensity";
	ui_min = 0.0; ui_max = 3.0;
> = 0.85;

uniform float ScanlineStrength <
	ui_type = "slider";
	ui_label = "Horizon Scanlines";
	ui_min = 0.0; ui_max = 1.0;
> = 0.08;

#include "ReShade.fxh"

texture NeonGlowTex { Width = BUFFER_WIDTH / 2; Height = BUFFER_HEIGHT / 2; Format = RGBA8; };
sampler NeonGlowSampler { Texture = NeonGlowTex; };

float3 NeonGlowExtractPS(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
	float luma = dot(color, float3(0.299, 0.587, 0.114));
	float mask = saturate((luma - GlowThreshold) / max(1.0 - GlowThreshold, 0.001));
	return color * mask;
}

float3 NeonAtmospherePS(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;

	// Duotone grade based on per-pixel luminance.
	float luma = dot(color, float3(0.299, 0.587, 0.114));
	float3 graded = lerp(ShadowTint, HighlightTint, luma);
	color = lerp(color, color * graded * 1.6, TintStrength);

	// Cheap wide blur of the bright-pass buffer for a soft neon glow.
	float2 px = ReShade::PixelSize * 3.0;
	float3 glow = 0.0;
	glow += tex2D(NeonGlowSampler, texcoord).rgb * 4.0;
	glow += tex2D(NeonGlowSampler, texcoord + float2(px.x, 0)).rgb;
	glow += tex2D(NeonGlowSampler, texcoord - float2(px.x, 0)).rgb;
	glow += tex2D(NeonGlowSampler, texcoord + float2(0, px.y)).rgb;
	glow += tex2D(NeonGlowSampler, texcoord - float2(0, px.y)).rgb;
	glow /= 8.0;

	color += glow * GlowIntensity;

	// Faint horizontal scanlines to evoke a retro synth horizon.
	float scan = sin(texcoord.y * BUFFER_HEIGHT * 3.14159) * 0.5 + 0.5;
	color *= lerp(1.0, scan, ScanlineStrength * 0.3);

	return saturate(color);
}

technique NeonAtmosphere
{
	pass GlowExtract
	{
		VertexShader = PostProcessVS;
		PixelShader = NeonGlowExtractPS;
		RenderTarget = NeonGlowTex;
	}
	pass Grade
	{
		VertexShader = PostProcessVS;
		PixelShader = NeonAtmospherePS;
	}
}
