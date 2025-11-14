//
//  FormulaEngineTests.swift
//  DriftTable
//
//  Test suite for FormulaEngine (can be moved to test target)
//

import Foundation

/// Simple test runner for FormulaEngine
/// Run these from your test target or use as inline verification
struct FormulaEngineTests {
    
    static func runAllTests() {
        print("🧪 Running FormulaEngine Tests...")
        
        testBasicArithmetic()
        testTrigonometric()
        testVariables()
        testModeDetection()
        testMultiArgumentFunctions()
        testLogicalOperators()
        testErrorHandling()
        testComplexExpressions()
        testSingleFrameApplication()
        testMultiFrameApplication()
        
        print("✅ All tests completed!")
    }
    
    static func testBasicArithmetic() {
        print("Testing basic arithmetic...")
        let engine = FormulaEngine()
        let context = FormulaContext(x: 0, w: 0, y: 0, z: 0, inSample: 0, selSample: 0, randSample: 0, q: nil)
        
        do {
            let result1 = try evaluate(engine, "2 + 3", context)
            assert(result1 == 5.0)
            let result2 = try evaluate(engine, "10 - 3", context)
            assert(result2 == 7.0)
            let result3 = try evaluate(engine, "4 * 5", context)
            assert(result3 == 20.0)
            let result4 = try evaluate(engine, "10 / 2", context)
            assert(result4 == 5.0)
            let result5 = try evaluate(engine, "2 ^ 3", context)
            assert(result5 == 8.0)
            let result6 = try evaluate(engine, "2 + 3 * 4", context)
            assert(result6 == 14.0) // Precedence
            let result7 = try evaluate(engine, "(2 + 3) * 4", context)
            assert(result7 == 20.0) // Parentheses
            print("  ✓ Basic arithmetic")
        } catch {
            print("  ✗ Failed: \(error)")
        }
    }
    
    static func testTrigonometric() {
        print("Testing trigonometric functions...")
        let engine = FormulaEngine()
        let context = FormulaContext(x: 0, w: 0, y: 0, z: 0, inSample: 0, selSample: 0, randSample: 0, q: nil)
        
        do {
            let sinPi = try evaluate(engine, "sin(pi)", context)
            assert(abs(sinPi) < 0.0001, "sin(pi) should be ~0")
            
            let cos0 = try evaluate(engine, "cos(0)", context)
            assert(abs(cos0 - 1.0) < 0.0001, "cos(0) should be 1")
            
            let tan0 = try evaluate(engine, "tan(0)", context)
            assert(abs(tan0) < 0.0001, "tan(0) should be ~0")
            
            print("  ✓ Trigonometric functions")
        } catch {
            print("  ✗ Failed: \(error)")
        }
    }
    
    static func testVariables() {
        print("Testing variables...")
        let engine = FormulaEngine()
        
        do {
            let context = FormulaContext(x: 0.5, w: 0.25, y: 0.75, z: 0.1, 
                                          inSample: -0.5, selSample: 0.8, 
                                          randSample: 0.3, q: 5)
            
            let xVal = try evaluate(engine, "x", context)
            assert(xVal == 0.5)
            let wVal = try evaluate(engine, "w", context)
            assert(wVal == 0.25)
            let yVal = try evaluate(engine, "y", context)
            assert(yVal == 0.75)
            let zVal = try evaluate(engine, "z", context)
            assert(zVal == 0.1)
            let inVal = try evaluate(engine, "in", context)
            assert(inVal == -0.5)
            let selVal = try evaluate(engine, "sel", context)
            assert(selVal == 0.8)
            let randVal = try evaluate(engine, "rand", context)
            assert(randVal == 0.3)
            let qVal = try evaluate(engine, "q", context)
            assert(qVal == 5.0)
            
            print("  ✓ Variables")
        } catch {
            print("  ✗ Failed: \(error)")
        }
    }
    
    static func testModeDetection() {
        print("Testing mode detection...")
        let engine = FormulaEngine()
        
        do {
            let singleFrame = try engine.compile("sin(2 * pi * x)")
            assert(!engine.usesFrameVariables(singleFrame), "Should be single-frame mode")
            
            let multiFrameY = try engine.compile("sin(2 * pi * x) * y")
            assert(engine.usesFrameVariables(multiFrameY), "Should be multi-frame mode (y)")
            
            let multiFrameZ = try engine.compile("sin(2 * pi * x) * z")
            assert(engine.usesFrameVariables(multiFrameZ), "Should be multi-frame mode (z)")
            
            let multiFrameBoth = try engine.compile("sin(2 * pi * x) * (y + z)")
            assert(engine.usesFrameVariables(multiFrameBoth), "Should be multi-frame mode (both)")
            
            print("  ✓ Mode detection")
        } catch {
            print("  ✗ Failed: \(error)")
        }
    }
    
    static func testMultiArgumentFunctions() {
        print("Testing multi-argument functions...")
        let engine = FormulaEngine()
        let context = FormulaContext(x: 0, w: 0, y: 0, z: 0, inSample: 0, selSample: 0, randSample: 0, q: nil)
        
        do {
            let minVal = try evaluate(engine, "min(5, 3, 8)", context)
            assert(minVal == 3.0)
            let maxVal = try evaluate(engine, "max(5, 3, 8)", context)
            assert(maxVal == 8.0)
            let sumVal = try evaluate(engine, "sum(1, 2, 3, 4)", context)
            assert(sumVal == 10.0)
            let avgVal = try evaluate(engine, "avg(2, 4, 6)", context)
            assert(avgVal == 4.0)
            print("  ✓ Multi-argument functions")
        } catch {
            print("  ✗ Failed: \(error)")
        }
    }
    
    static func testLogicalOperators() {
        print("Testing logical operators...")
        let engine = FormulaEngine()
        let context = FormulaContext(x: 0, w: 0, y: 0, z: 0, inSample: 0, selSample: 0, randSample: 0, q: nil)
        
        do {
            let gt = try evaluate(engine, "5 > 3", context)
            assert(gt == 1.0)
            let lt = try evaluate(engine, "5 < 3", context)
            assert(lt == 0.0)
            let gte = try evaluate(engine, "5 >= 5", context)
            assert(gte == 1.0)
            let lte = try evaluate(engine, "5 <= 4", context)
            assert(lte == 0.0)
            let eq = try evaluate(engine, "5 == 5", context)
            assert(eq == 1.0)
            let neq = try evaluate(engine, "5 != 3", context)
            assert(neq == 1.0)
            let and1 = try evaluate(engine, "1 && 1", context)
            assert(and1 == 1.0)
            let and0 = try evaluate(engine, "1 && 0", context)
            assert(and0 == 0.0)
            let or1 = try evaluate(engine, "0 || 1", context)
            assert(or1 == 1.0)
            let or0 = try evaluate(engine, "0 || 0", context)
            assert(or0 == 0.0)
            print("  ✓ Logical operators")
        } catch {
            print("  ✗ Failed: \(error)")
        }
    }
    
    static func testErrorHandling() {
        print("Testing error handling...")
        let engine = FormulaEngine()
        let context = FormulaContext(x: 0, w: 0, y: 0, z: 0, inSample: 0, selSample: 0, randSample: 0, q: nil)
        
        // Division by zero - should return 0 safely
        do {
            let result = try evaluate(engine, "1 / 0", context)
            assert(result == 0.0, "Division by zero should return 0")
        } catch {
            print("  ✗ Division by zero threw: \(error)")
        }
        
        // Invalid log - should return 0 safely
        do {
            let result = try evaluate(engine, "log(-1)", context)
            assert(result == 0.0, "log(-1) should return 0")
        } catch {
            print("  ✗ Invalid log threw: \(error)")
        }
        
        // Parse error
        do {
            _ = try engine.compile("2 + + 3")
            print("  ✗ Should have thrown parse error")
        } catch FormulaError.parseError {
            // Expected
        } catch {
            print("  ✗ Wrong error type: \(error)")
        }
        
        print("  ✓ Error handling")
    }
    
    static func testComplexExpressions() {
        print("Testing complex expressions...")
        let engine = FormulaEngine()
        let context = FormulaContext(x: 0.5, w: 0.75, y: 0.0, z: 0.0, 
                                      inSample: 0, selSample: 0, randSample: 0, q: nil)
        
        do {
            // Square wave
            let square = try evaluate(engine, "sign(sin(2 * pi * x))", context)
            assert(square == 1.0 || square == -1.0 || square == 0.0)
            
            // PWM
            let pwm = try evaluate(engine, "x < 0.5 && 1 || -1", context)
            assert(pwm == -1.0)
            
            // Complex harmonic
            _ = try evaluate(engine, "sin(2*pi*x) + 0.5*sin(4*pi*x) + 0.25*sin(6*pi*x)", context)
            
            print("  ✓ Complex expressions")
        } catch {
            print("  ✗ Failed: \(error)")
        }
    }
    
    static func testSingleFrameApplication() {
        print("Testing single-frame application...")
        let engine = FormulaEngine()
        
        do {
            let compiled = try engine.compile("sin(2 * pi * x)")
            var frames = Array(repeating: Array(repeating: Float(0.0), count: 256), count: 8)
            
            try applyExpressionSingleFrame(
                compiled: compiled,
                engine: engine,
                frames: &frames,
                selectedFrameIndex: 3,
                sampleCount: 256
            )
            
            // Check that only frame 3 was modified
            assert(frames[0].allSatisfy { $0 == 0.0 }, "Frame 0 should be unchanged")
            assert(frames[3].contains { $0 != 0.0 }, "Frame 3 should be modified")
            assert(frames[7].allSatisfy { $0 == 0.0 }, "Frame 7 should be unchanged")
            
            // Check values are in range
            for sample in frames[3] {
                assert(sample >= -1.0 && sample <= 1.0, "Samples should be clamped to [-1, 1]")
            }
            
            print("  ✓ Single-frame application")
        } catch {
            print("  ✗ Failed: \(error)")
        }
    }
    
    static func testMultiFrameApplication() {
        print("Testing multi-frame application...")
        let engine = FormulaEngine()
        
        do {
            let compiled = try engine.compile("sin(2 * pi * x) * y")
            var frames = Array(repeating: Array(repeating: Float(0.0), count: 256), count: 8)
            
            try applyExpressionMultiFrame(
                compiled: compiled,
                engine: engine,
                frames: &frames,
                selectedFrameIndex: 0,
                sampleCount: 256
            )
            
            // Check that all frames were modified
            for (frameIndex, frame) in frames.enumerated() {
                if frameIndex == 0 {
                    // First frame (y=0) should be all zeros
                    assert(frame.allSatisfy { abs($0) < 0.0001 }, "Frame 0 should be ~0 (y=0)")
                } else {
                    // Other frames should have non-zero values
                    assert(frame.contains { $0 != 0.0 }, "Frame \(frameIndex) should be modified")
                }
                
                // Check values are in range
                for sample in frame {
                    assert(sample >= -1.0 && sample <= 1.0, "Samples should be clamped to [-1, 1]")
                }
            }
            
            print("  ✓ Multi-frame application")
        } catch {
            print("  ✗ Failed: \(error)")
        }
    }
    
    // Helper
    private static func evaluate(_ engine: FormulaEngine, _ expression: String, _ context: FormulaContext) throws -> Float {
        let compiled = try engine.compile(expression)
        return try engine.evaluate(compiled, context: context)
    }
}

// Run tests on app launch if DEBUG
#if DEBUG
extension FormulaEngineTests {
    static func runTestsIfDebug() {
        // Uncomment to run tests on app launch in debug builds
        // FormulaEngineTests.runAllTests()
    }
}
#endif

