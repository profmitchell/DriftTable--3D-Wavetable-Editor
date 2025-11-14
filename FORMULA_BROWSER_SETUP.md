# Formula Browser Setup Guide

## Overview

The Formula Browser system allows you to browse, save, edit, and apply formulas from a library of 400+ pre-made wavetable expressions.

## Files Created

1. **FormulaLibrary.swift** - Library management and persistence
2. **FormulaBrowserView.swift** - Browser UI with categories, search, favorites
3. **Updated ExpressionPanelView.swift** - Integrated "Browse" button

## Setup Instructions

### Step 1: Add Formula Text Files to Xcode Project

The formula files need to be added to your app bundle:

1. In Xcode, select your project in the navigator
2. Right-click on the "DriftTable: 3D Wavetable Editor" folder
3. Choose "Add Files to 'DriftTable: 3D Wavetable Editor'..."
4. Navigate to your project directory
5. Select both files:
   - `FormulaUserSingles.txt`
   - `FormulaUserMultis.txt`
6. **IMPORTANT:** Check ✅ "Copy items if needed"
7. **IMPORTANT:** Check ✅ "Add to targets: DriftTable: 3D Wavetable Editor"
8. Click "Add"

### Step 2: Verify Files Are in Bundle

1. In Xcode, select your target
2. Go to "Build Phases"
3. Expand "Copy Bundle Resources"
4. Verify both `.txt` files are listed
5. If not, click the "+" button and add them

### Step 3: Build and Run

That's it! The formula browser is now ready to use.

## Features

### Browse Formulas
- **264 Single-Frame formulas** - For individual waveforms
- **173 Multi-Frame formulas** - For morphing wavetables
- Organized into categories (MD_ANLG, MD_BASS, MD_PAD, etc.)

### Categories

**Single-Frame:**
- Various (blends, folds, harmonics)
- MD_ANLG (Analog Character)
- MD_ATMO (Atmospheric)
- MD_BASS (Bass Harmonics)
- MD_PROC (Spectral Process)
- MD_PAD (Pad/Air/Width)
- MD_REES (Reese Bass)
- MD_SUB (Sub Bass)
- Fold variations (Gentle, Medium, Aggressive, Special)

**Multi-Frame:**
- Symmetrical Morphs
- Progressive Builds
- Filter/Resonant Morphs
- Sub/Deep Bass Morphs
- Saturation/Tube/Drive Morphs
- Detune/Unison Morphs
- Ring/Inharmonic Morphs
- Stepped/Sync Morphs
- DnB Wavetable Morphs
- And more!

### Search
- Search by name, expression, or category
- Real-time filtering

### Favorites
- Mark formulas as favorites with ⭐
- Quick access to your favorites
- Persisted across app launches

### User Formulas
- Save your own custom formulas
- Edit and delete your formulas
- Automatic categorization
- Validation (ensures expression compiles)

### Apply
- Tap any formula to apply it instantly
- Automatically populates the expression field
- Works with both single-frame and multi-frame modes

## Usage

### In the Expression Panel

1. Open the Formula tab (4th tab in tools)
2. Click the blue **"Browse"** button in the top right
3. Browse categories or search
4. Tap a formula to apply it
5. Hit "Apply Expression" to generate

### Save Your Own Formula

1. Create an expression in the text editor
2. Click **"Save"** button
3. Enter name and category
4. Formula is saved to "My Formulas"

### Edit/Delete User Formulas

1. Go to "My Formulas" category
2. Swipe left on any formula
3. Choose "Edit" or "Delete"
4. Or use the person icon (👤) to identify your formulas

### Quick Examples Menu

- Click "Quick" for instant access to basic waveforms
- Sine, Square, Sawtooth, Triangle, Harmonics
- Plus morphing examples if you have multiple frames

## Tips

1. **Start with Favorites** - Browse formulas and mark your favorites
2. **Explore Categories** - Each category has a different sonic character
3. **Modify and Save** - Tweak existing formulas and save as your own
4. **Search Smart** - Search for terms like "warm", "sub", "morph", "fold"
5. **Single vs Multi** - Browser automatically shows the right type based on your mode

## File Format

If you want to add more formulas manually to the text files:

```
[x][Category Name]

[expression code][Formula Name]
[another expression][Another Name]

[x][ ]

[x][Next Category]
[expression][Name]
```

- Category headers: `[x][Category Name]`
- Formulas: `[expression][Name]`
- Empty category: `[x][ ]` (spacer)

## Troubleshooting

### "File not found" error
- Formula text files aren't in the app bundle
- Follow Step 1 and 2 above to add them

### No formulas showing
- Check that files are added to "Copy Bundle Resources"
- Clean build folder (Cmd+Shift+K) and rebuild

### Can't save formulas
- User formulas are saved to UserDefaults
- No file access needed for this feature

## Integration with Your Workflow

The browser integrates seamlessly:
- **Key Shape Mode**: Browse single-frame formulas
- **Generated Frames Mode**: Browse multi-frame formulas
- Automatically detects which type to show
- All formulas validated before applying

Enjoy your 400+ formula library! 🎉

