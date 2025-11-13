# DriftTable Tools Guide

This guide explains all the tools available in DriftTable and how to use them effectively.

---

## Table of Contents

1. [Shape Tools](#shape-tools) - Tools for editing individual key shapes
2. [Flow Tools](#flow-tools) - Tools for editing the entire wavetable across frames
3. [Workflow Tips](#workflow-tips)

---

## Shape Tools

Shape tools modify individual **key shapes** (single-cycle waveforms like A, B, C). These changes affect the entire wavetable when you regenerate frames.

### 1. **Lift / Drop** 📊
**Icon:** `arrow.up.and.down`

**What it does:** Adds or subtracts a constant value from all samples in the waveform. This shifts the entire waveform up (positive) or down (negative).

**Parameters:**
- **Amount** (-1.0 to 1.0): How much to shift the waveform
  - Positive values lift the waveform up
  - Negative values drop it down
  - 0.0 = no change

**Use cases:**
- Adjusting DC offset
- Centering a waveform around zero
- Creating asymmetrical waveforms

**Example:** A sine wave with Amount = 0.3 becomes a sine wave shifted upward by 30% of its amplitude.

---

### 2. **Vertical Stretch** 📏
**Icon:** `arrow.up.and.down.circle`

**What it does:** Multiplies all sample values by a factor, making the waveform taller (amplitude increase) or shorter (amplitude decrease).

**Parameters:**
- **Amount** (0.1 to 3.0): Stretch factor
  - 1.0 = no change
  - > 1.0 = increases amplitude (waveform gets taller)
  - < 1.0 = decreases amplitude (waveform gets shorter)
  - Values below 1.0 can make the waveform quieter

**Use cases:**
- Boosting or reducing overall amplitude
- Creating more dynamic or subtle waveforms
- Normalizing amplitude before morphing

**Example:** Amount = 2.0 doubles the amplitude, making peaks twice as high.

---

### 3. **Horizontal Stretch** ↔️
**Icon:** `arrow.left.and.right`

**What it does:** Stretches or compresses the waveform horizontally by resampling. Higher values stretch (slow down the cycle), lower values compress (speed up the cycle).

**Parameters:**
- **Amount** (0.1 to 3.0): Stretch factor
  - 1.0 = no change
  - > 1.0 = stretches horizontally (waveform spreads out)
  - < 1.0 = compresses horizontally (waveform squeezes together)

**Use cases:**
- Changing the harmonic content
- Creating slower or faster waveforms
- Adjusting phase relationships

**Example:** Amount = 2.0 makes the waveform twice as wide, effectively halving the frequency content.

---

### 4. **Pinch** ✋
**Icon:** `hand.pinch`

**What it does:** Reduces amplitude around a specific point, creating a "pinched" or narrowed region in the waveform.

**Parameters:**
- **Position** (0.0 to 1.0): Where to apply the pinch (0.0 = start, 1.0 = end)
- **Strength** (0.0 to 1.0): How strong the pinch effect is
  - 0.0 = no effect
  - 1.0 = maximum pinch (can reduce amplitude to near zero at the position)

**How it works:** The effect is strongest at the position and fades out exponentially with distance.

**Use cases:**
- Creating notches or dips in waveforms
- Removing specific harmonics
- Creating unique timbral characteristics

**Example:** Position = 0.5, Strength = 0.8 creates a deep notch in the middle of the waveform.

---

### 5. **Arc** 🌊
**Icon:** `waveform.path`

**What it does:** Applies a curved transformation to a specific region of the waveform, creating an arc shape (either convex or concave).

**Parameters:**
- **Start Position** (0.0 to 1.0): Where the arc begins
- **End Position** (0.0 to 1.0): Where the arc ends (must be > Start Position)
- **Curvature** (-1.0 to 1.0): The shape of the arc
  - Positive = convex arc (bulges upward)
  - Negative = concave arc (dips downward)
  - 0.0 = linear (no curve)

**Use cases:**
- Creating smooth curves in specific regions
- Shaping attack or decay portions
- Adding musical character to waveforms

**Example:** Start = 0.25, End = 0.75, Curvature = 0.7 creates a smooth upward bulge in the middle third of the waveform.

---

### 6. **Tilt** ↗️
**Icon:** `arrow.turn.up.right`

**What it does:** Applies a linear tilt across the waveform, making one side higher and the other side lower.

**Parameters:**
- **Amount** (-1.0 to 1.0): Tilt strength and direction
  - Positive = left side goes down, right side goes up
  - Negative = left side goes up, right side goes down
  - 0.0 = no tilt

**Use cases:**
- Creating asymmetrical waveforms
- Adding movement or direction to static shapes
- Creating unique timbres

**Example:** Amount = 0.5 creates a gradual slope from left to right.

---

### 7. **Symmetry** 🔄
**Icon:** `arrow.triangle.2.circlepath`

**What it does:** Blends the waveform with its mirror image, creating symmetrical or partially symmetrical waveforms.

**Parameters:**
- **Amount** (0.0 to 1.0): How much to blend with the mirror
  - 0.0 = original waveform (no symmetry)
  - 1.0 = fully symmetrical (perfect mirror)
  - 0.5 = 50% blend of original and mirror

**Use cases:**
- Creating perfectly symmetrical waveforms
- Removing odd harmonics
- Creating unique hybrid shapes

**Example:** Amount = 1.0 on a sawtooth wave creates a triangle wave (symmetrical sawtooth).

---

### 8. **Smooth Brush** 🖌️
**Icon:** `paintbrush`

**What it does:** Interactive tool that smooths out local regions of the waveform by averaging nearby samples. Drag on the waveform to apply.

**Parameters:**
- **Brush Size** (0.01 to 0.5): How large the smoothing area is (normalized)
- **Strength** (0.0 to 1.0): How much smoothing to apply
  - 0.0 = no smoothing
  - 1.0 = maximum smoothing (strong averaging)

**How to use:**
1. Select Smooth Brush tool
2. Adjust brush size and strength
3. Drag on the waveform where you want to smooth
4. The tool averages nearby samples to create smooth curves

**Use cases:**
- Removing noise or artifacts
- Smoothing out rough edges
- Creating flowing, organic shapes
- Fixing unwanted kinks or discontinuities

**Tip:** Use smaller brush sizes for precise smoothing, larger sizes for broad smoothing.

---

### 9. **Grit Brush** ✨
**Icon:** `sparkles`

**What it does:** Interactive tool that adds controlled micro-ripples and texture to local regions. Drag on the waveform to apply.

**Parameters:**
- **Brush Size** (0.01 to 0.5): How large the texturing area is
- **Intensity** (0.0 to 1.0): How strong the texture effect is
  - Higher values add more pronounced ripples
  - Lower values add subtle texture

**How to use:**
1. Select Grit Brush tool
2. Adjust brush size and intensity
3. Drag on the waveform where you want texture
4. The tool adds randomized micro-ripples for character

**Use cases:**
- Adding harmonic complexity
- Creating "gritty" or "dirty" textures
- Adding character to clean waveforms
- Creating unique timbres

**Tip:** Use sparingly - a little grit goes a long way!

---

## Flow Tools

Flow tools modify the **entire wavetable** across all frames. They create movement, variation, and animation through the wavetable. These tools work on generated frames (after you've created a wavetable from key shapes).

### 1. **Drift** 🌊
**Icon:** `arrow.left.and.right`

**What it does:** Shifts samples horizontally within each frame, creating a "drifting" effect. The waveform appears to slide left or right.

**Parameters:**
- **Direction:** Left or Right
  - Left = samples shift left (waveform appears to move right)
  - Right = samples shift right (waveform appears to move left)
- **Amount** (0.0 to 2.0): How much to shift
  - Higher values create more dramatic shifts
  - Can shift up to 50% of the waveform

**Use cases:**
- Creating phase movement through the wavetable
- Adding motion and life to static wavetables
- Creating evolving timbres

**Example:** Drift Right with Amount = 0.5 makes waveforms gradually shift right as you move through frames, creating a sense of movement.

---

### 2. **Taper** 📉
**Icon:** `arrow.down`

**What it does:** Gradually changes the amplitude of frames from start to end, creating a fade or build-up effect.

**Parameters:**
- **Start Intensity** (0.0 to 2.0): Amplitude at the first frame
- **End Intensity** (0.0 to 2.0): Amplitude at the last frame
  - Values > 1.0 amplify
  - Values < 1.0 reduce amplitude
  - Linear interpolation between start and end

**Use cases:**
- Creating fade-ins or fade-outs
- Building intensity through the wavetable
- Creating dynamic range variations

**Example:** Start = 0.5, End = 1.5 creates a gradual fade-in that doubles in amplitude.

---

### 3. **Wind** 💨
**Icon:** `wind`

**What it does:** Creates a "wind" effect that pushes samples horizontally with varying strength based on frame position. Creates a sense of motion and flow.

**Parameters:**
- **Direction:** Left to Right or Right to Left
- **Strength** (0.0 to 2.0): How strong the wind effect is
- **Falloff** (0.0 to 1.0): How much the effect decreases through frames
  - 0.0 = constant strength
  - 1.0 = strong at start, weak at end

**Use cases:**
- Creating flowing, animated wavetables
- Adding organic movement
- Creating evolving textures

**Example:** Wind Left to Right with Strength = 1.0, Falloff = 0.5 creates a strong push at the beginning that gradually weakens.

---

### 4. **Turbulence Noise** 🌪️
**Icon:** `sparkles`

**What it does:** Adds smooth, coherent noise distortion across the wavetable. Creates subtle variations and texture without harsh artifacts.

**Parameters:**
- **Noise Amount** (0.0 to 0.2): How much noise to add
  - Higher values = more distortion
  - Lower values = subtle texture
- **Frame Frequency** (0.1 to 5.0): How quickly noise changes between frames
  - Higher = faster variation
  - Lower = slower, smoother variation
- **Sample Frequency** (0.1 to 5.0): How quickly noise changes within each frame
  - Higher = more detailed noise
  - Lower = smoother noise patterns

**Use cases:**
- Adding organic variation
- Creating "analog" character
- Breaking up perfect digital waveforms
- Adding subtle movement

**Example:** Noise Amount = 0.05, Frame Frequency = 1.0, Sample Frequency = 2.0 creates subtle, smooth variations.

---

### 5. **Gravity Well** ⭕
**Icon:** `circle.circle`

**What it does:** Pulls all amplitudes toward a target value, creating a "gravity" effect that normalizes or distorts the waveform.

**Parameters:**
- **Target Amplitude** (-1.0 to 1.0): The amplitude value to pull toward
  - 0.0 = pulls toward zero (centering)
  - Positive = pulls toward positive peaks
  - Negative = pulls toward negative peaks
- **Strength** (0.0 to 1.0): How strong the pull is
  - 1.0 = maximum pull (can flatten waveform)
  - Lower values = subtle effect

**Use cases:**
- Normalizing amplitudes
- Creating unique distortions
- Pulling waveforms toward specific shapes
- Creating "collapsed" or "expanded" effects

**Example:** Target = 0.0, Strength = 0.3 gradually pulls all samples toward zero, creating a subtle compression effect.

---

### 6. **Swirl** 🌪️
**Icon:** `arrow.triangle.2.circlepath`

**What it does:** Rotates waveforms around a center point, creating a swirling effect that evolves through frames.

**Parameters:**
- **Swirl Amount** (-3.14 to 3.14 radians): How much to rotate
  - Positive = clockwise rotation
  - Negative = counter-clockwise
  - Larger values = more rotation
- **Center X** (0.0 to 1.0): Horizontal center of rotation
- **Center Y** (0.0 to 1.0): Vertical center of rotation (mapped to amplitude range)

**Use cases:**
- Creating rotating, evolving waveforms
- Adding complex movement
- Creating unique phase relationships
- Generating interesting timbres

**Example:** Swirl Amount = 1.57 (90°), Center X = 0.5, Center Y = 0.5 rotates waveforms around the center, creating a spiral effect.

---

### 7. **Shear** ✂️
**Icon:** `arrow.turn.up.right`

**What it does:** Tilts waveforms horizontally based on their amplitude, creating a shearing effect that varies by frame.

**Parameters:**
- **Shear Amount** (-0.5 to 0.5): How much to tilt
  - Positive = tilt one direction
  - Negative = tilt opposite direction
- **Frame Influence** (0.0 to 1.0): How much frame position affects the shear
  - 0.0 = constant shear
  - 1.0 = shear increases with frame position

**Use cases:**
- Creating dynamic tilting effects
- Adding frame-dependent variation
- Creating evolving distortions

**Example:** Shear Amount = 0.2, Frame Influence = 0.7 creates a tilt that increases as you move through frames.

---

### 8. **Ripple Along Frames** 🌊
**Icon:** `waveform.path`

**What it does:** Makes the amplitude "breathe" or pulse along the frame axis, creating a rhythmic variation.

**Parameters:**
- **Ripple Depth** (0.0 to 1.0): How much the amplitude varies
  - 0.0 = no variation
  - 1.0 = maximum variation (can double or halve amplitude)
- **Period (Frames)** (4.0 to 128.0): How many frames for one complete ripple cycle
  - Lower = faster ripples
  - Higher = slower ripples
- **Phase Offset** (0.0 to 2π radians): Starting phase of the ripple
  - Adjusts where the ripple starts

**Use cases:**
- Creating rhythmic variations
- Adding "breathing" effects
- Creating pulsing wavetables
- Adding musical movement

**Example:** Ripple Depth = 0.3, Period = 32 frames creates a gentle pulse that completes one cycle every 32 frames.

---

### 9. **Glitch Sprinkle** ⚡
**Icon:** `exclamationmark.triangle`

**What it does:** Randomly applies strong distortions to individual frames, creating "glitch" effects sporadically throughout the wavetable.

**Parameters:**
- **Probability per Frame** (0.0 to 0.2): Chance that each frame will be glitched
  - 0.05 = 5% chance per frame
  - Higher = more glitches
- **Glitch Intensity** (0.0 to 1.0): How strong each glitch is
  - Higher = more extreme distortion
  - Lower = subtle glitches

**How it works:** Uses deterministic randomness (seeded) so results are reproducible. Applies jitter and nonlinear distortion to glitched frames.

**Use cases:**
- Adding digital artifacts
- Creating "broken" or "corrupted" sounds
- Adding character and unpredictability
- Creating experimental textures

**Example:** Probability = 0.05, Intensity = 0.5 creates occasional moderate glitches throughout the wavetable.

**Tip:** Use sparingly - too many glitches can make the wavetable unusable!

---

## Workflow Tips

### General Workflow

1. **Start with Key Shapes**
   - Create or import 2+ key shapes (A, B, C, etc.)
   - Use Shape Tools to sculpt each key shape
   - Preview single cycles with the play button

2. **Generate Wavetable**
   - Set Frame Count (64, 128, 256, etc.)
   - Choose Morph Style (Linear, Ease In/Out, etc.)
   - Click "Generate Frames"

3. **Apply Flow Tools**
   - Use Flow Tools to add movement and variation
   - Adjust parameters in real-time
   - Click "Apply Flow" to commit changes

4. **Fine-tune**
   - Use "Normalize" if needed
   - Adjust individual key shapes and regenerate
   - Layer multiple flow tools for complex effects

### Shape Tools Tips

- **Combine tools:** Apply multiple shape tools in sequence for complex shapes
- **Use Smooth Brush:** Clean up rough edges after applying other tools
- **Symmetry tool:** Great for removing odd harmonics
- **Pinch tool:** Useful for creating notches or removing specific frequencies

### Flow Tools Tips

- **Start subtle:** Flow tools can be powerful - start with low values
- **Layer effects:** Apply multiple flow tools for complex animations
- **Use gradients:** Flow tools respect frame gradients for selective application
- **Preview often:** Use the audio preview to hear how flow tools affect the sound

### Best Practices

1. **Save frequently:** Use "Save" to preserve your work
2. **Experiment:** Try different combinations - creativity is key!
3. **Normalize:** Use the Normalize button to ensure optimal levels
4. **Undo/Redo:** Don't be afraid to experiment - you can always undo
5. **Preview:** Always preview your wavetable before exporting

---

## Quick Reference

### Shape Tools (for Key Shapes)
- **Lift/Drop** - Shift waveform up/down
- **Vertical Stretch** - Change amplitude
- **Horizontal Stretch** - Change frequency content
- **Pinch** - Create notches
- **Arc** - Add curves to regions
- **Tilt** - Create slopes
- **Symmetry** - Mirror blending
- **Smooth Brush** - Drag to smooth
- **Grit Brush** - Drag to add texture

### Flow Tools (for Wavetables)
- **Drift** - Horizontal shifting
- **Taper** - Amplitude fade
- **Wind** - Flowing motion
- **Turbulence Noise** - Smooth distortion
- **Gravity Well** - Amplitude pulling
- **Swirl** - Rotation effect
- **Shear** - Tilting distortion
- **Ripple Along Frames** - Pulsing variation
- **Glitch Sprinkle** - Random glitches

---

Happy wavetable designing! 🎵

