# Verification result

The result for verifying nodes is assigned to `[object Verifier].result`. The symbol for a node can be obtained through `[object Verifier].result.symbolOf(node)`, in which case the `[object Verifier].result` **MUST** have, on top of its stack, the correct `Script` object. Append or pop a `Script` from the stack by using the `[object VerificationResult].enterScript()` and `[object VerificationResult].exitScript()` methods.

### Enums

Every constant definition fills `[object VariableSlot].enumPairAssociation` with (`String`,  `AnyRangeNumber`).

### Destructuring patterns

- `ArrayLiteralNode` and `ObjectLiteralNode` are associated to object references.
- `TypedIdNode`, `SimpleIdNode` and `ObjectFieldNode` are associated to `TargetAndValue` symbols. In `TypedIdNode` and declarative `SimpleIdNode`, the target of the `TargetAndValue` symbol is a variable slot. In assignment `SimpleIdNode`, the target of the `TargetAndValue` symbol is a reference value.
- Spread operator is currently unallowed at object destructuring pattern.
- Spread operator at array destructuring pattern always assigns an `Array` object, independent of type.

### Functions

- `RestParamNode` is associated to a variable slot.