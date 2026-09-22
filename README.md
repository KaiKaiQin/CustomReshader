# CustomReshader

A small set of original ReShade/GShade `.fx` post-processing shaders, each exploring a different visual style.

## WatercolorPainting.fx

Simulates a hand-painted watercolor look through three layered techniques:

1. **Wet-on-wet blur** – a cheap 9-tap blur softens detail so colors read as "bled" pigment rather than sharp photographic edges.
2. **Posterization** – the blurred image is quantized into flat tone bands (`ToneSteps`), like mixed pigment layers instead of a smooth gradient.
3. **Edge pigment pooling** – local contrast from the sharp image darkens contours, mimicking how watercolor pigment settles along edges as it dries.

On top of that, a **hidden color trajectory** shifts each pixel's hue continuously from Shadow → Mid → Light based on its own luminance (instead of hard-switching between three fixed colors). The trajectory is intentionally subtle: highlights stay close to the base hue, while shadows drift a small, consistent amount toward a secondary hue — matching the way cel-shaded/painterly art usually keeps light colors close to "true" color and pushes most of the hue variation into the shadow side. An irregular multi-octave hash pattern (`PigmentPattern`) breaks the tint into uneven blotches instead of a flat overlay, and a small per-blotch hue jitter keeps neighboring regions from all landing on the exact same shade — approximating how real pigments separate unevenly on wet paper.

Key parameters: `SmoothRadius`, `ToneSteps`, `EdgeDarken`, `LightHueShift` / `MidHueShift` / `ShadowHueShift`, `LightSaturation` / `MidSaturation` / `ShadowSaturation`, `PigmentVariation`, `HueVariation`, `StructureInfluence`, `PaperGrain`.

## NeonAtmosphere.fx

A synthwave-inspired color grade built from three passes:

1. **Duotone grade** – shadows and highlights are pushed toward two independent tint colors (`ShadowTint` / `HighlightTint`) based on per-pixel luma, giving the classic magenta/cyan synth look without fully replacing the original color.
2. **Bright-pass glow** – a half-resolution buffer extracts pixels above `GlowThreshold` and blurs them cheaply, then adds the result back as a soft neon bloom (`GlowIntensity`).
3. **Horizon scanlines** – a faint sine-wave modulation across the vertical axis evokes a retro CRT/synth-horizon feel without being a full scanline filter.

Key parameters: `ShadowTint`, `HighlightTint`, `TintStrength`, `GlowThreshold`, `GlowIntensity`, `ScanlineStrength`.

## VintageFilmGrain.fx

A single-pass vintage film look combining several classic photographic/film cues:

1. **Lifted blacks** – blends the image toward mid-gray to fake the reduced contrast of faded film stock (`FadeAmount`).
2. **Warm/cool split-tone** – shadows are warmed and highlights cooled slightly based on luma (`WarmthAmount`), a common film emulation trick.
3. **Radial vignette** – a simple distance-from-center falloff darkens the frame edges (`VignetteStrength`).
4. **Animated light leak** – a slowly drifting diagonal gradient adds a warm streak, mimicking light leaking into a film camera (`LightLeakStrength`).
5. **Animated grain** – per-frame hashed noise driven by `frametime` keeps the grain from looking static (`GrainAmount`).

All effects are additive/multiplicative blends on top of the original image so the shader degrades gracefully at low parameter values.

## Notes

These shaders are written from scratch for this repo and are not derived from or copies of any other author's `.fx` source. They're built for ReShade/GShade and rely only on `ReShade.fxh` (`ReShade::BackBuffer`, `ReShade::PixelSize`, `PostProcessVS`).
