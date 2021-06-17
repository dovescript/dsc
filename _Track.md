# Work tracker

## dsc

### Semantics subpackage

- [x] Context
- [x] Context statics
- [x] Symbol factory
- [x] Names
- [x] Slot
  - [x] Variable slot
  - [x] Virtual slot
  - [x] Method slot
- [x] Meta data
- [x] Namespace set
- [x] Method signature
- [x] Operator
- [x] Scope chain
- [x] Value
  - [x] This
  - [x] This class
  - [x] Constant
    - [x] undefined constant
    - [x] null constant
    - [x] Reserved namespace constant
    - [x] Explicit namespace constant
    - [x] String constant
    - [x] Boolean constant
    - [x] Number constant
    - [x] BigInt constant
    - [x] Char constant
    - [x] Enum constant
  - [x] Object value (indicates the object it was defined in)
    - [x] Frame
      - [x] class
      - [x] enum
      - [x] interface
      - [x] package
      - [x] Namespace object frame
      - [x] Activation
      - [x] with
    - [x] Type
      - [x] \*
      - [x] void
      - [x] null
      - [x] Class
      - [x] Enum
      - [x] Interface
      - [x] Instantiated type
      - [x] Nullable
      - [x] Nullable plus
      - [x] Tuple
      - [x] Type parameter
    - [x] Package
    - [x] Delegate
  - [x] ReferenceValue
  - [x] DynamicReferenceValue
  - [x] PropertyProxyReferenceValue
  - [x] AttributeProxyReferenceValue
  - [x] TupleElement
  - [x] Descendants
  - [x] IncompatibleOperandsLogic (special result of logical and/or)
  - [x] ConversionValue (byAsOperator?)
  - [x] Conversion enum

## Differences from previous version

- No parameterized type, with the exception of Observable and Promise.
- Any parameterized class is final.
- Untyped rest parameter in functions.
- Only tuples as structural types.
- Enum manipulation changes. For flags you use `e.set('foo')`, `e.exclude('foo')`, `e.toggle('foo')`, `e.filter(['foo', 'bar'])`, `'foo' in e` and `e = ['foo', 'bar'];`.

### Parsing subpackage

### Verifying subpackage

- [x] Directives
  - [x] Import
  - [x] Include
  - [x] Use namespace
  - [x] Use default namespace
- [x] Definitions
  - [x] Class
  - [x] Enum
  - [x] Function
  - [x] Interface
  - [x] Namespace
  - [x] Object
  - [x] Type
  - [x] Var
- [x] Destructuring patterns
  - [x] Support for transforming variables into Observable.\<T> variables.
- [x] Statements
  - [x] Block
  - [x] Break
  - [x] Continue
  - [x] Do
  - [x] Default XML namespace
  - [x] Empty
  - [x] Expression
  - [x] For
  - [x] For..in
  - [x] If
  - [x] Labeled
  - [x] Return
  - [x] Super
  - [x] Switch
  - [x] Switch type
  - [x] Throw
  - [x] Try
  - [x] While
  - [x] With
- [x] Type expressions
  - [x] Lexical reference
  - [x] \*
  - [x] Dot operator
  - [x] Type arguments
  - [x] ? operator
  - [x] + operator
  - [x] Tuple
  - [x] Void
- [x] Constant expressions
  - [x] QualifiedIdNode
  - [x] DotNode
  - [x] ArrayLiteralNode
    - [x] When expected type is flags enum, when there is no spread operator and when every element converts to an E constant.
  - [x] BinaryOperatorNode
  - [x] BooleanLiteralNode
  - [x] NullLiteralNode
  - [x] NumericLiteralNode
  - [x] ParenExpressionNode
  - [x] ReservedNamespaceNode
  - [x] StringLiteralNode
  - [x] UnaryOperatorNode
- [x] Expressions
  - [x] Lexical reference
  - [x] Dot operator
  - [x] Brackets operator
  - [x] Assignment operator
    - [x] left:ArrayLiteralNode
    - [x] left:ObjectLiteralNode
    - [x] Write to compile-time Observable.\<T> with T
  - [x] Call operator
  - [x] ArrayLiteralNode
  - [x] BinaryOperatorNode
  - [x] BooleanLiteralNode
  - [x] DescendantsNode
  - [x] EmbedExpressionNode
  - [x] FunctionExpressionNode
  - [x] ListExpressionNode
  - [x] NewOperatorNode
  - [x] NullableTypeNode
  - [x] NullLiteralNode
  - [x] NumericLiteralNode
  - [x] ObjectLiteralNode
  - [x] ParenExpressionNode
  - [x] RegExpLiteralNode
  - [x] ReservedNamespaceNode
  - [x] StringLiteralNode
  - [x] SuperNode
  - [x] TernaryNode
  - [x] ThisLiteralNode
  - [x] TypeArgumentsNode
  - [x] TypeOperatorNode
  - [x] UnaryOperatorNode
  - [x] XMLListNode
  - [x] XMLNode

### DSDoc work

- Pages
  - [ ] Overview
  - [ ] Package details
  - [ ] Class details
- Tags
  - [ ] @constructor
  - [ ] @copy
  - [ ] @description
  - [ ] @example
  - [ ] @hidden
  - [ ] @method
  - [ ] @param
  - [ ] @return
  - [ ] @throws

### Verifier special cases

- [ ] `for each (var i in Range(from, to)) [action];`: _i_ is auto Number typed.

### Platform export

- Expression treatment
  - [ ] Treat myObservable as myObservable.value
  - [ ] Treat `(myObservable as is)` as myObservable (not reading myObservable.value).
  - [ ] Assignment expression where one of the base objects is a Observable variable slot reference should post-invoke the method `observable.dispatchUpdate()`.
- Special behavior
- [ ] Range optimization:
  - [ ] `for each` iteration
  - [ ] `in` operation
    - [ ] `cv in Range('a-z')`

### Bytecode work

- [ ] BytecodeArray
  - Should extend ByteArray and define 'read' and 'write' methods for the bytecode format.
- [ ] SemanticToBytecodeMapping
- [ ] BytecodeToSemanticMapping
- Type resolution deferreds
  - Type resolution at bytecode should be familiar to the AST symbol solver.
  - [ ] Enum special methods
- [ ] How 'this' is stored at activations:
  - In constructor definition, 'this' is not a local.
  - In methods, 'this' is a local and copied to sub-activations.