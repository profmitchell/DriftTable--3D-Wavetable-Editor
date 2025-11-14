# Math Expression Wavetable Generator

A complete, production-ready math expression generator for wavetable synthesis in SwiftUI/iOS.

## 🎯 Overview

This system allows users to generate wavetable waveforms using mathematical expressions. It includes:

- **Full expression parser and evaluator** with operator precedence, functions, constants, and variables
- **Single-frame and multi-frame modes** that automatically detect based on expression content
- **SwiftUI interface** with real-time mode detection and error handling
- **Comprehensive function library** including trigonometric, hyperbolic, logarithmic functions

## 📦 Components

### Core Files

1. **FormulaEngine.swift** - Complete expression parser and evaluator
   - Tokenizer for parsing expression strings
   - Recursive descent parser with proper operator precedence
   - AST-based evaluation with safety checks
   - Variable usage analysis for automatic mode detection

2. **ExpressionApplicator.swift** - Application logic for wavetables
   - Single-frame mode (affects only selected frame)
   - Multi-frame mode (affects all frames with frame variables)
   - Reproducible random number generation
   - Safe clamping to [-1, 1] range

3. **ExpressionPanelView.swift** - SwiftUI interface
   - Expression text editor with syntax highlighting
   - Automatic mode detection display
   - Example expressions gallery
   - Variable reference guide
   - Error reporting

4. **WavetableEditorDemoView.swift** - Complete working demo
   - Waveform visualization
   - Frame selection
   - Multi-frame grid view
   - Integration example

5. **ExpressionGeneratorDemoApp.swift** - Standalone demo app
   - Can be used as main app or integrated
   - Multiple integration examples
   - Programmatic usage examples

## 🚀 Quick Start

### Option 1: Run the Demo

To test the expression generator standalone:

1. Open `ExpressionGeneratorDemoApp.swift`
2. Uncomment the `@main` attribute
3. Comment out `@main` in `DriftTable__3D_Wavetable_EditorApp.swift`
4. Run the app

### Option 2: Integrate into Existing App

Add the expression panel to any view with wavetable frames:

```swift
import SwiftUI

struct MyWavetableEditor: View {
    @State private var frames: [[Float]] = Array(
        repeating: Array(repeating: 0.0, count: 256),
        count: 8
    )
    @State private var selectedFrameIndex = 0
    
    var body: some View {
        VStack {
            // Your existing UI
            
            ExpressionPanelView(
                frames: $frames,
                selectedFrameIndex: $selectedFrameIndex,
                sampleCount: 256
            )
        }
    }
}
```

### Option 3: Programmatic Usage

Use the engine directly without UI:

```swift
let engine = FormulaEngine()

// Compile expression
let compiled = try engine.compile("sin(2 * pi * x)")

// Apply to frames
var frames = Array(repeating: Array(repeating: Float(0.0), count: 256), count: 8)
try applyExpressionSingleFrame(
    compiled: compiled,
    engine: engine,
    frames: &frames,
    selectedFrameIndex: 0,
    sampleCount: 256
)
```

## 📖 Expression Language

### Variables

| Variable | Range | Description |
|----------|-------|-------------|
| `x` | [-1, 1] | Horizontal position (centered) |
| `w` | [0, 1] | Horizontal position (normalized) |
| `y` | [0, 1] | Frame index (normalized) - **triggers multi-frame mode** |
| `z` | [-1, 1] | Frame index (centered) - **triggers multi-frame mode** |
| `in` | [-1, 1] | Original sample value before applying expression |
| `sel` | [-1, 1] | Sample from the originally selected frame |
| `rand` | [-1, 1] | Reproducible random value per sample index |
| `q` | integer | Optional harmonic index (1-512) for spectral mode |

### Constants

- `pi` = 3.141592653589793
- `e` = 2.718281828459045

### Operators

**Arithmetic** (by precedence):
- `^` - Power (right-associative)
- `*`, `/` - Multiply, divide
- `+`, `-` - Add, subtract

**Comparison**:
- `<`, `>`, `<=`, `>=` - Comparison (returns 1.0 or 0.0)
- `==`, `!=` - Equality (with floating-point tolerance)

**Logical**:
- `&&` - Logical AND (short-circuit)
- `||` - Logical OR (short-circuit)
- `!` - Logical NOT (unary)

**Ternary (using logical operators)**:
```
x < 0 ? 1 : -1    →    (x < 0) && 1 || -1
```

### Functions

**Trigonometric**:
- `sin(x)`, `cos(x)`, `tan(x)`
- `asin(x)`, `acos(x)`, `atan(x)`

**Hyperbolic**:
- `sinh(x)`, `cosh(x)`, `tanh(x)`
- `asinh(x)`, `acosh(x)`, `atanh(x)`

**Logarithmic & Exponential**:
- `log2(x)`, `log10(x)`, `log(x)` (alias for log10)
- `ln(x)` (natural log)
- `exp(x)` (e^x)
- `sqrt(x)`

**Other**:
- `abs(x)` - Absolute value
- `sign(x)` - Sign (-1, 0, or 1)
- `rint(x)` - Round to nearest integer

**Multi-argument**:
- `min(a, b, ...)` - Minimum value
- `max(a, b, ...)` - Maximum value
- `sum(a, b, ...)` - Sum of values
- `avg(a, b, ...)` - Average of values

## 📝 Example Expressions

### Single-Frame (no `y` or `z`)

**Basic Waveforms**:
```
sin(2 * pi * x)                    // Sine wave
sign(sin(2 * pi * x))              // Square wave
x                                   // Sawtooth
abs(x) * 2 - 1                     // Triangle
```

**Pulse Width Modulation**:
```
x < 0.5 ? 1 : -1                   // 50% duty cycle
x < 0.25 ? 1 : -1                  // 25% duty cycle
```

**Complex Harmonics**:
```
sin(2*pi*x) + 0.5*sin(4*pi*x) + 0.25*sin(6*pi*x)
```

**Waveshaping**:
```
tanh(3 * x)                        // Soft clipping
x / (1 + abs(x))                   // Asymptotic saturation
x * (2 - abs(x))                   // Parabolic shaping
```

### Multi-Frame (uses `y` or `z`)

**Morphing Waveforms**:
```
sin(2*pi*x) * (1 - y) + sign(sin(2*pi*x)) * y
// Morphs from sine to square across frames
```

**Frame-Dependent Harmonics**:
```
sin(2*pi*x) + z * abs(sin(2*pi*x))
// Adds harmonics based on frame position
```

**Evolving Complexity**:
```
sin(2*pi*x) * (1 + y * 5)
// Increases frequency across frames
```

**Cross-Frame Mixing**:
```
in * (1 - abs(z)) + sel * abs(z)
// Morphs from original to selected frame
```

## 🎨 Modes

### Single-Frame Mode

- **Triggers when**: Expression does NOT use `y` or `z` variables
- **Behavior**: Only modifies the currently selected frame
- **Use case**: Creating individual waveforms, editing specific frames

### Multi-Frame Mode

- **Triggers when**: Expression uses `y` or `z` variables
- **Behavior**: Regenerates ALL frames in the wavetable
- **Use case**: Creating smooth morphing sequences, wavetable evolution

**Mode is automatically detected** - no manual selection needed!

## ⚡ Performance

- **Compilation**: Once per expression (on "Apply")
- **Random generation**: Precomputed once per application
- **Evaluation**: Optimized AST traversal, no allocations in inner loop
- **Thread safety**: Background processing with main thread updates

## 🛡️ Error Handling

### Parse Errors

```
Expression: "sin 2 * pi * x"
Error: Parse error: Expected ')'
```

### Evaluation Errors

```
Expression: "log(-1)"
Result: 0.0 (safe fallback, no crash)
```

### Division by Zero

```
Expression: "1 / 0"
Result: 0.0 (safe fallback)
```

All errors are caught and displayed in the UI - **no crashes**.

## 🔧 Customization

### Add New Functions

Edit `FormulaEngine.swift`, in `evaluateFunction`:

```swift
case "myfunction":
    guard args.count == 1 else { 
        throw FormulaError.evaluationError("myfunction expects 1 argument") 
    }
    return myCustomImplementation(args[0])
```

### Add New Constants

Edit `FormulaEngine.swift`, in the `constants` dictionary:

```swift
private let constants: [String: Float] = [
    "pi": Float.pi,
    "e": Float(M_E),
    "myconstant": 42.0
]
```

### Add New Operators

1. Add to `BinaryOperator` enum with precedence
2. Handle in `evaluateBinaryOp` function
3. Update tokenizer to recognize the operator symbol

## 📱 UI Features

- **Live mode detection** - Shows single/multi-frame mode as you type
- **Example gallery** - Tap to load preset expressions
- **Variable reference** - Collapsible guide always available
- **Background processing** - No UI blocking during generation
- **Error display** - Clear, helpful error messages
- **Multi-line editor** - Monospaced font for complex expressions

## 🧪 Testing

Run the unit tests (create these if needed):

```swift
func testBasicExpression() throws {
    let engine = FormulaEngine()
    let compiled = try engine.compile("2 + 3")
    let context = FormulaContext(x: 0, w: 0, y: 0, z: 0, 
                                  inSample: 0, selSample: 0, 
                                  randSample: 0, q: nil)
    let result = try engine.evaluate(compiled, context: context)
    XCTAssertEqual(result, 5.0)
}

func testModeDetection() throws {
    let engine = FormulaEngine()
    
    let singleFrame = try engine.compile("sin(2 * pi * x)")
    XCTAssertFalse(engine.usesFrameVariables(singleFrame))
    
    let multiFrame = try engine.compile("sin(2 * pi * x) * y")
    XCTAssertTrue(engine.usesFrameVariables(multiFrame))
}
```

## 📚 Integration with Main App

To add this to your wavetable editor's main view (e.g., `MainWindowView.swift`):

```swift
// Add as a new sidebar item or sheet
.sheet(isPresented: $showExpressionGenerator) {
    NavigationView {
        ExpressionPanelView(
            frames: $projectViewModel.project.generatedFrames,
            selectedFrameIndex: $projectViewModel.selectedFrameIndex,
            sampleCount: projectViewModel.project.samplesPerFrame
        )
        .navigationTitle("Expression Generator")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") { showExpressionGenerator = false }
            }
        }
    }
}
```

Or add as a menu item:

```swift
Button(action: { showExpressionGenerator = true }) {
    Label("Expression Generator", systemImage: "function")
}
```

## 🎓 Advanced Usage

### Combining with Original Samples

```
in * 0.5 + sin(2*pi*x) * 0.5
// Blend original with generated sine
```

### Frame Interpolation

```
in * (1 - abs(z)) + sel * abs(z)
// Smoothly interpolate from selected frame
```

### Conditional Processing

```
x < 0 ? in : sin(2*pi*x)
// Keep left half, generate right half
```

### Random Variation

```
sin(2*pi*x) + rand * 0.1
// Add slight random variation per sample
```

## 🐛 Known Limitations

- No variable assignment (read-only variables)
- No loops or recursion (single-pass evaluation)
- Floating-point precision limitations
- Expression length limited by UI (can be very long)

## 📄 License

Part of DriftTable: 3D Wavetable Editor
Created by Mitchell Cohen, 2025

## 🙏 Acknowledgments

Built with:
- Swift 5.9+
- SwiftUI
- iOS 17+

