////////////////////////////////////////////////////////
// VintageFilmGrain
// Original shader: warm faded-print color response, soft
// vignette, animated grain and a subtle diagonal light leak
// to evoke an old projected film reel.
////////////////////////////////////////////////////////

uniform float FadeAmount <
	ui_type = "slider";
	ui_label = "Fade / Lifted Blacks";
	ui_min = 0.0; ui_max = 0.5;
> = 0.09;

uniform float WarmthAmount <
	ui_type = "slider";
	ui_label = "Warmth";
	ui_min = 0.0; ui_max = 1.0;
> = 0.28;

uniform float VignetteStrength <
	ui_type = "slider";
	ui_label = "Vignette Strength";
	ui_min = 0.0; ui_max = 1.5;
> = 0.45;

uniform float GrainAmount <
	ui_type = "slider";
	ui_label = "Grain Amount";
	ui_min = 0.0; ui_max = 0.3;
> = 0.045;

uniform float LightLeakStrength <
	ui_type = "slider";
	ui_label = "Light Leak Strength";
	ui_min = 0.0; ui_max = 1.0;
> = 0.15;

uniform float FrameTime < source = "frametime"; >;

#include "ReShade.fxh"

float Hash12(float2 p)
{
	float3 p3 = frac(float3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return frac((p3.x + p3.y) * p3.z);
}

float3 VintageFilmGrainPS(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;

	// Lift blacks and gently roll off highlights for a faded print look.
	color = color * (1.0 - FadeAmount) + FadeAmount * 0.5;

	// Push warm tones into shadows, cool tones stay in highlights.
	float3 warm = float3(1.08, 1.0, 0.85);
	float3 cool = float3(0.95, 1.0, 1.05);
	float luma = dot(color, float3(0.299, 0.587, 0.114));
	float3 tinted = color * lerp(warm, cool, luma);
	color = lerp(color, tinted, WarmthAmount);

	// Radial vignette darkening toward the frame edges.
	float2 centered = texcoord - 0.5;
	float vig = 1.0 - dot(centered, centered) * VignetteStrength;
	color *= saturate(vig);

	// Diagonal light leak drifting slowly over time.
	static const float2 leakDir = float2(0.7, 0.7);
	float leakPhase = frac(FrameTime * 0.00005);
	float leak = saturate(dot(texcoord - leakPhase, leakDir) * 0.5 + 0.5);
	leak = pow(leak, 6.0);
	color += float3(1.0, 0.55, 0.2) * leak * LightLeakStrength * 0.4;

	// Animated fine grain.
	float t = frac(FrameTime * 0.001);
	float grain = (Hash12(texcoord * BUFFER_WIDTH + t * 97.0) - 0.5) * GrainAmount;
	color = saturate(color + grain);

	return color;
}

technique VintageFilmGrain
{
	pass Main
	{
		VertexShader = PostProcessVS;
		PixelShader = VintageFilmGrainPS;
	}
}
