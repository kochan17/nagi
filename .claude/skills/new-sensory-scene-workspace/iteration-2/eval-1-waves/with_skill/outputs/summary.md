# MoonlitWaves Scene — iteration-2 with_skill

## What was done

Added a complete `MoonlitWaves` sensory scene (deep nighttime ocean, moon overhead, moonlit specular column, touch-driven concentric ripples) following the new-sensory-scene v2 SKILL exactly. 8 steps executed in one pass:

1. **Step 0 (collision check):** `case waves` already exists in `TextureType` (variant catalog category). Per skill, used the differentiated name `MoonlitWaves` / `.moonlitWaves` (user pre-approved this in the task).
2. Read existing patterns (BonfireScene, CampfireShader, TextureType, HapticEngine factories, LocalizationManager, RelaxView, SensoryScene protocol, templates).
3. Wrote `MoonlitWavesScene.swift` — registered 3 haptic patterns (`droplet_tap`, `ripple_spread`, `deep_swell`) and ambient audio.
4. Wrote `MoonlitWavesShader.metal` — `moonlit_waves_render` kernel: night sky + stars + moon disc + perspective sea with multi-octave wave height, normal-based moonlit specular column under the moon, white caps, atmospheric mist, ACES tonemap. Touch creates 3 expanding concentric rings with pale-moon highlight.
5. TextureType: `.moonlitWaves` case + 5 switch arms (kernelName, displayNameKey, iconName, soundFileName, gradientColors). Default arms cover materialTextureName/needsFluidSim.
6. HapticEngine: `.moonlitWaves` profile (low intensity, low sharpness, ripple) + 3 static factories.
7. LocalizationManager: `.categoryMoonlitWaves` L10nKey + 4 language entries (en/ja/ko/zh).
8. RelaxView: refactored if/else → switch with `.campfire`, `.moonlitWaves`, `default`.
9. pbxproj: registered both new files via `pbxproj-register/scripts/register_one.py` (FileRef B1000104/105, BuildFile A1000104/105).

## Skill v2 helpful

- Step 0 caught the `.waves` collision instantly — without the explicit check I would have created a redundant case and broken the variant catalog.
- The "read 4 reference files first" step kept the new code 1:1 with BonfireScene conventions (Logger subsystem, struct touchState ref, `_render` suffix, eventID/completeEvent ordering).
- Step 6 v2 fix (LocalizationManager dict not xcstrings) avoided breaking Xcode.
- Trouble-shoot table preempted the kernelName/`_render` mismatch trap.

## Difficulties

None significant. The skill's "yatte wa ikenai" warning (don't commit per-file) kept everything coherent. Only minor judgment call: chose `.ripple` releaseStyle (matches `.waves`) for the profile.
