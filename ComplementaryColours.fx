////////////////////////////////////////////////////////
// ComplementaryColours (V4)
// Original shader: simulates a hand-painted watercolor look
// by softening detail, posterizing tones and darkening edges
// like pooled pigment along contours. The hidden-color tint
// follows a continuous Shadow -> Mid -> Light hue trajectory
// using complementary/analogous hue shifts instead of
// hard-switching between three fixed colors.
//
// V4 adds a shared environmental color atmosphere (sampled from
// a wide blur) and small local complementary-hue color accents
// on top of the per-pixel hue/sat/value trajectory.
//
// Local Base Color -> Light/Mid/Shadow Trajectory
//   -> + Environmental Color -> + Small Color Accents -> Final
////////////////////////////////////////////////////////

uniform float SmoothRadius <
	ui_type = "slider";
	ui_label = "Smoothing Radius";
	ui_min = 0.5; ui_max = 4.0;
	ui_tooltip = "How far the paint 'bleeds' between neighboring pixels.";
> = 1.1;

uniform int ToneSteps <
	ui_type = "slider";
	ui_label = "Tone Steps";
	ui_min = 3; ui_max = 12;
	ui_tooltip = "Number of flat color bands, like mixed pigment layers.";
> = 9;

uniform float PosterizeSoftness <
	ui_type = "slider";
	ui_label = "Posterize Softness";
	ui_min = 0.0; ui_max = 0.5;
	ui_tooltip = "Feathers the boundary between tone bands instead of a hard step.";
> = 0.25;

uniform float EdgeDarken <
	ui_type = "slider";
	ui_label = "Edge Pigment Pooling";
	ui_min = 0.0; ui_max = 2.0;
	ui_tooltip = "Darkens contours where pigment would collect.";
> = 0.45;

uniform float PaperGrain <
	ui_type = "slider";
	ui_label = "Paper Grain";
	ui_min = 0.0; ui_max = 0.3;
	ui_tooltip = "Adds subtle paper texture noise.";
> = 0.035;

uniform float HiddenColorStrength <
	ui_type = "slider";
	ui_label = "Hidden Color Strength";
	ui_min = 0.0; ui_max = 2.0;
	ui_tooltip = "Overall strength of the painterly color trajectory.";
> = 1.0;

uniform float HiddenColorScale <
	ui_type = "slider";
	ui_label = "Pigment Blotch Size";
	ui_min = 4.0; ui_max = 64.0;
	ui_tooltip = "Size of the large pigment color regions.";
> = 18.0;

uniform float LightZoneThreshold <
	ui_type = "slider";
	ui_label = "Light Zone Threshold";
	ui_min = 0.4; ui_max = 0.95;
	ui_tooltip = "Luma above this is the Light zone.";
> = 0.66;

uniform float ShadowZoneThreshold <
	ui_type = "slider";
	ui_label = "Shadow Zone Threshold";
	ui_min = 0.05; ui_max = 0.6;
	ui_tooltip = "Luma below this is the Shadow zone.";
> = 0.33;

// Hue shifts are relative to each pixel's own base hue: Light leans warm/yellow,
// Mid stays near the source color, Shadow leans cool/secondary. The trajectory
// between them is continuous (see HueLerp), not a hard per-zone switch.
uniform float LightHueShift <
	ui_type = "slider";
	ui_label = "Light Hue Shift";
	ui_min = -180.0; ui_max = 180.0;
	ui_tooltip = "Hue offset applied toward the light.";
> = -5.0;

uniform float MidHueShift <
	ui_type = "slider";
	ui_label = "Mid Hue Shift";
	ui_min = -180.0; ui_max = 180.0;
	ui_tooltip = "Hue offset around the middle value range.";
> = 0.0;

uniform float ShadowHueShift <
	ui_type = "slider";
	ui_label = "Shadow Hue Shift";
	ui_min = -180.0; ui_max = 180.0;
	ui_tooltip = "Hue offset applied toward the shadow.";
> = 35.0;

uniform float LightSaturation <
	ui_type = "slider";
	ui_label = "Light Saturation";
	ui_min = 0.0; ui_max = 1.5;
	ui_tooltip = "Saturation multiplier in the light.";
> = 1.05;

uniform float MidSaturation <
	ui_type = "slider";
	ui_label = "Mid Saturation";
	ui_min = 0.0; ui_max = 1.5;
	ui_tooltip = "Saturation multiplier in the midtones.";
> = 0.75;

uniform float ShadowSaturation <
	ui_type = "slider";
	ui_label = "Shadow Saturation";
	ui_min = 0.0; ui_max = 1.5;
	ui_tooltip = "Saturation multiplier in the shadows.";
> = 0.80;

uniform float LightValue <
	ui_type = "slider";
	ui_label = "Light Value";
	ui_min = 0.7; ui_max = 1.2;
	ui_tooltip = "Value multiplier in the light.";
> = 1.0;

uniform float MidValue <
	ui_type = "slider";
	ui_label = "Mid Value";
	ui_min = 0.7; ui_max = 1.2;
	ui_tooltip = "Value multiplier in the midtones.";
> = 0.96;

uniform float ShadowValue <
	ui_type = "slider";
	ui_label = "Shadow Value";
	ui_min = 0.5; ui_max = 1.1;
	ui_tooltip = "Value multiplier in the shadows.";
> = 0.90;

uniform float PigmentVariation <
	ui_type = "slider";
	ui_label = "Pigment Variation";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "Amount of irregular color separation.";
> = 0.45;

uniform float HueVariation <
	ui_type = "slider";
	ui_label = "Hue Variation";
	ui_min = 0.0; ui_max = 45.0;
	ui_tooltip = "Small hue deviation between pigment regions.";
> = 15.0;

uniform float StructureInfluence <
	ui_type = "slider";
	ui_label = "Structure Influence";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "Makes hidden color stronger around local form changes.";
> = 0.35;

uniform float EnvironmentColorStrength <
	ui_type = "slider";
	ui_label = "Environment Color Strength";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "How strongly the surrounding color atmosphere influences each pixel.";
> = 0.20;

uniform float EnvironmentColorRadius <
	ui_type = "slider";
	ui_label = "Environment Color Radius";
	ui_min = 2.0; ui_max = 16.0;
	ui_tooltip = "Spatial scale used to estimate the surrounding color atmosphere.";
> = 7.0;

uniform float EnvironmentShadowBias <
	ui_type = "slider";
	ui_label = "Shadow Environment Bias";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "Makes environmental color stronger toward shadow areas.";
> = 0.65;

uniform float AccentStrength <
	ui_type = "slider";
	ui_label = "Complementary Color Accent";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "Small amount of complementary pigment variation.";
> = 0.10;

uniform float AccentVariation <
	ui_type = "slider";
	ui_label = "Accent Variation";
	ui_min = 0.0; ui_max = 60.0;
	ui_tooltip = "Hue variation around the complementary accent.";
> = 25.0;

#include "ReShade.fxh"

texture WatercolorBlurTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler WatercolorBlurSampler { Texture = WatercolorBlurTex; };

// Wide-radius atmosphere buffer: not meant to look blurred, just to estimate the color surrounding each pixel.
texture WatercolorAtmosphereTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler WatercolorAtmosphereSampler { Texture = WatercolorAtmosphereTex; };

float Hash12(float2 p)
{
	float3 p3 = frac(float3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return frac((p3.x + p3.y) * p3.z);
}

float3 RGBtoHSV(float3 c)
{
	float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
	float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

float3 HSVtoRGB(float3 c)
{
	float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
}

// Interpolates hue along its shortest circular path so 350deg -> 10deg doesn't cross through 180deg.
float HueLerp(float a, float b, float t)
{
	float delta = b - a;
	if (delta > 0.5) delta -= 1.0;
	if (delta < -0.5) delta += 1.0;
	return frac(a + delta * t);
}

// Smooth (bilinearly interpolated) hash noise so pigment regions blend into each other instead of snapping at grid cell borders.
float ValueNoise(float2 uv)
{
	float2 i = floor(uv);
	float2 f = frac(uv);
	float a = Hash12(i);
	float b = Hash12(i + float2(1.0, 0.0));
	float c = Hash12(i + float2(0.0, 1.0));
	float d = Hash12(i + float2(1.0, 1.0));
	float2 u = f * f * (3.0 - 2.0 * f);
	return lerp(lerp(a, b, u.x), lerp(c, d, u.x), u.y);
}

// Blends large/medium/small smooth noise octaves so pigment separation reads as soft, irregular blotches.
float PigmentPattern(float2 texcoord)
{
	float2 uv = texcoord * BUFFER_WIDTH / max(HiddenColorScale, 1.0);
	float largeA = ValueNoise(uv);
	float largeB = ValueNoise(uv * 0.73 + 17.0);
	float medium = ValueNoise(uv * 1.8 + 41.0);
	float small = ValueNoise(uv * 4.0 + 83.0);
	float large = lerp(largeA, largeB, 0.35);
	return saturate(large * 0.55 + medium * 0.30 + small * 0.15);
}

// Simple 9-tap box-ish smoothing to approximate wet-on-wet color bleed.
float3 WatercolorBlurPS(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float2 px = ReShade::PixelSize * SmoothRadius;
	float3 sum = 0.0;
	sum += tex2D(ReShade::BackBuffer, texcoord).rgb * 4.0;
	sum += tex2D(ReShade::BackBuffer, texcoord + float2(px.x, 0)).rgb;
	sum += tex2D(ReShade::BackBuffer, texcoord - float2(px.x, 0)).rgb;
	sum += tex2D(ReShade::BackBuffer, texcoord + float2(0, px.y)).rgb;
	sum += tex2D(ReShade::BackBuffer, texcoord - float2(0, px.y)).rgb;
	sum += tex2D(ReShade::BackBuffer, texcoord + px).rgb;
	sum += tex2D(ReShade::BackBuffer, texcoord - px).rgb;
	sum += tex2D(ReShade::BackBuffer, texcoord + float2(px.x, -px.y)).rgb;
	sum += tex2D(ReShade::BackBuffer, texcoord + float2(-px.x, px.y)).rgb;
	return sum / 12.0;
}

// Same 9-tap pattern as the local blur but at a much wider radius, to sample the color atmosphere around each pixel.
float3 WatercolorAtmospherePS(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float2 px = ReShade::PixelSize * EnvironmentColorRadius;
	float3 sum = 0.0;
	sum += tex2D(ReShade::BackBuffer, texcoord).rgb * 4.0;
	sum += tex2D(ReShade::BackBuffer, texcoord + float2(px.x, 0)).rgb;
	sum += tex2D(ReShade::BackBuffer, texcoord - float2(px.x, 0)).rgb;
	sum += tex2D(ReShade::BackBuffer, texcoord + float2(0, px.y)).rgb;
	sum += tex2D(ReShade::BackBuffer, texcoord - float2(0, px.y)).rgb;
	sum += tex2D(ReShade::BackBuffer, texcoord + px).rgb;
	sum += tex2D(ReShade::BackBuffer, texcoord - px).rgb;
	sum += tex2D(ReShade::BackBuffer, texcoord + float2(px.x, -px.y)).rgb;
	sum += tex2D(ReShade::BackBuffer, texcoord + float2(-px.x, px.y)).rgb;
	return sum / 12.0;
}

float3 WatercolorPaintPS(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float3 blurred = tex2D(WatercolorBlurSampler, texcoord).rgb;

	// Soft posterize: feather the step edge between bands instead of a hard round().
	float3 bands = blurred * ToneSteps;
	float3 bandFloor = floor(bands);
	float3 bandFrac = bands - bandFloor;
	float3 bandT = smoothstep(0.5 - PosterizeSoftness, 0.5 + PosterizeSoftness, bandFrac);
	float3 painted = (bandFloor + bandT) / ToneSteps;

	// Estimate local contrast from the sharp image to find contours.
	float2 px = ReShade::PixelSize;
	float3 sharp = tex2D(ReShade::BackBuffer, texcoord).rgb;
	float3 nx = tex2D(ReShade::BackBuffer, texcoord + float2(px.x, 0)).rgb;
	float3 ny = tex2D(ReShade::BackBuffer, texcoord + float2(0, px.y)).rgb;
	float edge = saturate(length(sharp - nx) + length(sharp - ny));
	painted *= saturate(1.0 - edge * EdgeDarken);

	float3 hsv = RGBtoHSV(painted);
	float baseHue = hsv.x;
	float baseSat = hsv.y;
	float baseValue = hsv.z;

	// Use the pre-posterize luma so the hue/saturation/value trajectory stays continuous
	// instead of inheriting the tone band's stair-steps.
	float luma = dot(blurred, float3(0.299, 0.587, 0.114));

	// Continuous Shadow -> Mid -> Light hue/saturation/value trajectory, instead of a hard zone switch.
	float shadowHue = frac(baseHue + ShadowHueShift / 360.0);
	float midHue = frac(baseHue + MidHueShift / 360.0);
	float lightHue = frac(baseHue + LightHueShift / 360.0);

	float targetHue, satValue, valueMultiplier;
	if (luma < ShadowZoneThreshold)
	{
		float t = smoothstep(0.0, ShadowZoneThreshold, luma);
		targetHue = HueLerp(shadowHue, midHue, t);
		satValue = lerp(ShadowSaturation, MidSaturation, t);
		valueMultiplier = lerp(ShadowValue, MidValue, t);
	}
	else
	{
		float t = smoothstep(ShadowZoneThreshold, 1.0, luma);
		targetHue = HueLerp(midHue, lightHue, t);
		satValue = lerp(MidSaturation, LightSaturation, t);
		valueMultiplier = lerp(MidValue, LightValue, t);
	}

	// Per-blotch hue jitter keeps the trajectory from painting every pixel at one exact hue.
	float patch = PigmentPattern(texcoord);
	float2 blotchUV = texcoord * BUFFER_WIDTH / max(HiddenColorScale, 1.0);
	float hueNoise = Hash12(floor(blotchUV * 0.65 + 19.0));
	float hueJitter = (hueNoise - 0.5) * HueVariation / 360.0;

	float3 targetHSV;
	targetHSV.x = frac(targetHue + hueJitter * PigmentVariation);
	targetHSV.y = saturate(baseSat * satValue);
	targetHSV.z = saturate(baseValue * valueMultiplier);
	float3 hiddenColor = HSVtoRGB(targetHSV);

	// Large pigment regions should be visible, but never fully replace the base color.
	float pigmentVisibility = lerp(0.25, 1.0, patch);
	float structureVisibility = lerp(1.0, 1.0 + edge, StructureInfluence);
	float hiddenAmount = saturate(HiddenColorStrength * 0.12 * pigmentVisibility * structureVisibility);
	painted = lerp(painted, hiddenColor, hiddenAmount);

	// Environment color: a wide blur estimates the color atmosphere around this pixel, low-saturation
	// (grayish) surroundings contribute little hue, and shadows lean on it more than highlights do.
	float3 environmentHSV = RGBtoHSV(tex2D(WatercolorAtmosphereSampler, texcoord).rgb);
	float environmentColorWeight = smoothstep(0.04, 0.25, environmentHSV.y);
	float shadowAmount = 1.0 - smoothstep(ShadowZoneThreshold, 0.75, luma);
	float environmentInfluence = EnvironmentColorStrength * environmentColorWeight
		* lerp(1.0, 1.0 + EnvironmentShadowBias, shadowAmount);

	float3 environmentHSVOut = targetHSV;
	environmentHSVOut.x = HueLerp(targetHSV.x, environmentHSV.x, environmentInfluence);
	// Environment color behaves like reflected/atmospheric pigment, so it slightly reduces purity.
	environmentHSVOut.y = lerp(targetHSV.y, targetHSV.y * 0.82, environmentInfluence);
	float3 environmentColor = HSVtoRGB(environmentHSVOut);
	painted = lerp(painted, environmentColor, hiddenAmount * environmentInfluence);

	// Local complementary accent: a small "surprise pigment" placed only in the densest pigment blotches.
	float accentNoise = Hash12(floor(blotchUV * 1.7 + 71.0));
	float accentHueJitter = (accentNoise - 0.5) * AccentVariation / 360.0;
	float3 accentHSV = targetHSV;
	accentHSV.x = frac(baseHue + 0.5 + accentHueJitter);
	accentHSV.y = saturate(targetHSV.y * 1.15);
	accentHSV.z = targetHSV.z * 0.95;
	float3 accentColor = HSVtoRGB(accentHSV);
	float accentMask = smoothstep(0.72, 0.92, patch);
	painted = lerp(painted, accentColor, AccentStrength * accentMask * hiddenAmount);

	float grain = (Hash12(texcoord * BUFFER_WIDTH) - 0.5) * PaperGrain;
	painted = saturate(painted + grain);

	return painted;
}

technique ComplementaryColours <
	ui_label = "Complementary Colours";
	ui_tooltip = "Watercolor-style posterize/blur with a hidden complementary-hue color trajectory.";
>
{
	pass Blur
	{
		VertexShader = PostProcessVS;
		PixelShader = WatercolorBlurPS;
		RenderTarget = WatercolorBlurTex;
	}
	pass Atmosphere
	{
		VertexShader = PostProcessVS;
		PixelShader = WatercolorAtmospherePS;
		RenderTarget = WatercolorAtmosphereTex;
	}
	pass Paint
	{
		VertexShader = PostProcessVS;
		PixelShader = WatercolorPaintPS;
	}
}
