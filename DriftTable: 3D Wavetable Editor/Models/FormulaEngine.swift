//
//  FormulaEngine.swift
//  DriftTable
//
//  Math expression parser and evaluator for wavetable generation
//

import Foundation

// MARK: - Public Types

enum FormulaError: Error {
    case parseError(String)
    case evaluationError(String)
}

struct FormulaContext {
    var x: Float
    var w: Float
    var y: Float
    var z: Float
    var inSample: Float
    var selSample: Float
    var randSample: Float
    var q: Int?
}

struct CompiledExpression {
    let ast: ASTNode
    let usesY: Bool
    let usesZ: Bool
    
    var usesFrameVariables: Bool {
        return usesY || usesZ
    }
}

// MARK: - AST Node Types

enum ASTNode {
    case number(Float)
    case variable(String)
    case unaryOp(UnaryOperator, Box<ASTNode>)
    case binaryOp(BinaryOperator, Box<ASTNode>, Box<ASTNode>)
    case functionCall(String, [ASTNode])
}

enum UnaryOperator: String {
    case negate = "-"
    case logicalNot = "!"
}

enum BinaryOperator: String {
    case add = "+"
    case subtract = "-"
    case multiply = "*"
    case divide = "/"
    case power = "^"
    case lessThan = "<"
    case greaterThan = ">"
    case lessEqual = "<="
    case greaterEqual = ">="
    case equal = "=="
    case notEqual = "!="
    case logicalAnd = "&&"
    case logicalOr = "||"
    
    var precedence: Int {
        switch self {
        case .logicalOr: return 1
        case .logicalAnd: return 2
        case .equal, .notEqual: return 3
        case .lessThan, .greaterThan, .lessEqual, .greaterEqual: return 4
        case .add, .subtract: return 5
        case .multiply, .divide: return 6
        case .power: return 7
        }
    }
    
    var isRightAssociative: Bool {
        return self == .power
    }
}

// Box helper for recursive enum
class Box<T> {
    let value: T
    init(_ value: T) { self.value = value }
}

// MARK: - Token Types

enum Token {
    case number(Float)
    case identifier(String)
    case op(String)
    case leftParen
    case rightParen
    case comma
}

// MARK: - Formula Engine

final class FormulaEngine {
    
    // MARK: - Constants
    
    private let constants: [String: Float] = [
        "pi": Float.pi,
        "e": Float(M_E)
    ]
    
    // MARK: - Public API
    
    func compile(_ source: String) throws -> CompiledExpression {
        let tokens = try tokenize(source)
        let ast = try parse(tokens)
        let (usesY, usesZ) = analyzeVariableUsage(ast)
        return CompiledExpression(ast: ast, usesY: usesY, usesZ: usesZ)
    }
    
    func evaluate(_ compiled: CompiledExpression, context: FormulaContext) throws -> Float {
        return try evaluateNode(compiled.ast, context: context)
    }
    
    func usesFrameVariables(_ compiled: CompiledExpression) -> Bool {
        return compiled.usesFrameVariables
    }
    
    // MARK: - Tokenization
    
    private func tokenize(_ source: String) throws -> [Token] {
        var tokens: [Token] = []
        var index = source.startIndex
        
        while index < source.endIndex {
            let char = source[index]
            
            // Skip whitespace
            if char.isWhitespace {
                index = source.index(after: index)
                continue
            }
            
            // Numbers
            if char.isNumber || char == "." {
                var numStr = ""
                while index < source.endIndex {
                    let c = source[index]
                    if c.isNumber || c == "." {
                        numStr.append(c)
                        index = source.index(after: index)
                    } else {
                        break
                    }
                }
                guard let num = Float(numStr) else {
                    throw FormulaError.parseError("Invalid number: \(numStr)")
                }
                tokens.append(.number(num))
                continue
            }
            
            // Identifiers (variables, functions, constants)
            if char.isLetter || char == "_" {
                var ident = ""
                while index < source.endIndex {
                    let c = source[index]
                    if c.isLetter || c.isNumber || c == "_" {
                        ident.append(c)
                        index = source.index(after: index)
                    } else {
                        break
                    }
                }
                tokens.append(.identifier(ident))
                continue
            }
            
            // Operators and punctuation
            switch char {
            case "(":
                tokens.append(.leftParen)
                index = source.index(after: index)
            case ")":
                tokens.append(.rightParen)
                index = source.index(after: index)
            case ",":
                tokens.append(.comma)
                index = source.index(after: index)
            case "+", "-", "*", "/", "^":
                tokens.append(.op(String(char)))
                index = source.index(after: index)
            case "<", ">", "=", "!":
                // Handle multi-character operators
                var opStr = String(char)
                index = source.index(after: index)
                if index < source.endIndex && source[index] == "=" {
                    opStr.append("=")
                    index = source.index(after: index)
                }
                tokens.append(.op(opStr))
            case "&":
                // Handle &&
                index = source.index(after: index)
                if index < source.endIndex && source[index] == "&" {
                    tokens.append(.op("&&"))
                    index = source.index(after: index)
                } else {
                    throw FormulaError.parseError("Invalid operator '&' (did you mean '&&'?)")
                }
            case "|":
                // Handle ||
                index = source.index(after: index)
                if index < source.endIndex && source[index] == "|" {
                    tokens.append(.op("||"))
                    index = source.index(after: index)
                } else {
                    throw FormulaError.parseError("Invalid operator '|' (did you mean '||'?)")
                }
            default:
                throw FormulaError.parseError("Unexpected character: \(char)")
            }
        }
        
        return tokens
    }
    
    // MARK: - Parsing (Recursive Descent)
    
    private func parse(_ tokens: [Token]) throws -> ASTNode {
        var position = 0
        let result = try parseExpression(tokens, position: &position, minPrecedence: 0)
        if position < tokens.count {
            throw FormulaError.parseError("Unexpected tokens after expression")
        }
        return result
    }
    
    private func parseExpression(_ tokens: [Token], position: inout Int, minPrecedence: Int) throws -> ASTNode {
        var left = try parsePrimary(tokens, position: &position)
        
        while position < tokens.count {
            guard case .op(let opStr) = tokens[position],
                  let op = BinaryOperator(rawValue: opStr) else {
                break
            }
            
            if op.precedence < minPrecedence {
                break
            }
            
            position += 1
            let nextMinPrecedence = op.isRightAssociative ? op.precedence : op.precedence + 1
            let right = try parseExpression(tokens, position: &position, minPrecedence: nextMinPrecedence)
            left = .binaryOp(op, Box(left), Box(right))
        }
        
        return left
    }
    
    private func parsePrimary(_ tokens: [Token], position: inout Int) throws -> ASTNode {
        guard position < tokens.count else {
            throw FormulaError.parseError("Unexpected end of expression")
        }
        
        let token = tokens[position]
        
        switch token {
        case .number(let value):
            position += 1
            return .number(value)
            
        case .identifier(let name):
            position += 1
            
            // Check if it's a function call
            if position < tokens.count, case .leftParen = tokens[position] {
                position += 1 // consume '('
                var args: [ASTNode] = []
                
                // Parse arguments
                if position < tokens.count, case .rightParen = tokens[position] {
                    // No arguments
                    position += 1
                    return .functionCall(name, args)
                }
                
                repeat {
                    let arg = try parseExpression(tokens, position: &position, minPrecedence: 0)
                    args.append(arg)
                    
                    if position < tokens.count {
                        if case .comma = tokens[position] {
                            position += 1
                            continue
                        } else if case .rightParen = tokens[position] {
                            position += 1
                            break
                        } else {
                            throw FormulaError.parseError("Expected ',' or ')' in function call")
                        }
                    } else {
                        throw FormulaError.parseError("Unclosed function call")
                    }
                } while true
                
                return .functionCall(name, args)
            }
            
            // Variable or constant
            return .variable(name)
            
        case .op(let opStr):
            // Unary operators
            if opStr == "-" {
                position += 1
                let operand = try parsePrimary(tokens, position: &position)
                return .unaryOp(.negate, Box(operand))
            } else if opStr == "!" {
                position += 1
                let operand = try parsePrimary(tokens, position: &position)
                return .unaryOp(.logicalNot, Box(operand))
            } else {
                throw FormulaError.parseError("Unexpected operator: \(opStr)")
            }
            
        case .leftParen:
            position += 1
            let expr = try parseExpression(tokens, position: &position, minPrecedence: 0)
            guard position < tokens.count, case .rightParen = tokens[position] else {
                throw FormulaError.parseError("Expected ')'")
            }
            position += 1
            return expr
            
        default:
            throw FormulaError.parseError("Unexpected token")
        }
    }
    
    // MARK: - Variable Analysis
    
    private func analyzeVariableUsage(_ node: ASTNode) -> (usesY: Bool, usesZ: Bool) {
        var usesY = false
        var usesZ = false
        
        func visit(_ n: ASTNode) {
            switch n {
            case .number:
                break
            case .variable(let name):
                if name == "y" { usesY = true }
                if name == "z" { usesZ = true }
            case .unaryOp(_, let operand):
                visit(operand.value)
            case .binaryOp(_, let left, let right):
                visit(left.value)
                visit(right.value)
            case .functionCall(_, let args):
                for arg in args {
                    visit(arg)
                }
            }
        }
        
        visit(node)
        return (usesY, usesZ)
    }
    
    // MARK: - Evaluation
    
    private func evaluateNode(_ node: ASTNode, context: FormulaContext) throws -> Float {
        switch node {
        case .number(let value):
            return value
            
        case .variable(let name):
            return try resolveVariable(name, context: context)
            
        case .unaryOp(let op, let operand):
            let value = try evaluateNode(operand.value, context: context)
            switch op {
            case .negate:
                return -value
            case .logicalNot:
                return value == 0.0 ? 1.0 : 0.0
            }
            
        case .binaryOp(let op, let left, let right):
            let leftVal = try evaluateNode(left.value, context: context)
            
            // Short-circuit evaluation for logical operators
            if op == .logicalAnd {
                if leftVal == 0.0 { return 0.0 }
                let rightVal = try evaluateNode(right.value, context: context)
                return (rightVal != 0.0) ? 1.0 : 0.0
            }
            if op == .logicalOr {
                if leftVal != 0.0 { return 1.0 }
                let rightVal = try evaluateNode(right.value, context: context)
                return (rightVal != 0.0) ? 1.0 : 0.0
            }
            
            let rightVal = try evaluateNode(right.value, context: context)
            return try evaluateBinaryOp(op, leftVal, rightVal)
            
        case .functionCall(let name, let args):
            let argValues = try args.map { try evaluateNode($0, context: context) }
            return try evaluateFunction(name, args: argValues)
        }
    }
    
    private func resolveVariable(_ name: String, context: FormulaContext) throws -> Float {
        // Check constants first
        if let constant = constants[name] {
            return constant
        }
        
        // Check context variables
        switch name {
        case "x": return context.x
        case "w": return context.w
        case "y": return context.y
        case "z": return context.z
        case "in": return context.inSample
        case "sel": return context.selSample
        case "rand": return context.randSample
        case "q":
            if let q = context.q {
                return Float(q)
            } else {
                return 0.0 // Default if q not provided
            }
        default:
            throw FormulaError.evaluationError("Unknown variable: \(name)")
        }
    }
    
    private func evaluateBinaryOp(_ op: BinaryOperator, _ left: Float, _ right: Float) throws -> Float {
        switch op {
        case .add:
            return left + right
        case .subtract:
            return left - right
        case .multiply:
            return left * right
        case .divide:
            guard right != 0.0 else {
                return 0.0 // Safe fallback for division by zero
            }
            return left / right
        case .power:
            let result = pow(left, right)
            return result.isNaN || result.isInfinite ? 0.0 : result
        case .lessThan:
            return left < right ? 1.0 : 0.0
        case .greaterThan:
            return left > right ? 1.0 : 0.0
        case .lessEqual:
            return left <= right ? 1.0 : 0.0
        case .greaterEqual:
            return left >= right ? 1.0 : 0.0
        case .equal:
            return abs(left - right) < 1e-6 ? 1.0 : 0.0
        case .notEqual:
            return abs(left - right) >= 1e-6 ? 1.0 : 0.0
        case .logicalAnd, .logicalOr:
            // Already handled in evaluateNode with short-circuit
            fatalError("Should not reach here")
        }
    }
    
    private func evaluateFunction(_ name: String, args: [Float]) throws -> Float {
        let safeGuard: (Float) -> Float = { value in
            return value.isNaN || value.isInfinite ? 0.0 : value
        }
        
        switch name {
        // Trigonometric
        case "sin":
            guard args.count == 1 else { throw FormulaError.evaluationError("sin expects 1 argument") }
            return sin(args[0])
        case "cos":
            guard args.count == 1 else { throw FormulaError.evaluationError("cos expects 1 argument") }
            return cos(args[0])
        case "tan":
            guard args.count == 1 else { throw FormulaError.evaluationError("tan expects 1 argument") }
            return safeGuard(tan(args[0]))
        case "asin":
            guard args.count == 1 else { throw FormulaError.evaluationError("asin expects 1 argument") }
            return safeGuard(asin(args[0]))
        case "acos":
            guard args.count == 1 else { throw FormulaError.evaluationError("acos expects 1 argument") }
            return safeGuard(acos(args[0]))
        case "atan":
            guard args.count == 1 else { throw FormulaError.evaluationError("atan expects 1 argument") }
            return atan(args[0])
            
        // Hyperbolic
        case "sinh":
            guard args.count == 1 else { throw FormulaError.evaluationError("sinh expects 1 argument") }
            return safeGuard(sinh(args[0]))
        case "cosh":
            guard args.count == 1 else { throw FormulaError.evaluationError("cosh expects 1 argument") }
            return safeGuard(cosh(args[0]))
        case "tanh":
            guard args.count == 1 else { throw FormulaError.evaluationError("tanh expects 1 argument") }
            return tanh(args[0])
        case "asinh":
            guard args.count == 1 else { throw FormulaError.evaluationError("asinh expects 1 argument") }
            return safeGuard(asinh(args[0]))
        case "acosh":
            guard args.count == 1 else { throw FormulaError.evaluationError("acosh expects 1 argument") }
            return safeGuard(acosh(args[0]))
        case "atanh":
            guard args.count == 1 else { throw FormulaError.evaluationError("atanh expects 1 argument") }
            return safeGuard(atanh(args[0]))
            
        // Logarithms and exponentials
        case "log2":
            guard args.count == 1 else { throw FormulaError.evaluationError("log2 expects 1 argument") }
            guard args[0] > 0 else { return 0.0 }
            return log2(args[0])
        case "log10", "log":
            guard args.count == 1 else { throw FormulaError.evaluationError("\(name) expects 1 argument") }
            guard args[0] > 0 else { return 0.0 }
            return log10(args[0])
        case "ln":
            guard args.count == 1 else { throw FormulaError.evaluationError("ln expects 1 argument") }
            guard args[0] > 0 else { return 0.0 }
            return log(args[0])
        case "exp":
            guard args.count == 1 else { throw FormulaError.evaluationError("exp expects 1 argument") }
            return safeGuard(exp(args[0]))
        case "sqrt":
            guard args.count == 1 else { throw FormulaError.evaluationError("sqrt expects 1 argument") }
            guard args[0] >= 0 else { return 0.0 }
            return sqrt(args[0])
            
        // Other math functions
        case "sign":
            guard args.count == 1 else { throw FormulaError.evaluationError("sign expects 1 argument") }
            if args[0] > 0 { return 1.0 }
            if args[0] < 0 { return -1.0 }
            return 0.0
        case "rint":
            guard args.count == 1 else { throw FormulaError.evaluationError("rint expects 1 argument") }
            return round(args[0])
        case "abs":
            guard args.count == 1 else { throw FormulaError.evaluationError("abs expects 1 argument") }
            return abs(args[0])
            
        // Multi-argument functions
        case "min":
            guard !args.isEmpty else { throw FormulaError.evaluationError("min expects at least 1 argument") }
            return args.min() ?? 0.0
        case "max":
            guard !args.isEmpty else { throw FormulaError.evaluationError("max expects at least 1 argument") }
            return args.max() ?? 0.0
        case "sum":
            guard !args.isEmpty else { throw FormulaError.evaluationError("sum expects at least 1 argument") }
            return args.reduce(0.0, +)
        case "avg":
            guard !args.isEmpty else { throw FormulaError.evaluationError("avg expects at least 1 argument") }
            return args.reduce(0.0, +) / Float(args.count)
            
        default:
            throw FormulaError.evaluationError("Unknown function: \(name)")
        }
    }
}

