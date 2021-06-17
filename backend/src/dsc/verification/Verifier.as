package dsc.verification {
    import dsc.*;
    import dsc.parsing.*;
    import dsc.parsing.ast.*;
    import dsc.semantics.*;
    import dsc.semantics.accessErrors.*;
    import dsc.semantics.constants.*;
    import dsc.semantics.frames.*;
    import dsc.semantics.types.*;
    import dsc.semantics.values.*;
    import dsc.util.*;

    import flash.utils.Dictionary;
    import com.hurlant.math.BigInteger;

    public final class Verifier {
        private var _compilerOptions:CompilerOptions;
        public const result:VerificationResult = new VerificationResult;
        public const problems:Array = [];
        public const semanticContext:Context = new Context;
        public var scopeChain:ScopeChain;
        private var _invalidated:Boolean;
        private const _scriptStack:Array = [];
        private const _openedFunctions:Array = [];
        private var _openedFunction:OpenedFunction;

        public function Verifier(compilerOptions:CompilerOptions = undefined) {
            _compilerOptions = compilerOptions || new CompilerOptions;
            scopeChain = new ScopeChain(semanticContext);

            var rootFrame:Symbol = semanticContext.factory.frame();
            rootFrame.importPackage(semanticContext.statics.topPackage);
            rootFrame.importPackage(semanticContext.statics.dsGlobalPackage);
            scopeChain.enterFrame(rootFrame);
        }

        public function get invalidated():Boolean { return _invalidated }

        public function get compilerOptions():CompilerOptions { return _compilerOptions }
        public function set compilerOptions(options:CompilerOptions):void { _compilerOptions = options }

        public function get currentScript():Script { return _scriptStack.length == 0 ? null : _scriptStack[_scriptStack.length - 1] }
        public function get currentActivation():Symbol { return _openedFunction ? _openedFunction.activation : undefined }

        public function reportSyntaxError(errorId:String, span:Span, variables:* = undefined):void { problems.push(new Problem(errorId, 'syntaxError', new SourceLocation(_scriptStack[_scriptStack.length - 1], span), variables)), _invalidated = true }
        public function reportVerifyError(errorId:String, span:Span, variables:* = undefined):void { problems.push(new Problem(errorId, 'verifyError', new SourceLocation(_scriptStack[_scriptStack.length - 1], span), variables)), _invalidated = true }
        public function warn(errorId:String, span:Span, variables:* = undefined):void { problems.push(new Problem(errorId, 'warning', new SourceLocation(_scriptStack[_scriptStack.length - 1], span), variables)) }

        public function enterScript(script:Script):void { _scriptStack.push(script), result.enterScript(script) }
        public function exitScript():void { _scriptStack.pop(), result.exitScript() }

        public function enterFunction(activation:Symbol, methodSlot:Symbol, commonNode:FunctionCommonNode):void {
            var opened:OpenedFunction = new OpenedFunction(activation, methodSlot, commonNode);
            _openedFunctions.push(opened), _openedFunction = opened;
        }

        public function exitFunction():void { _openedFunctions.pop(), _openedFunction = _openedFunctions.length == 0 ? undefined : _openedFunctions[_openedFunctions.length - 1] }

        private function nodeIsAlreadyVerified(node:Node):Boolean { return result.nodeIsAlreadyVerified(node) }

        /**
         * Resolves a QualifiedIdentifier as a property operator.
         */
        public function resolveReference(object:Symbol, id:QualifiedIdNode, context:VerificationContext):Symbol {
            var p:Symbol, qual:Symbol, qname:Symbol, str:String, simpleId:SimpleIdNode, expressionId:ExpressionIdNode, attributeId:AttributeIdNode;
            var flags:uint = context.flags, reportError:Boolean = context.reportConstantExpressionErrors;

            if (object.valueType is VoidType) { if (reportError) reportVerifyError('verifyErrors.cannotAccessPropertyOfUndefined', id.span); return undefined }
            if (object.valueType is NullType) { if (reportError) reportVerifyError('verifyErrors.cannotAccessPropertyOfNull', id.span); return undefined }

            if (simpleId = id as SimpleIdNode) {
                str = simpleId.name;

                if (simpleId.qualifier) {
                    qual = verifyExpression(simpleId.qualifier);
                    qual = qual is NamespaceSet ? qual : limitType(simpleId.qualifier, semanticContext.statics.namespaceType);

                    if (!qual) return undefined;
                    if (!(qual is Constant)) p = semanticContext.factory.dynamicReferenceValue(object);
                    else if (!(qual is NamespaceSet)) qname = semanticContext.factory.name(qual, str);
                }

                p = p || ( qname ? object.resolveName(qname) : object.resolveMultiName(NamespaceSet(qual || scopeChain.nss), str) );
                p = !p && object is Package && !qname && !qual ? object.findSubpackage(object.fullyQualifiedName + '.' + str) : p;

                if (!p) {
                    p = qname ? null : object.resolveMultiName(null, str);
                    if (reportError) {
                        if (p)
                            reportVerifyError('verifyErrors.inaccessiblePropertyThroughReference', id.span, { name: qname ? qname.toString() : str, type: object is Type ? object : object.valueType });
                        else reportVerifyError('verifyErrors.undefinedPropertyThroughReference', id.span, { name: qname ? qname.toString() : str, type: object is Type ? object : object.valueType });
                    }

                    return null;
                }

                else if (p is AmbiguousReference) { if (reportError) reportVerifyError('verifyErrors.ambiguousReference', id.span, { name: qname ? qname.toString() : str }); return undefined }
            }
            else if (expressionId = id as ExpressionIdNode) {
                if (expressionId.qualifier) limitType(expressionId.qualifier, semanticContext.statics.namespaceType);

                limitType(expressionId.key, semanticContext.statics.stringType);
                p = semanticContext.factory.dynamicReferenceValue(object);
            }
            else {
                attributeId = AttributeIdNode(id);

                if (attributeId.id.qualifier) limitType(attributeId.id.qualifier, semanticContext.statics.namespaceType);
                if (attributeId.id is ExpressionIdNode) limitType(ExpressionIdNode(attributeId.id).key, semanticContext.statics.stringType);

                var attributeProxy:PropertyProxy = object.valueType.delegate.findAttributeProxyInTree();

                if (!attributeProxy) { if (reportError) reportVerifyError('verifyErrors.cannotAccessAttributeThroughReference', id.span, { type: object.valueType }); return undefined }

                p = semanticContext.factory.attributeProxyReferenceValue(object, attributeProxy);
            }

            if (p is Value && !p.valueType) return reportVerifyError('verifyErrors.unresolvedReference', id.span, { name: qname ? qname.toString() : str }), undefined;

            if (p is ReferenceValue) {

                // check bound method

                if (p.property is MethodSlot && !(flags & VerifyFlags.CALL_BASE_REFERENCE)) p.property.methodFlags |= MethodFlags.BOUND;

                // Observable manipulation

                else if (p.isObservableVariable) p.valueType = p.property.valueType.arguments[0];
            }

            // instantiate parameterized type

            else if (p is Type && p.typeParams) { var arguments:Array = []; for each (var typeParam:Symbol in p.typeParams) arguments.push(semanticContext.statics.anyType); p = semanticContext.factory.instantiatedType(p, arguments); }

            return p;
        }

        /**
         * Resolves a QualifiedIdentifier as a lexical reference.
         */
        public function resolveLexicalReference(id:QualifiedIdNode, context:VerificationContext):Symbol {
            var p:Symbol, qual:Symbol, qname:Symbol, str:String, simpleId:SimpleIdNode, expressionId:ExpressionIdNode, attributeId:AttributeIdNode, object:Symbol;
            var flags:uint = context.flags, reportError:Boolean = context.reportConstantExpressionErrors;

            if (simpleId = id as SimpleIdNode) {
                str = simpleId.name;

                var nonConstantQualifier:Boolean;

                if (simpleId.qualifier) {
                    qual = verifyExpression(simpleId.qualifier);
                    qual = qual is NamespaceSet ? qual : limitType(simpleId.qualifier, semanticContext.statics.namespaceType);

                    if (!qual) return undefined;

                    // SimpleQualifiedIdentifier with non-constant qualifier

                    if (!(qual is Constant)) {
                        object = scopeChain.currentFrame is WithFrame ? scopeChain.currentFrame.symbol : undefined;
                        object = object instanceof Value ? object : undefined;

                        if (!object) return reportVerifyError('verifyErrors.cannotResolveComputedReference', id.span), undefined;
                        p = semanticContext.factory.dynamicReferenceValue(object);
                    }

                    else if (!(qual is NamespaceSet)) qname = semanticContext.factory.name(qual, str);
                }

                p ||= qname ? scopeChain.resolveName(qname) : scopeChain.resolveMultiName(NamespaceSet(qual || scopeChain.nss), str);
                p = !p && !qname && !qual ? semanticContext.statics.topPackage.findSubpackage(str) : p;

                if (p is AmbiguousReference) { if (reportError) reportVerifyError('verifyErrors.ambiguousReference', id.span, { name: str }); return undefined; }

                if (!p) {
                    if (reportError)
                        reportVerifyError('verifyErrors.undefinedProperty', id.span, { name: qname ? qname.toString() : (qual ? qual.prefix + '::' : '') + str });
                    return null;
                }

                if (p is Value && !p.valueType) {
                    if (reportError)
                        reportVerifyError('verifyErrors.unresolvedReference', id.span, { name: qname ? qname.toString() : str });
                    return null;
                }
            }
            else if (expressionId = id as ExpressionIdNode) {
                if (expressionId.qualifier) limitType(expressionId.qualifier, semanticContext.statics.namespaceType);

                limitType(expressionId.key, semanticContext.statics.stringType);

                object = scopeChain.currentFrame is WithFrame ? scopeChain.currentFrame.symbol : undefined;
                object = object instanceof Value ? object : undefined;

                if (!object) return reportVerifyError('verifyErrors.cannotResolveComputedReference', id.span), undefined;

                p = semanticContext.factory.dynamicReferenceValue(object);
            }
            else {
                attributeId = AttributeIdNode(id);

                if (attributeId.id.qualifier) limitType(attributeId.id.qualifier, semanticContext.statics.namespaceType);

                if (attributeId.id is ExpressionIdNode) limitType(ExpressionIdNode(attributeId.id).key, semanticContext.statics.stringType);

                object = scopeChain.currentFrame is WithFrame ? scopeChain.currentFrame.symbol : undefined;
                object = object instanceof Value ? object : undefined;

                if (!object) return reportVerifyError('verifyErrors.cannotAccessAttribute', id.span), undefined;

                var attributeProxy:PropertyProxy = object.valueType.delegate.findAttributeProxyInTree();

                if (!attributeProxy) return reportVerifyError('verifyErrors.cannotAccessAttribute', id.span), undefined;

                p = semanticContext.factory.attributeProxyReferenceValue(object, attributeProxy);
            }

            if (p is ReferenceValue || p is DynamicReferenceValue || p is AttributeProxyReferenceValue || p is PropertyProxyReferenceValue) {
                // check bound method

                if (p is ReferenceValue && p.property is MethodSlot && !(flags & VerifyFlags.CALL_BASE_REFERENCE)) p.property.methodFlags |= MethodFlags.BOUND;

                // Observable manipulation

                else if (p is ReferenceValue && p.property is VariableSlot && p.property.valueType.equalsOrInstantiationOf(semanticContext.statics.observableType)) p.valueType = p.property.valueType.arguments[0];

                // check frame property capture

                if (p is ReferenceValue && p.object is Frame) { if (p.object.activation != currentActivation) p.object.activation.setScopeExtendedProperty(p.property) }

                // check 'this' capture

                else if (p.object is This) { if (p.object.activation != currentActivation) p.object.activation.setScopeExtendedProperty(p.object) }

                // code may capture property from an enclosing 'with' frame
                //
                // with (0x0a) function f():void trace(toString(16));

                else if (p.object is ReferenceValue && p.object.object is Frame) {
                    var p2:Symbol = p.object;

                    if (p2.object.activation != currentActivation) p2.object.activation.setScopeExtendedProperty(p2.property);
                }
            }

            // instantiate parameterized type

            else if (p is Type && p.typeParams) { var arguments:Array = []; for each (var typeParam:Symbol in p.typeParams) arguments.push(semanticContext.statics.anyType); p = semanticContext.factory.instantiatedType(p, arguments); }

            return p;
        }

        public function arrangeProblems(programs:Array):void {
            for each (var problem:Problem in problems) problem.location.script.collect(problem);

            for each (var program:ProgramNode in programs) _arrangeSingleScriptProblems(program.script);
        }

        private function _arrangeSingleScriptProblems(script:Script):void {
            script.sortProblemCollection();

            for each (var subscript:Script in script.includesScripts) _arrangeSingleScriptProblems(subscript);
        }

        public function verifyConstantExpression(node:ExpressionNode, context:VerificationContext = undefined):Symbol {
            context ||= new VerificationContext;

            var r:Symbol = result.symbolOf(node);

            var base:Symbol, symbol1:Symbol, symbol2:Symbol;

            if (r || nodeIsAlreadyVerified(node)) return r;

            var simpleId:SimpleIdNode, dot:DotNode, arrayLiteral:ArrayLiteralNode;

            if (simpleId = node as SimpleIdNode) {
                r = resolveLexicalReference(simpleId, context);

                if (r) r = validateConstantReference(node, r, context);
            }
            else if (dot = node as DotNode) {
                base = verifyConstantExpression(dot.base, context.clone());
 
                if (base)
                    r = resolveReference(base, dot.id, context);
                else if (!context.reportConstantExpressionErrors)
                    result.unsetSymbolOf(dot.base);

                if (r) r = validateConstantReference(node, r, context);
            }
            else if (node is BooleanLiteralNode) r = semanticContext.factory.booleanConstant(BooleanLiteralNode(node).value);

            else if (node is NumericLiteralNode) {
                r = semanticContext.factory.numberConstant(NumericLiteralNode(node).value);

                if (context.expectedType && semanticContext.isNumericType(context.expectedType)) r = r.convertConstant(context.expectedType);
            }
            else if (node is StringLiteralNode) r = verifyStringLiteral(StringLiteralNode(node), context);
            else if (node is NullLiteralNode) r = semanticContext.factory.nullConstant(context.expectedType && context.expectedType.containsNull ? context.expectedType : semanticContext.statics.nullType);
            else if (node is ReservedNamespaceNode) r = verifyReservedNamespace(ReservedNamespaceNode(node), context);
            else if (node is UnaryOperatorNode) r = verifyConstantUnaryOperator(UnaryOperatorNode(node), context);
            else if (node is BinaryOperatorNode) r = verifyConstantBinaryOperator(BinaryOperatorNode(node), context);
            else if (node is ParenExpressionNode) r = verifyConstantExpression(ParenExpressionNode(node).expression, context);
            else if (arrayLiteral = node as ArrayLiteralNode) {
                var element:ExpressionNode, arrayIsConstant:Boolean;

                if (context.expectedType && context.expectedType.escapeType() is EnumType && context.expectedType.escapeType().enumFlags & EnumFlags.FLAGS) {
                    var enumFlags:uint;

                    arrayIsConstant = true;

                    for each (element in arrayLiteral.elements) {
                        if (element is SpreadOperatorNode) { arrayIsConstant = false; continue }

                        var elementValue:Symbol = limitType(element, context.expectedType);

                        if (elementValue) {
                            if (elementValue is EnumConstant)
                                enumFlags |= elementValue.valueOf().valueOf();
                            else arrayIsConstant = false;
                        }
                    }

                    if (arrayIsConstant)
                        r = semanticContext.factory.enumConstant(new AnyRangeNumber(enumFlags), context.expectedType.escapeType());
                }

                if (!arrayIsConstant && context.reportConstantExpressionErrors) reportVerifyError('verifyErrors.notACompileTimeConstant', node.span);
            }

            else if (context.reportConstantExpressionErrors) reportVerifyError('verifyErrors.notACompileTimeConstant', node.span);

            if (r) {
                result.setSymbolOf(node, r);

                if (context.expectedType) {
                    r = r.convertConstant(context.expectedType);
                    if (r) result.setSymbolOf(node, r);
                }

                return r = result.symbolOf(node);
            }

            if (!context.reportConstantExpressionErrors)
                result.unsetSymbolOf(node);
            return null;
        }

        public function limitConstantType(node:ExpressionNode, type:Symbol):Symbol {
            var context:VerificationContext = new VerificationContext;
            context.expectedType = type;
            var r:Symbol = verifyConstantExpression(node, context);
            if (!r) return undefined;

            var conv:Symbol = r.convertConstant(type);
            if (conv) return result.setSymbolOf(node, conv), conv;
            else reportVerifyError('verifyErrors.incompatibleTypes', node.span, { expected: type, got: r.valueType });

            return result.setSymbolOf(node, null), undefined;
        }

        public function verifyNamespaceConstant(node:ExpressionNode):Symbol {
            var s:Symbol = verifyConstantExpression(node);

            if (!s || s is NamespaceConstant || s is NamespaceSet) return s;

            return reportVerifyError('verifyErrors.notANamespaceConstant', node.span), result.setSymbolOf(node, null), undefined;
        }

        private function validateConstantReference(node:ExpressionNode, symbol:Symbol, context:VerificationContext):Symbol {
            var p:Symbol;
            if (symbol is ReferenceValue && (symbol.object is Type || symbol.object is Package))
                p = symbol.property;
            else if (symbol is Constant)
                return symbol;

            if (p && p is VariableSlot && p.readOnly && p.initialValue)
                return p.initialValue;
            else if (context.reportConstantExpressionErrors)
                reportVerifyError('verifyErrors.notACompileTimeConstant', node.span);

            return null;
        }

        private function verifyStringLiteral(node:StringLiteralNode, context:VerificationContext):Symbol {
            if (context.expectedType && context.expectedType.escapeType() is EnumType) {
                var constant:Symbol = context.expectedType.escapeType().getEnumConstant(node.value);
                if (!constant && context.reportConstantExpressionErrors) reportVerifyError('verifyErrors.undefinedConstant', node.span, { name: node.value, type: context.expectedType.escapeType() });
                return constant;
            }

            return semanticContext.factory.stringConstant(node.value);
        }

        private function verifyConstantUnaryOperator(node:UnaryOperatorNode, context:VerificationContext):Symbol {
            var argument:Symbol = verifyConstantExpression(node.argument, context.clone());

            if (!argument) return undefined;

            if (node.type == Operator.VOID) return semanticContext.factory.undefinedConstant();

            // Number

            if (argument is NumberConstant) {
                if (node.type == Operator.NEGATE) return semanticContext.factory.numberConstant(-argument.valueOf());
                if (node.type == Operator.BITWISE_NOT) return semanticContext.factory.numberConstant(~argument.valueOf());
            }

            // BigInt

            else if (argument is BigIntConstant) {
                if (node.type == Operator.NEGATE) return semanticContext.factory.bigIntConstant(BigInteger(argument.valueOf()).negate());
                if (node.type == Operator.BITWISE_NOT) return semanticContext.factory.bigIntConstant(BigInteger(argument.valueOf()).not());
            }

            if (context.reportConstantExpressionErrors) reportVerifyError('verifyErrors.notACompileTimeConstant', node.span);

            return undefined;
        }

        private function verifyConstantBinaryOperator(node:BinaryOperatorNode, context:VerificationContext):Symbol {
            if (node.type == Operator.IN) return null;

            var left:Symbol = verifyConstantExpression(node.left, context.clone());
            if (!left) return null;

            var rightContext:VerificationContext = context.clone();
            rightContext.expectedType = left.valueType;
            var right:Symbol = verifyConstantExpression(node.right, rightContext);
            if (!right) return null;

            if (left is NumberConstant && right is NumberConstant) {
                if (node.type == Operator.ADD) return semanticContext.factory.numberConstant(left.valueOf() + right.valueOf(), left.valueType);
                if (node.type == Operator.SUBTRACT) return semanticContext.factory.numberConstant(left.valueOf() - right.valueOf(), left.valueType);
                if (node.type == Operator.MULTIPLY) return semanticContext.factory.numberConstant(left.valueOf() * right.valueOf(), left.valueType);
                if (node.type == Operator.DIVIDE) return semanticContext.factory.numberConstant(left.valueOf() / right.valueOf(), left.valueType);
                if (node.type == Operator.REMAINDER) return semanticContext.factory.numberConstant(left.valueOf() % right.valueOf(), left.valueType);
                if (node.type == Operator.BITWISE_AND) return semanticContext.factory.numberConstant(left.valueOf() & right.valueOf(), left.valueType);
                if (node.type == Operator.BITWISE_XOR) return semanticContext.factory.numberConstant(left.valueOf() ^ right.valueOf(), left.valueType);
                if (node.type == Operator.BITWISE_OR) return semanticContext.factory.numberConstant(left.valueOf() | right.valueOf(), left.valueType);
                if (node.type == Operator.LEFT_SHIFT) return semanticContext.factory.numberConstant(left.valueOf() << right.valueOf(), left.valueType);
                if (node.type == Operator.RIGHT_SHIFT) return semanticContext.factory.numberConstant(left.valueOf() >> right.valueOf(), left.valueType);
                if (node.type == Operator.UNSIGNED_RIGHT_SHIFT) return semanticContext.factory.numberConstant(left.valueOf() >>> right.valueOf(), left.valueType);
                if (node.type == Operator.EQUALS) return semanticContext.factory.booleanConstant(left.valueOf() == right.valueOf());
                if (node.type == Operator.NOT_EQUALS) return semanticContext.factory.booleanConstant(left.valueOf() != right.valueOf());
                if (node.type == Operator.LT) return semanticContext.factory.booleanConstant(left.valueOf() < right.valueOf());
                if (node.type == Operator.GT) return semanticContext.factory.booleanConstant(left.valueOf() > right.valueOf());
                if (node.type == Operator.LE) return semanticContext.factory.booleanConstant(left.valueOf() <= right.valueOf());
                if (node.type == Operator.GE) return semanticContext.factory.booleanConstant(left.valueOf() >= right.valueOf());
            }

            else if (left is BigIntConstant && right is BigIntConstant) {
                if (node.type == Operator.ADD) return semanticContext.factory.bigIntConstant(BigInteger(left.valueOf()).add(right.valueOf()), left.valueType);
                if (node.type == Operator.SUBTRACT) return semanticContext.factory.bigIntConstant(BigInteger(left.valueOf()).subtract(right.valueOf()), left.valueType);
                if (node.type == Operator.MULTIPLY) return semanticContext.factory.bigIntConstant(BigInteger(left.valueOf()).multiply(right.valueOf()), left.valueType);
                if (node.type == Operator.DIVIDE) return semanticContext.factory.bigIntConstant(BigInteger(left.valueOf()).divide(right.valueOf()), left.valueType);
                if (node.type == Operator.REMAINDER) return semanticContext.factory.bigIntConstant(BigInteger(left.valueOf()).remainder(right.valueOf()), left.valueType);
                if (node.type == Operator.BITWISE_AND) return semanticContext.factory.bigIntConstant(BigInteger(left.valueOf()).and(right.valueOf()), left.valueType);
                if (node.type == Operator.BITWISE_XOR) return semanticContext.factory.bigIntConstant(BigInteger(left.valueOf()).xor(right.valueOf()), left.valueType);
                if (node.type == Operator.BITWISE_OR) return semanticContext.factory.bigIntConstant(BigInteger(left.valueOf()).or(right.valueOf()), left.valueType);
                if (node.type == Operator.LEFT_SHIFT) return semanticContext.factory.bigIntConstant(BigInteger(left.valueOf()).shiftLeft(right.valueOf()), left.valueType);
                if (node.type == Operator.RIGHT_SHIFT) return semanticContext.factory.bigIntConstant(BigInteger(left.valueOf()).shiftRight(right.valueOf()), left.valueType);
                if (node.type == Operator.EQUALS) return semanticContext.factory.booleanConstant(BigInteger(left.valueOf()).equals(right.valueOf()));
                if (node.type == Operator.NOT_EQUALS) return semanticContext.factory.booleanConstant(!BigInteger(left.valueOf()).equals(right.valueOf()));
                if (node.type == Operator.LT) return semanticContext.factory.booleanConstant(BigInteger(left.valueOf()).compareTo(right.valueOf()) < 0);
                if (node.type == Operator.GT) return semanticContext.factory.booleanConstant(BigInteger(left.valueOf()).compareTo(right.valueOf()) > 0);
                if (node.type == Operator.LE) return semanticContext.factory.booleanConstant(BigInteger(left.valueOf()).compareTo(right.valueOf()) <= 0);
                if (node.type == Operator.GE) return semanticContext.factory.booleanConstant(BigInteger(left.valueOf()).compareTo(right.valueOf()) >= 0);
            }

            else if (left is BooleanConstant && right is BooleanConstant) {
                if (node.type == Operator.LOGICAL_AND) return semanticContext.factory.booleanConstant(left.valueOf() && right.valueOf(), left.valueType);
                if (node.type == Operator.LOGICAL_OR) return semanticContext.factory.booleanConstant(left.valueOf() || right.valueOf(), left.valueType);
            }

            else if (left is StringConstant && right is StringConstant) {
                if (node.type == Operator.ADD) return semanticContext.factory.stringConstant(left.valueOf() + right.valueOf(), left.valueType);
            }

            if (context.reportConstantExpressionErrors) reportVerifyError('verifyErrors.notACompileTimeConstant', node.span);

            return undefined;
        }

        private function verifyReservedNamespace(node:ReservedNamespaceNode, context:VerificationContext):Symbol {
            var ns:Symbol = scopeChain.getLexicalReservedNamespace(node.type);

            if (!ns) { if (context.reportConstantExpressionErrors) reportVerifyError('verifyErrors.reservedNamespaceNotAvailable', node.span, { type: node.type }); return undefined }

            return ns;
        }

        public function verifyDirectives(list:Array, context:VerificationContext = undefined):void {
            context ||= new VerificationContext;

            if (!context.phase) {
                var pd:PhaseDistributor = new PhaseDistributor(this);

                while (pd.hasRemaining) pd.verify(list), pd.nextPhase();

                return;
            }

            for each (var directive:DirectiveNode in list) {
                if (directive is StatementNode && context.phase == VerificationPhase.OMEGA)
                    verifyStatement(StatementNode(directive));
                else if (directive is ClassDefinitionNode)
                    verifyClassDefinition(ClassDefinitionNode(directive), context);
                else if (directive is EnumDefinitionNode)
                    verifyEnumDefinition(EnumDefinitionNode(directive), context);
                else if (directive is ObjectDefinitionNode)
                    verifyObjectDefinition(ObjectDefinitionNode(directive), context);
                else if (directive is InterfaceDefinitionNode)
                    verifyInterfaceDefinition(InterfaceDefinitionNode(directive), context);
                else if (directive is VarDefinitionNode)
                    verifyVarDefinition(VarDefinitionNode(directive), context);
                else if (directive is FunctionDefinitionNode)
                    verifyFunctionDefinition(FunctionDefinitionNode(directive), context);
                else if (directive is NamespaceDefinitionNode)
                    verifyNamespaceDefinition(NamespaceDefinitionNode(directive), context);
                else if (directive is TypeDefinitionNode)
                    verifyTypeDefinition(TypeDefinitionNode(directive), context);
                else if (directive is ImportDirectiveNode)
                    verifyImportDirective(ImportDirectiveNode(directive), context);
                else if (directive is UseDirectiveNode && context.phase == VerificationPhase.DECLARATION_1)
                    verifyUseDirective(UseDirectiveNode(directive));
                else if (directive is UseDefaultDirectiveNode && context.phase == VerificationPhase.DECLARATION_1)
                    verifyUseDefaultDirective(UseDefaultDirectiveNode(directive));
                else if (directive is IncludeDirectiveNode) {
                    var includeDirective:IncludeDirectiveNode = IncludeDirectiveNode(directive);

                    enterScript(includeDirective.subscript);

                    if (includeDirective.subdirectives) verifyDirectives(includeDirective.subdirectives, context);

                    exitScript();
                }
            }
        }

        public function resolveDefinitionQualifier(definition:DefinitionNode):Symbol {
            if (!definition.accessModifier) return scopeChain.currentFrame.defaultNamespace;

            var q:Symbol = verifyNamespaceConstant(definition.accessModifier);

            if (!q) return undefined;
            if (q is NamespaceSet) q = semanticContext.factory.explicitNamespaceConstant(q.prefix, undefined);
            if (scopeChain.currentFrame is Activation && !(q is ReservedNamespaceConstant && q.namespaceType == 'internal')) reportVerifyError('verifyErrors.accessModifierNotAllowedHere', definition.accessModifier.span);

            return q;
        }

        public function nameCollectionOfDefinition(definition:DefinitionNode):Names {
            if (definition.modifiers & Modifiers.STATIC)
                return scopeChain.currentFrame.symbol.names;

            if (scopeChain.currentFrame.symbol) {
                if (scopeChain.currentFrame.symbol is Type)
                    return scopeChain.currentFrame.symbol.delegate.names;
                if (scopeChain.currentFrame.symbol is ObjectValue)
                    return scopeChain.currentFrame.symbol.names;
            }

            return scopeChain.currentFrame.names;
        }

        private function verifyNamespaceDefinition(definition:NamespaceDefinitionNode, context:VerificationContext):void {
            switch (context.phase) {

            case VerificationPhase.DECLARATION_1:

                var qual:Symbol = resolveDefinitionQualifier(definition);

                if (!qual) return;

                var assignedNS:Symbol;

                if (definition.expression) {
                    var stringLiteral:StringLiteralNode = definition.expression as StringLiteralNode;

                    if (stringLiteral) {
                        var pckg:Symbol = stringLiteral.value.indexOf(':') == -1 ? semanticContext.statics.topPackage.findSubpackage(stringLiteral.value) : undefined;
                        assignedNS = pckg ? pckg.toRecursiveNamespaceSet(definition.name) : semanticContext.factory.explicitNamespaceConstant(definition.name, stringLiteral.value);
                    }
                    else assignedNS = verifyNamespaceConstant(definition.expression);
                }
                else assignedNS = semanticContext.factory.explicitNamespaceConstant(definition.name, undefined);

                result.setSymbolOf(definition, assignedNS);

                if (!assignedNS) break;

                // if this is a package alias, then define name into the frame only

                var name:Symbol = semanticContext.factory.name(qual, definition.name);
                var intoNames:Names = assignedNS.definedIn is Package && !(definition.modifiers & Modifiers.STATIC) ? scopeChain.currentFrame.names : nameCollectionOfDefinition(definition);
                var k:Symbol = intoNames.resolveName(name);

                if (k) {
                    if (k is NamespaceConstant && _compilerOptions.allowDuplicates) result.setSymbolOf(definition, k);

                    else reportVerifyError('verifyErrors.namespaceConflict', definition.nameSpan, { 'namespace': qual });
                }
                else {
                    // import aliased packages
                    if (assignedNS is NamespaceSet)
                        for each (var itemNS:NamespaceConstant in assignedNS.namespaces)
                            scopeChain.currentFrame.importPackage(itemNS.definedIn),
                            scopeChain.nss.addItem(itemNS);

                    intoNames.defineName(name, assignedNS);
                }

                break;

            }
        }

        private function verifyImportDirective(directive:ImportDirectiveNode, context:VerificationContext):void {
            var p:Symbol, itemName:String, splitImportName:Array, property:Symbol;

            switch (context.phase) {

            case VerificationPhase.DECLARATION_1:
                if (directive.wildcard) {
                    p = semanticContext.factory.packageSymbol(directive.importName);

                    var aliasSpecified:Boolean = !!directive.alias;

                    scopeChain.currentFrame.importPackage(p);
                    scopeChain.nss.addItem(p.publicNs);

                    if (aliasSpecified) {
                        var internalNS:Symbol = scopeChain.currentFrame.getLexicalReservedNamespace('internal');
                        var name:Symbol = semanticContext.factory.name(internalNS, directive.alias);

                        if (!scopeChain.currentFrame.names.hasName(name)) scopeChain.currentFrame.names.defineName(name, p.publicNs);
                    }
                    else scopeChain.nss.addItem(p.publicNs);

                    result.setSymbolOf(directive, p);
                }
                else verifyNonWildcardForm();

                break;

            case VerificationPhase.DECLARATION_4:
                if (directive.wildcard) {
                    p = result.symbolOf(directive);

                    if (p.names.length == 0) warn('warnings.noDefinitionsMatching', directive.importNameSpan, { name: p.fullyQualifiedName + '.*' });
                }
                else verifyNonWildcardForm();
                break;

            }

            function verifyNonWildcardForm():void {
                splitImportName = directive.importName.split('.');
                p = semanticContext.factory.packageSymbol(splitImportName.slice(0, splitImportName.length - 1).join('.'));
                itemName = splitImportName[splitImportName.length - 1];

                property = p.resolveName(semanticContext.factory.name(p.publicNs, itemName));

                if (property) {
                    var name2:Symbol = semanticContext.factory.name(scopeChain.currentFrame.getLexicalReservedNamespace('internal'), directive.alias ? directive.alias : itemName);

                    if (!scopeChain.currentFrame.names.hasName(name2)) scopeChain.currentFrame.names.defineName(name2, property);

                    result.setSymbolOf(directive, property);
                    scopeChain.currentFrame.openNamespaceList.addItem(p.publicNs);
                    scopeChain.nss.addItem(p.publicNs);
                }
                else if (property is AmbiguousReference) reportVerifyError('verifyErrors.ambiguousReference', directive.importNameSpan, { name: itemName });

                else if (context.phase == VerificationPhase.DECLARATION_3) warn('warnings.noDefinitionsMatching', directive.importNameSpan, { name: p.fullyQualifiedName + '.' + itemName });
            }
        }

        private function verifyUseDirective(directive:UseDirectiveNode):void {
            var q:Symbol;

            if (directive.expression is ListExpressionNode) {
                for each (var subExpr:ExpressionNode in ListExpressionNode(directive.expression).expressions) {
                    q = verifyNamespaceConstant(subExpr);

                    if (q is NamespaceSet) q = semanticContext.factory.explicitNamespaceConstant(q.prefix, undefined);

                    if (q) scopeChain.currentFrame.openNamespaceList.addItem(q), scopeChain.nss.addItem(q);
                }
            }
            else {
                q = verifyNamespaceConstant(directive.expression);

                if (q is NamespaceSet) q = semanticContext.factory.explicitNamespaceConstant(q.prefix, undefined);

                if (q) scopeChain.currentFrame.openNamespaceList.addItem(q), scopeChain.nss.addItem(q);
            }
        }

        private function verifyUseDefaultDirective(directive:UseDefaultDirectiveNode):void {
            var q:Symbol = verifyNamespaceConstant(directive.expression);

            if (q is NamespaceSet) q = semanticContext.factory.explicitNamespaceConstant(q.prefix, undefined);

            if (q) {
                if (scopeChain.currentFrame is Activation && !(q is ReservedNamespaceConstant && q.namespaceType == 'internal'))
                    reportVerifyError('verifyErrors.accessModifierNotAllowedHere', directive.expression.span);
                scopeChain.currentFrame.defaultNamespace = q;
            }
        }

        private function verifyTypeDefinition(definition:TypeDefinitionNode, context:VerificationContext):void {
            var r:Symbol, name:Symbol, intoNames:Names;

            switch (context.phase) {

            case VerificationPhase.DECLARATION_3:
            case VerificationPhase.DECLARATION_4:
                if (result.nodeIsAlreadyVerified(definition))
                    return;

                var q:Symbol = resolveDefinitionQualifier(definition);
                if (!q) return;

                name = semanticContext.factory.name(q, definition.name);
                r = verifyTypeExpression(definition.type);
                intoNames = nameCollectionOfDefinition(definition);

                if (intoNames.hasName(name))
                    reportVerifyError('verifyErrors.namespaceConflict', definition.nameSpan, { 'namespace': q });
                else intoNames.defineName(name, r);

                result.setSymbolOf(definition, r);
                break;

            }
        }
 
        private function verifyVarDefinition(definition:VarDefinitionNode, context:VerificationContext):void {
            var binding:VarBindingNode, type:Symbol, variable:Symbol;

            switch (context.phase) {

            case VerificationPhase.DECLARATION_2:

                if (result.symbolOf(definition) is SkipVarDefinition)
                    break;

                var q:Symbol = resolveDefinitionQualifier(definition);
                if (!q) {
                    result.setSymbolOf(definition, semanticContext.factory.skipVarDefinition());
                    break
                }

                var intoNames:Names = nameCollectionOfDefinition(definition);
                for each (binding in definition.bindings)
                    verifyDestructuringPattern1(binding.pattern, definition.readOnly, q, intoNames);

                break;

            case VerificationPhase.DECLARATION_4:

                if (result.symbolOf(definition) is SkipVarDefinition) break;

                for each (binding in definition.bindings) {
                    var typeExpr:ExpressionNode = binding.pattern.getPatternTypeExpression();
                    if (!typeExpr) continue;

                    type = verifyTypeExpression(typeExpr);
                    variable = result.symbolOf(binding.pattern).target;
                    if (type) variable.valueType = type;
                }

                break;

            case VerificationPhase.DECLARATION_5:

                if (result.symbolOf(definition) is SkipVarDefinition) break;

                if (!definition.readOnly && scopeChain.currentFrame is ClassFrame && scopeChain.currentFrame.symbol.classFlags & ClassFlags.PRIMITIVE) reportVerifyError('verifyErrors.varsInPrimitiveClassMustBeReadOnly', definition.span);

                // static variables won't auto turn Observable
                if (definition.modifiers & Modifiers.STATIC)
                    context = null;
                for each (binding in definition.bindings)
                    verifyVarBinding(binding, context);

                break;
            }
        }

        private function verifyVarBinding(binding:VarBindingNode, context:VerificationContext = undefined):void {
            context ||= new VerificationContext;
            var varType:Symbol,
                typeExpr:ExpressionNode = binding.pattern.getPatternTypeExpression();

            if (typeExpr)
                varType = verifyTypeExpression(typeExpr);

            if (binding.initialiser && (typeExpr ? result.symbolOf(typeExpr) : true)) {
                var iv:Symbol = verifyExpression(binding.initialiser, VerificationContext.withExpectedType(varType));

                if (iv && iv is Constant && binding.pattern is TypedIdNode)
                    result.symbolOf(binding.pattern).target.initialValue = iv;
                varType = varType ? varType : (iv ? iv.valueType : undefined);
                if (iv)
                    limitType(binding.initialiser, varType);
            }

            varType ||= semanticContext.statics.anyType;

            verifyDestructuringPattern2(binding.pattern, semanticContext.factory.value(varType), context);
        }

        private function updateDefinitionOrigin(symbol:Symbol):void {
            var frame:Symbol = scopeChain.currentFrame;
            symbol.definedIn = frame is PackageFrame || frame is ClassFrame || frame is EnumFrame || frame is InterfaceFrame ? frame.symbol : undefined;
        }

        private function verifyEnumDefinition(definition:EnumDefinitionNode, context:VerificationContext):void {
            var qual:Symbol, name:Symbol, type:Symbol, intoNames:Names, k:Symbol, blockFrame:Symbol, lexicalPublicNS:Symbol, nt:Symbol, drtv:DirectiveNode;

            switch (context.phase) {

            case VerificationPhase.DECLARATION_2:

                qual = resolveDefinitionQualifier(definition);

                if (!qual) return;

                name = semanticContext.factory.name(qual, definition.name);
                intoNames = nameCollectionOfDefinition(definition);
                k = intoNames.resolveName(name);

                lexicalPublicNS = scopeChain.getLexicalReservedNamespace('public') || scopeChain.getLexicalReservedNamespace('internal');

                if (k) {
                    if (_compilerOptions.allowDuplicates)
                        type = k;
                    else reportVerifyError('verifyErrors.namespaceConflict', definition.nameSpan, { 'namespace': qual });
                }
                else {
                    var configMetaData:MetaData = definition.findMetaData('TypeConfig');
                    var flags:Boolean = !!(configMetaData && !!configMetaData.findEntry('flags') && !!configMetaData.findEntry('flags').value) || definition.removeMetaData('Flags');
                    var disableNames:Boolean = !!(configMetaData && !!configMetaData.findEntry('disableNames') && !!configMetaData.findEntry('disableNames').value);
                    type = semanticContext.factory.enumType(name, undefined, (flags ? EnumFlags.FLAGS : 0) | (disableNames ? EnumFlags.DISABLE_NAMES : 0), lexicalPublicNS);
                    updateDefinitionOrigin(type);
                    intoNames.defineName(name, type);
                }

                result.setSymbolOf(definition, type), definition.removeMetaData('TypeConfig');

                if (type)
                    result.setSymbolOf(definition.block, blockFrame = semanticContext.factory.enumFrame(type)),
                    blockFrame.defaultNamespace = lexicalPublicNS,
                    blockFrame.activation = currentActivation;

                break;

            case VerificationPhase.DECLARATION_4:
                type = result.symbolOf(definition);

                if (!type) break;

                flags = type.enumFlags & EnumFlags.FLAGS;

                if (definition.type) {
                    nt = verifyTypeExpression(definition.type);

                    if (nt && nt != semanticContext.statics.numberType) reportVerifyError('verifyErrors.unsupportedEnumNumericType', definition.type.span), nt = undefined;
                }

                type.wrapsType = nt ||= semanticContext.statics.numberType;
                lexicalPublicNS = scopeChain.getLexicalReservedNamespace('public') || scopeChain.getLexicalReservedNamespace('internal');

                // define special methods
                type.defineEnumSpecialMethods(lexicalPublicNS);

                scopeChain.enterFrame(result.symbolOf(definition.block));

                var counter:AnyRangeNumber = AnyRangeNumber.numberOfClass(type.enumFlags & EnumFlags.FLAGS ? 1 : 0, nt.actionScriptNumericDataType);
                var inUseDictionary:Dictionary = new Dictionary;

                for each (drtv in definition.block.directives) {
                    if (!(drtv is VarDefinitionNode)) continue;

                    result.setSymbolOf(drtv, semanticContext.factory.skipVarDefinition());

                    qual = resolveDefinitionQualifier(DefinitionNode(drtv));
                    if (qual) for each (var binding:VarBindingNode in VarDefinitionNode(drtv).bindings) counter = declareEnumConstant(binding, type, qual, counter, inUseDictionary);
                }

                verifyDirectives(definition.block.directives, VerificationContext.withPhase(VerificationPhase.DECLARATION_1));
                verifyDirectives(definition.block.directives, VerificationContext.withPhase(VerificationPhase.DECLARATION_2));
                verifyDirectives(definition.block.directives, VerificationContext.withPhase(VerificationPhase.DECLARATION_3));
                verifyDirectives(definition.block.directives, VerificationContext.withPhase(VerificationPhase.DECLARATION_4));

                scopeChain.exitFrame();

                break;

            case VerificationPhase.INTERFACES:
                type = result.symbolOf(definition);

                if (!type) break;

                scopeChain.enterFrame(result.symbolOf(definition.block));
                verifyDirectives(definition.block.directives, VerificationContext.withPhase(VerificationPhase.INTERFACES));
                scopeChain.exitFrame();

                break;

            case VerificationPhase.DECLARATION_5:
                type = result.symbolOf(definition);

                if (!type) break;

                scopeChain.enterFrame(result.symbolOf(definition.block));
                verifyDirectives(definition.block.directives, VerificationContext.withPhase(VerificationPhase.DECLARATION_5));
                scopeChain.exitFrame();

                break;

            case VerificationPhase.INTERFACE_OPERATORS:
                type = result.symbolOf(definition);

                if (!type) break;

                scopeChain.enterFrame(result.symbolOf(definition.block));
                verifyDirectives(definition.block.directives, VerificationContext.withPhase(VerificationPhase.INTERFACE_OPERATORS));
                scopeChain.exitFrame();

                break;

            case VerificationPhase.OMEGA:
                type = result.symbolOf(definition);

                if (!type) break;

                scopeChain.enterFrame(result.symbolOf(definition.block));
                verifyDirectives(definition.block.directives, VerificationContext.withPhase(VerificationPhase.OMEGA));
                scopeChain.exitFrame();

                break;

            }
        }

        private function declareEnumConstant(binding:VarBindingNode, enumType:Symbol, qual:Symbol, counter:AnyRangeNumber, dictionary:Dictionary):AnyRangeNumber {
            var propertyName:Symbol = semanticContext.factory.name(qual, TypedIdNode(binding.pattern).name);
            var variable:Symbol = semanticContext.factory.variableSlot(propertyName, true, enumType);
            var numericConstant:Symbol;
            var id:String;

            if (binding.initialiser) {
                var arrayLiteral:ArrayLiteralNode = binding.initialiser as ArrayLiteralNode,
                    stringLiteral:StringLiteralNode;

                if (arrayLiteral && arrayLiteral.elements.length == 2) {
                    var j:int = -1;

                    if (stringLiteral = arrayLiteral.elements[0] as StringLiteralNode)
                        id = stringLiteral.value, j = 1;
                    else if (stringLiteral = arrayLiteral.elements[1] as StringLiteralNode)
                        id = stringLiteral.value, j = 0;

                    if (j == -1)
                        numericConstant = limitConstantType(binding.initialiser, enumType.wrapsType);
                    else numericConstant = limitConstantType(arrayLiteral.elements[j], enumType.wrapsType);
                }
                else if (stringLiteral = binding.initialiser as StringLiteralNode)
                    id = stringLiteral.value;
                else numericConstant = limitConstantType(binding.initialiser, enumType.wrapsType);
            }

            var value:AnyRangeNumber = counter = numericConstant ? new AnyRangeNumber(numericConstant.valueOf() >>> 0) : counter,
                previousNumber:*;

            if (enumType.wrapsType == semanticContext.statics.bigIntType) {
                for (previousNumber in dictionary) {
                    if (previousNumber.valueOf().equals(value.valueOf())) {
                        reportVerifyError('verifyErrors.duplicateEnumNumber', binding.pattern.span);
                        break;
                    }
                }
            }
            else {
                for (previousNumber in dictionary) {
                    if (previousNumber.valueOf() == value.valueOf()) {
                        reportVerifyError('verifyErrors.duplicateEnumNumber', binding.pattern.span);
                        break;
                    }
                }
            }

            if (enumType.enumFlags & EnumFlags.FLAGS) {
                var powerOf2Target:uint = value.valueOf();
                var valid:Boolean;

                if (powerOf2Target != 1) {
                    for (var i:uint = 1; i <= uint.MAX_VALUE; ++i) {
                        var powerOf2:uint = Math.pow(2, i);
                        if (powerOf2Target == powerOf2) {
                            valid = true;
                            break;
                        }
                        if (powerOf2Target < powerOf2) break;
                    }
                }
                else valid = true;

                if (!valid) reportVerifyError('verifyErrors.numericValueMustBePowerOf2', binding.pattern.span);
            }

            dictionary[value] = true;
            var enumConstant:Symbol = semanticContext.factory.enumConstant(value, enumType);
            counter = enumType.enumFlags & EnumFlags.FLAGS ? counter.multiply(2) : counter.add(1);

            id = id ? id : transformEnumConstantId(propertyName.localName);
            enumType.setEnumConstant(id, value);

            variable.initialValue = enumConstant;
            variable.enumPairAssociation = [id, value];

            result.setSymbolOf(binding.pattern, semanticContext.factory.targetAndValue(variable, enumConstant));

            if (enumType.names.hasName(propertyName))
                reportVerifyError('verifyErrors.namespaceConflict', binding.pattern.span, { 'namespace': propertyName.qualifier });
            else enumType.names.defineName(propertyName, enumConstant);

            return counter;
        }

        private function transformEnumConstantId(propertyName:String):String {
            var parts:Array = propertyName.split('_');
            var r:Array = [parts.shift().toLowerCase()];

            for each (var str:String in parts) {
                if (!str) continue;

                r.push(str.slice(0, 1).toUpperCase(), str.slice(1).toLowerCase());
            }

            return r.join('');
        }

        private function verifyObjectDefinition(definition:ObjectDefinitionNode, context:VerificationContext):void {
            var qual:Symbol, name:Symbol, nsObj:Symbol, intoNames:Names, k:Symbol, blockFrame:Symbol, lexicalPublicNS:Symbol;

            switch (context.phase) {

            case VerificationPhase.DECLARATION_2:

                qual = resolveDefinitionQualifier(definition);

                if (!qual) return;

                name = semanticContext.factory.name(qual, definition.name);
                intoNames = nameCollectionOfDefinition(definition);
                k = intoNames.resolveName(name);

                lexicalPublicNS = scopeChain.getLexicalReservedNamespace('public') || scopeChain.getLexicalReservedNamespace('internal');

                if (k) {
                    if (_compilerOptions.allowDuplicates)
                        nsObj = k;
                    else reportVerifyError('verifyErrors.namespaceConflict', definition.nameSpan, { 'namespace': qual });
                }
                else {
                    nsObj = semanticContext.factory.objectValue();
                    updateDefinitionOrigin(nsObj);
                    intoNames.defineName(name, nsObj);
                }

                result.setSymbolOf(definition, nsObj);

                if (nsObj)
                    result.setSymbolOf(definition.block, blockFrame = semanticContext.factory.objectFrame(nsObj)),
                    blockFrame.defaultNamespace = lexicalPublicNS,
                    blockFrame.activation = currentActivation;

                break;

            case VerificationPhase.DECLARATION_4:
                nsObj = result.symbolOf(definition);

                if (!nsObj) break;

                lexicalPublicNS = scopeChain.getLexicalReservedNamespace('public') || scopeChain.getLexicalReservedNamespace('internal');

                scopeChain.enterFrame(result.symbolOf(definition.block));

                verifyDirectives(definition.block.directives, VerificationContext.withPhase(VerificationPhase.DECLARATION_1));
                verifyDirectives(definition.block.directives, VerificationContext.withPhase(VerificationPhase.DECLARATION_2));
                verifyDirectives(definition.block.directives, VerificationContext.withPhase(VerificationPhase.DECLARATION_3));
                verifyDirectives(definition.block.directives, VerificationContext.withPhase(VerificationPhase.DECLARATION_4));

                scopeChain.exitFrame();

                break;

            case VerificationPhase.INTERFACES:
                nsObj = result.symbolOf(definition);

                if (!nsObj) break;

                scopeChain.enterFrame(result.symbolOf(definition.block));
                verifyDirectives(definition.block.directives, VerificationContext.withPhase(VerificationPhase.INTERFACES));
                scopeChain.exitFrame();

                break;

            case VerificationPhase.DECLARATION_5:
                nsObj = result.symbolOf(definition);

                if (!nsObj) break;

                scopeChain.enterFrame(result.symbolOf(definition.block));
                verifyDirectives(definition.block.directives, VerificationContext.withPhase(VerificationPhase.DECLARATION_5));
                scopeChain.exitFrame();

                break;

            case VerificationPhase.INTERFACE_OPERATORS:
                nsObj = result.symbolOf(definition);

                if (!nsObj) break;

                scopeChain.enterFrame(result.symbolOf(definition.block));
                verifyDirectives(definition.block.directives, VerificationContext.withPhase(VerificationPhase.INTERFACE_OPERATORS));
                scopeChain.exitFrame();

                break;

            case VerificationPhase.OMEGA:
                nsObj = result.symbolOf(definition);

                if (!nsObj) break;

                scopeChain.enterFrame(result.symbolOf(definition.block));
                verifyDirectives(definition.block.directives, VerificationContext.withPhase(VerificationPhase.OMEGA));
                scopeChain.exitFrame();

                break;

            }
        }

        private function verifyFunctionDefinition(definition:FunctionDefinitionNode, context:VerificationContext):void {
            var qual:Symbol, name:Symbol, intoNames:Names, enclosingType:Symbol, activation:Symbol, fn:Symbol, baseSignature:MethodSignature, signature:MethodSignature, virtualSlot:Symbol, delegate:Symbol;

            switch (context.phase) {

            case VerificationPhase.DECLARATION_2:

                if (definition.flags & FunctionFlags.GETTER || definition.flags & FunctionFlags.SETTER || definition.flags & FunctionFlags.CONSTRUCTOR) {
                    if (definition.flags & FunctionFlags.GETTER)
                        verifyGetterOrSetterDefinition(definition, true, context);
                    else if (definition.flags & FunctionFlags.SETTER)
                        verifyGetterOrSetterDefinition(definition, false, context);
                    else verifyConstructorDefinition(definition, context);
                }
                else {
                    qual = resolveDefinitionQualifier(definition);
                    if (!qual) break;

                    name = semanticContext.factory.name(qual, definition.name);
                    intoNames = nameCollectionOfDefinition(definition);

                    if (intoNames.hasName(name))
                        reportVerifyError('verifyErrors.namespaceConflict', definition.nameSpan, { 'namespace': qual });
                    else {
                        enclosingType = scopeChain.currentFrame.symbol is Type ? scopeChain.currentFrame.symbol : undefined;
                        activation = semanticContext.factory.activation((definition.modifiers & Modifiers.STATIC ? null : enclosingType) || semanticContext.statics.anyType);

                        fn = semanticContext.factory.methodSlot(name, undefined);
                        fn.activation = activation;
                        updateDefinitionOrigin(fn);
                        fn.methodFlags |= definition.common.flags & FunctionFlags.YIELD ? MethodFlags.YIELD : 0;
                        fn.methodFlags |= definition.common.flags & FunctionFlags.AWAIT ? MethodFlags.AWAIT : 0;
                        intoNames.defineName(name, fn);

                        result.setSymbolOf(definition, fn);
                        result.setSymbolOf(definition.common, fn);
                    }
                }

                fn = result.symbolOf(definition);

                if (fn)
                    fn.methodFlags |= definition.modifiers & Modifiers.FINAL ? MethodFlags.FINAL : 0,
                    fn.methodFlags |= definition.modifiers & Modifiers.NATIVE ? MethodFlags.NATIVE : 0,
                    fn.methodFlags |= !definition.common.body ? MethodFlags.NATIVE : 0;

                break;

            case VerificationPhase.DECLARATION_4:
                fn = result.symbolOf(definition);
                if (!fn) break;

                if (definition.flags & FunctionFlags.SETTER && fn.ofVirtualSlot.valueType)
                    baseSignature = semanticContext.factory.methodSignature([fn.ofVirtualSlot.valueType], undefined, false, semanticContext.statics.voidType);
                else if (definition.flags & FunctionFlags.GETTER && fn.ofVirtualSlot.valueType)
                    baseSignature = semanticContext.factory.methodSignature(undefined, undefined, false, fn.ofVirtualSlot.valueType);

                signature = resolveMethodSignature(definition.common, definition.nameSpan, baseSignature);
                fn.methodSignature = signature;

                if (definition.flags & FunctionFlags.GETTER) {
                    // limit getter signature
                    virtualSlot = fn.ofVirtualSlot;
                    if (signature.params || signature.optParams || signature.hasRest)
                        virtualSlot.getter = undefined,
                        reportVerifyError('verifyErrors.illegalGetterSignature', definition.nameSpan);
                    else virtualSlot.valueType ||= signature.result;
                }
                else if (definition.flags & FunctionFlags.SETTER) {
                    // limit setter signature
                    virtualSlot = fn.ofVirtualSlot;
                    if (!signature.params || signature.params.length != 1 || signature.optParams || signature.hasRest)
                        virtualSlot.setter = undefined,
                        reportVerifyError('verifyErrors.illegalSetterSignature', definition.nameSpan);
                    else virtualSlot.valueType ||= signature.params[0];
                }

                break;

            case VerificationPhase.DECLARATION_5:
                fn = result.symbolOf(definition);
                if (!fn) break;

                enclosingType = scopeChain.currentFrame.symbol is Type ? scopeChain.currentFrame.symbol : undefined;

                if (definition.modifiers & Modifiers.OVERRIDE) {
                    fn.methodFlags |= MethodFlags.OVERRIDE;
                    var overrideError:Symbol = fn.override(enclosingType.delegate);

                    if (overrideError) {
                        if (overrideError is IncompatibleOverrideSignature)
                            reportVerifyError('verifyErrors.incompatibleOverrideSignature', definition.nameSpan, { signature: overrideError.expectedMethodSignature });
                        else if (overrideError is MustOverrideAMethod)
                            reportVerifyError('verifyErrors.mustOverrideAMethod', definition.nameSpan);
                        else if (overrideError is OverridingFinal)
                            reportVerifyError('verifyErrors.overridingFinal', definition.nameSpan);
                    }
                }

                if (definition.common.flags & FunctionFlags.CONSTRUCTOR)
                    requireSuperConstructorCall(definition);

                if (fn.name.qualifier == semanticContext.statics.proxyNamespace && enclosingType)
                    validateProxyDefinition(definition, enclosingType, fn);

                break;

            case VerificationPhase.OMEGA:
                fn = result.symbolOf(definition);
                if (!fn) break;

                enclosingType = scopeChain.currentFrame.symbol is Type ? scopeChain.currentFrame.symbol : undefined;

                fillMethodActivation(definition.common, fn.methodSignature);

                if (definition.common.flags & FunctionFlags.CONSTRUCTOR && definition.common.body is BlockNode)
                    verifyConstructorDefinition(definition, context);
                else if (definition.common.body)
                    enterFunction(undefined, fn, definition.common),
                    verifyFunctionBody(definition.common, fn, definition.nameSpan),
                    exitFunction();

                break;

            }
        }

        private function requireSuperConstructorCall(definition:FunctionDefinitionNode):void {
            var superClass:Symbol = scopeChain.currentFrame.symbol.superType;
            if (superClass) return;

            var superCF:Symbol;
            for (var h:Symbol = superClass; h; h = h.superType)
                if (superCF = h.constructorMethod)
                    break;

            var signature:MethodSignature = superCF ? superCF.methodSignature : undefined;
            if (signature && signature.params) {
                var foundSuperStatement:Boolean;
                if (definition.common.body is BlockNode) {
                    for each (var drtv:DirectiveNode in BlockNode(definition.common.body).directives) {
                        if (drtv is SuperStatementNode) {
                            foundSuperStatement = true;
                            break;
                        }
                    }
                }
                if (!foundSuperStatement)
                    reportVerifyError('verifyErrors.superClassHasNoDefaultConstructor', definition.nameSpan);
            }
        }

        private function validateProxyDefinition(definition:FunctionDefinitionNode, enclosingType:Symbol, fn:Symbol):void {
            var name:Symbol = fn.name;
            var keyType:Symbol, valueType:Symbol, signature:MethodSignature;
            var propertyProxy:PropertyProxy;
            var markedStatic:Boolean = !!(definition.modifiers & Modifiers.STATIC);
            var operator:Operator = Operator.fromProxyName(semanticContext, name);

            if (operator && !markedStatic) {
                signature = semanticContext.factory.methodSignature(operator.isUnary ? undefined : [enclosingType], undefined, false, operator.resultsBoolean ? semanticContext.statics.booleanType : enclosingType);
                if (fn.methodSignature == signature)
                    enclosingType.delegate.operators ||= new Dictionary,
                    enclosingType.delegate.operators[operator] = fn;
            }
            else if (!markedStatic) {
                signature = fn.methodSignature;

                // Proxy::getProperty(name:K):V
                if (name == semanticContext.statics.proxyGetProperty) {
                    if (!( !signature.params || signature.params.length != 1 || signature.optParams || signature.hasRest) ) {
                        keyType = signature.params[0];
                        valueType = signature.result;
                        propertyProxy = enclosingType.delegate.propertyProxy;

                        if (!propertyProxy)
                            propertyProxy = enclosingType.delegate.propertyProxy = new PropertyProxy(keyType, valueType),
                            propertyProxy.getMethod = fn;
                        else if (propertyProxy.keyType == keyType && propertyProxy.valueType == valueType)
                            propertyProxy.getMethod = fn;
                    }
                }
                // Proxy::setProperty(name:K, value:V):void
                else if (name == semanticContext.statics.proxySetProperty) {
                    if (!( !signature.params || signature.params.length != 2 || signature.optParams || signature.hasRest || signature.result != semanticContext.statics.voidType) ) {
                        keyType = signature.params[0];
                        valueType = signature.params[1];
                        propertyProxy = enclosingType.delegate.propertyProxy;

                        if (!propertyProxy)
                            propertyProxy = enclosingType.delegate.propertyProxy = new PropertyProxy(keyType, valueType),
                            propertyProxy.includeMethod = fn;
                        else if (propertyProxy.keyType == keyType && propertyProxy.valueType == valueType)
                            propertyProxy.includeMethod = fn;
                    }
                }
                // Proxy::deleteProperty(name:K):Boolean
                else if (name == semanticContext.statics.proxyDeleteProperty) {
                    if (!( !signature.params || signature.params.length != 1 || signature.optParams || signature.hasRest || signature.result != semanticContext.statics.booleanType) ) {
                        keyType = signature.params[0];
                        propertyProxy = enclosingType.delegate.propertyProxy;
                        if (propertyProxy && keyType == propertyProxy.keyType)
                            propertyProxy.deleteMethod = fn;
                    }
                }
                // Proxy::getAttribute(name:K):V
                else if (name == semanticContext.statics.proxyGetAttribute) {
                    if (!( !signature.params || signature.params.length != 1 || signature.optParams || signature.hasRest) ) {
                        keyType = signature.params[0];
                        valueType = signature.result;
                        if (semanticContext.isNameType(keyType)) {
                            propertyProxy = enclosingType.delegate.attributeProxy;

                            if (!propertyProxy)
                                propertyProxy = enclosingType.delegate.attributeProxy = new PropertyProxy(keyType, valueType),
                                propertyProxy.getMethod = fn;
                            else if (propertyProxy.keyType == keyType && propertyProxy.valueType == valueType)
                                propertyProxy.getMethod = fn;
                        }
                    }
                }
                // Proxy::setAttribute(name:K, value:V):void
                else if (name == semanticContext.statics.proxySetAttribute) {
                    if (!( !signature.params || signature.params.length != 2 || signature.optParams || signature.hasRest || signature.result != semanticContext.statics.voidType) ) {
                        keyType = signature.params[0];
                        valueType = signature.params[1];
                        if (semanticContext.isNameType(keyType)) {
                            propertyProxy = enclosingType.delegate.attributeProxy;

                            if (!propertyProxy)
                                propertyProxy = enclosingType.delegate.attributeProxy = new PropertyProxy(keyType, valueType),
                                propertyProxy.includeMethod = fn;
                            else if (propertyProxy.keyType == keyType && propertyProxy.valueType == valueType)
                                propertyProxy.includeMethod = fn;
                        }
                    }
                }
                // Proxy::deleteAttribute(name:K):Boolean
                else if (name == semanticContext.statics.proxyDeleteAttribute) {
                    if (!( !signature.params || signature.params.length != 1 || signature.optParams || signature.hasRest || signature.result != semanticContext.statics.booleanType) ) {
                        keyType = signature.params[0];
                        propertyProxy = enclosingType.delegate.attributeProxy;
                        if (propertyProxy && keyType == propertyProxy.keyType)
                            propertyProxy.deleteMethod = fn;
                    }
                }
            }
        }

        private function verifyGetterOrSetterDefinition(definition:FunctionDefinitionNode, isGetter:Boolean, context:VerificationContext):void {
            var qual:Symbol, k:Symbol, name:Symbol, intoNames:Names, enclosingType:Symbol, activation:Symbol, fn:Symbol, virtualSlot:Symbol;

            switch (context.phase) {

            case VerificationPhase.DECLARATION_2:
                qual = resolveDefinitionQualifier(definition);
                if (!qual) break;

                name = semanticContext.factory.name(qual, definition.name);
                intoNames = nameCollectionOfDefinition(definition);
                k = intoNames.resolveName(name);

                enclosingType = scopeChain.currentFrame.symbol is Type ? scopeChain.currentFrame.symbol : undefined;

                if (k && k is VirtualSlot && (isGetter ? !k.getter : !k.setter)) {
                    activation = semanticContext.factory.activation(enclosingType || semanticContext.statics.anyType);

                    fn = semanticContext.factory.methodSlot(name, undefined);
                    fn.ofVirtualSlot = k;
                    updateDefinitionOrigin(fn);
                    fn.activation = activation;

                    if (isGetter)
                        k.getter = fn;
                    else k.setter = fn;

                    result.setSymbolOf(definition, fn);
                    result.setSymbolOf(definition.common, fn);
                }
                else if (k)
                    reportVerifyError('verifyErrors.namespaceConflict', definition.nameSpan, { 'namespace': qual });
                else {
                    activation = semanticContext.factory.activation(enclosingType || semanticContext.statics.anyType);
                    virtualSlot = semanticContext.factory.virtualSlot(name, undefined);
                    fn = semanticContext.factory.methodSlot(name, undefined);
                    fn.activation = activation;
                    fn.ofVirtualSlot = virtualSlot;
                    updateDefinitionOrigin(fn);

                    if (isGetter)
                        virtualSlot.getter = fn;
                    else virtualSlot.setter = fn;

                    result.setSymbolOf(definition, fn);
                    result.setSymbolOf(definition.common, fn);
                    intoNames.defineName(name, virtualSlot);
                }

                break;

            }
        }

        private function verifyConstructorDefinition(definition:FunctionDefinitionNode, context:VerificationContext):void {
            var qual:Symbol, k:Symbol, name:Symbol, intoNames:Names, enclosingType:Symbol, activation:Symbol, fn:Symbol;

            switch (context.phase) {

            case VerificationPhase.DECLARATION_2:

                qual = resolveDefinitionQualifier(definition);
                if (!qual) break;

                enclosingType = scopeChain.currentFrame.symbol;

                if (enclosingType.constructorMethod)
                    reportVerifyError('verifyErrors.constructorAlreadyDefined', definition.nameSpan);
                else {
                    activation = semanticContext.factory.activation(enclosingType);
                    fn = semanticContext.factory.methodSlot(enclosingType.name, undefined);
                    fn.activation = activation;
                    enclosingType.constructorMethod = fn;
                    result.setSymbolOf(definition, fn);
                    result.setSymbolOf(definition.common, fn);
                }

                break;

            case VerificationPhase.OMEGA:
                fn = result.symbolOf(definition);
                enclosingType = scopeChain.currentFrame.symbol;
                var block:BlockNode = BlockNode(definition.common.body);
                var blockFrame:Symbol = semanticContext.factory.frame();
                blockFrame.defaultNamespace = scopeChain.getLexicalReservedNamespace('internal');
                result.setSymbolOf(block, blockFrame);

                enterFunction(undefined, fn, definition.common);
                scopeChain.enterFrame(fn.activation);
                scopeChain.enterFrame(blockFrame);

                const readOnlyVars:Array = [];
                var property:Property, readOnlyVar:Symbol;

                for each (property in new NamesTree(enclosingType.delegate))
                    if (property.value is VariableSlot && property.value.readOnly)
                        readOnlyVars.push(property.value);

                for each (readOnlyVar in readOnlyVars) readOnlyVar.readOnly = false;

                verifyDirectives(block.directives);

                for each (readOnlyVar in readOnlyVars) readOnlyVar.readOnly = true;

                scopeChain.exitFrame();
                scopeChain.exitFrame();
                exitFunction();

                break;

            }
        }

        private function verifyClassDefinition(definition:ClassDefinitionNode, context:VerificationContext):void {
            var qual:Symbol,
                type:Symbol,
                type2:Symbol,
                name:Symbol,
                intoNames:Names,
                k:Symbol,
                frame:Symbol,
                drtv:DirectiveNode,
                typeExpr:ExpressionNode;

            switch (context.phase) {
            case VerificationPhase.DECLARATION_2:
                qual = resolveDefinitionQualifier(definition);
                if (!qual) break;

                var configMetadata:MetaData = definition.findMetaData('TypeConfig');
                name = semanticContext.factory.name(qual, definition.name);
                intoNames = nameCollectionOfDefinition(definition);

                k = intoNames.resolveName(name);
                if (k) {
                    if (k is ClassType && _compilerOptions.allowDuplicates)
                        type = k;
                    else reportVerifyError('verifyErrors.namespaceConflict', definition.nameSpan, { 'namespace': qual });
                }
                else {
                    var isPrimitive:Boolean = (configMetadata && configMetadata &&configMetadata.findEntry('primitive') && !!(configMetadata.findEntry('primitive').value)) || definition.removeMetaData('Primitive');
                    var isUnion:Boolean = (configMetadata && configMetadata.findEntry('union') && !!(configMetadata.findEntry('union').value)) || definition.removeMetaData('Union');
                    type = semanticContext.factory.classType(name, (definition.modifiers & Modifiers.FINAL ? ClassFlags.FINAL : 0) | (definition.modifiers & Modifiers.DYNAMIC ? ClassFlags.DYNAMIC : 0) | (isPrimitive ? ClassFlags.PRIMITIVE : 0) | (isUnion ? ClassFlags.UNION : 0) | (isUnion ? ClassFlags.ALLOW_LITERAL : 0));
                    updateDefinitionOrigin(type);
                    intoNames.defineName(name, type);
                }

                result.setSymbolOf(definition, type);
                definition.removeMetaData('TypeConfig');

                if (type && configMetadata && configMetadata.findEntry('dynamicInit'))
                    type.classFlags |= configMetadata.findEntry('dynamicInit').value ? ClassFlags.ALLOW_LITERAL : 0;

                if (type && definition.removeMetaData('AllowLiteral'))
                    type.classFlags |= ClassFlags.ALLOW_LITERAL;

                if (type)
                    result.setSymbolOf(definition.block, frame = semanticContext.factory.classFrame(type)),
                    frame.defaultNamespace = scopeChain.getLexicalReservedNamespace('public') || scopeChain.getLexicalReservedNamespace('internal');

                break;

            case VerificationPhase.DECLARATION_4:
                type = result.symbolOf(definition);
                if (!type) break;

                if (definition.extendsElement) {
                    type2 = verifyTypeExpression(definition.extendsElement);
                    type2 = type2 ? type2.escapeType() : undefined;
                    if (type2 && type2 is ClassType) {
                        if (type2.classFlags & ClassFlags.FINAL)
                            reportVerifyError('verifyErrors.cannotExtendFinalClass', definition.extendsElement.span);
                        else if (type2.classFlags & ClassFlags.PRIMITIVE && type2 != semanticContext.statics.objectType)
                            reportVerifyError('verifyErrors.primitiveClassMustExtendObject', definition.nameSpan);
                        else type.extendType(type2.escapeType()),
                            type.classFlags |= type2.classFlags & ClassFlags.LIVE_VARS ? ClassFlags.LIVE_VARS : 0;
                    }
                    else if (type2)
                        reportVerifyError('verifyErrors.cannotExtendFinalClass', definition.extendsElement.span);
                }

                if (definition.implementsList) {
                    for each (typeExpr in definition.implementsList) {
                        type2 = verifyTypeExpression(typeExpr);
                        type2 = type2 ? type2.escapeType() : undefined;
                        if (type2 && type2 is InterfaceType)
                            type.implementType(type2);
                        else if (type2)
                            reportVerifyError('verifyErrors.expectedInterfaceReference', typeExpr.span);
                    }
                }

                scopeChain.enterFrame(result.symbolOf(definition.block));

                verifyDirectives(definition.block.directives, VerificationContext.withPhase(VerificationPhase.DECLARATION_1));
                verifyDirectives(definition.block.directives, VerificationContext.withPhase(VerificationPhase.DECLARATION_2));
                verifyDirectives(definition.block.directives, VerificationContext.withPhase(VerificationPhase.DECLARATION_3));
                verifyDirectives(definition.block.directives, VerificationContext.withPhase(VerificationPhase.DECLARATION_4));

                scopeChain.exitFrame();

                break;

            case VerificationPhase.INTERFACES:
                type = result.symbolOf(definition);
                if (!type) break;

                scopeChain.enterFrame(result.symbolOf(definition.block));
                verifyDirectives(definition.block.directives, VerificationContext.withPhase(VerificationPhase.INTERFACES));
                scopeChain.exitFrame();

                break;

            case VerificationPhase.DECLARATION_5:
                type = result.symbolOf(definition);
                if (!type) break;

                type.verifyInterfaceImplementations(onUndefinedItrfcReq, onWrongItrfcReq);

                function onUndefinedItrfcReq(methodType:String, name:Symbol, signature:MethodSignature):void {
                    if (methodType == 'getter')
                        reportVerifyError('verifyErrors.mustDefineItrfcReqGetter', definition.nameSpan, { name: name, signature: signature });
                    else if (methodType == 'setter')
                        reportVerifyError('verifyErrors.mustDefineItrfcReqSetter', definition.nameSpan, { name: name, signature: signature });
                    else reportVerifyError('verifyErrors.mustDefineItrfcReqMethod', definition.nameSpan, { name: name, signature: signature });
                }


                function onWrongItrfcReq(slotType:String, name:Symbol):void {
                    if (slotType == 'virtualProperty')
                        reportVerifyError('verifyErrors.invalidItrfcReqProperty', definition.nameSpan, { name: name });
                    else reportVerifyError('verifyErrors.invalidItrfcReqMethod', definition.nameSpan, { name: name });
                }

                scopeChain.enterFrame(result.symbolOf(definition.block));

                var blockContext:VerificationContext = VerificationContext.withPhase(VerificationPhase.DECLARATION_5);
                blockContext.turnObservables = context.turnObservables || !!(type.classFlags & ClassFlags.LIVE_VARS);

                verifyDirectives(definition.block.directives, blockContext);

                scopeChain.exitFrame();

                break;

            case VerificationPhase.INTERFACE_OPERATORS:
                type = result.symbolOf(definition);
                if (!type) break;

                scopeChain.enterFrame(result.symbolOf(definition.block));
                verifyDirectives(definition.block.directives, VerificationContext.withPhase(VerificationPhase.INTERFACE_OPERATORS));
                scopeChain.exitFrame();

                break;

            case VerificationPhase.OMEGA:
                type = result.symbolOf(definition);
                if (!type) break;

                scopeChain.enterFrame(result.symbolOf(definition.block));
                verifyDirectives(definition.block.directives, VerificationContext.withPhase(VerificationPhase.OMEGA));
                scopeChain.exitFrame();

                if (type.classFlags & ClassFlags.UNION) {
                    for each (drtv in definition.block.directives) {
                        var varDefn:VarDefinitionNode = drtv as VarDefinitionNode;
                        if (varDefn && !(varDefn.modifiers & Modifiers.STATIC)) {
                            for each (var binding:VarBindingNode in varDefn.bindings) {
                                var varType:Symbol = result.symbolOf(binding.pattern).target.valueType;
                                if (!varType.containsNull || !varType.containsUndefined)
                                    reportVerifyError('verifyErrors.unionInstanceVarMustBeNullable', binding.pattern.span);
                            }
                        }
                    }
                }

                break;
            }
        }

        private function verifyInterfaceDefinition(definition:InterfaceDefinitionNode, context:VerificationContext):void {
            var qual:Symbol,
                name:Symbol,
                intoNames:Names,
                k:Symbol,
                type:Symbol,
                type2:Symbol,
                superItrfc:Symbol,
                frame:Symbol,
                typeExpr:ExpressionNode;

            switch (context.phase) {

            case VerificationPhase.DECLARATION_2:
                qual = resolveDefinitionQualifier(definition);
                if (!qual) break;

                name = semanticContext.factory.name(qual, definition.name);
                intoNames = nameCollectionOfDefinition(definition);

                k = intoNames.resolveName(name);
                if (k) {
                    if (k is InterfaceType && _compilerOptions.allowDuplicates)
                        type = k;
                    else reportVerifyError('verifyErrors.namespaceConflict', definition.nameSpan, { 'namespace': qual });
                }
                else type = semanticContext.factory.interfaceType(name),
                    intoNames.defineName(name, type),
                    updateDefinitionOrigin(type);

                if (type)
                    result.setSymbolOf(definition.block, frame = semanticContext.factory.interfaceFrame(type)),
                    frame.defaultNamespace = scopeChain.getLexicalReservedNamespace('public') || scopeChain.getLexicalReservedNamespace('internal');

                result.setSymbolOf(definition, type);

                break;

            case VerificationPhase.DECLARATION_4:
                type = result.symbolOf(definition);
                if (!type) break;

                scopeChain.enterFrame(result.symbolOf(definition.block));

                verifyDirectives(definition.block.directives, VerificationContext.withPhase(VerificationPhase.DECLARATION_1));
                verifyDirectives(definition.block.directives, VerificationContext.withPhase(VerificationPhase.DECLARATION_2));
                verifyDirectives(definition.block.directives, VerificationContext.withPhase(VerificationPhase.DECLARATION_3));
                verifyDirectives(definition.block.directives, VerificationContext.withPhase(VerificationPhase.DECLARATION_4));

                scopeChain.exitFrame();

                break;

            case VerificationPhase.INTERFACES:
                type = result.symbolOf(definition);
                if (!type) break;

                if (definition.extendsList) {
                    for each (typeExpr in definition.extendsList) {
                        type2 = verifyTypeExpression(typeExpr);
                        type2 = type2 ? type2.escapeType() : undefined;
                        if (type2 && type2 is InterfaceType) {
                            var extendingErrors:Array = type.extendType(type2);
                            if (extendingErrors)
                                for each (var extendError:Symbol in extendingErrors)
                                    reportVerifyError('verifyErrors.inheritingDuplicateDefinition', definition.nameSpan, { name: extendError.name });
                        }
                        else if (type2)
                            reportVerifyError('verifyErrors.expectedInterfaceReference', typeExpr.span);
                    }
                }

                break;

            case VerificationPhase.DECLARATION_5:
                type = result.symbolOf(definition);
                if (!type) break;

                scopeChain.enterFrame(result.symbolOf(definition.block));
                verifyDirectives(definition.block.directives, VerificationContext.withPhase(VerificationPhase.DECLARATION_5));
                scopeChain.exitFrame();

                break;

            case VerificationPhase.INTERFACE_OPERATORS:
                type = result.symbolOf(definition);

                if (type && type.superInterfaces) {
                    for each (superItrfc in type.superInterfaces) {
                        if (superItrfc.delegate.operators) {
                            type.delegate.operators ||= new Dictionary;

                            for (var operator in superItrfc.delegate.operators)
                                type.delegate.operators[operator] = superItrfc.delegate.operators[operator];
                        }
                    }
                }

                break;

            case VerificationPhase.OMEGA:
                type = result.symbolOf(definition);
                if (!type) break;

                scopeChain.enterFrame(result.symbolOf(definition.block));
                verifyDirectives(definition.block.directives, VerificationContext.withPhase(VerificationPhase.OMEGA));
                scopeChain.exitFrame();

                break;
            }
        }

        private function limitType(expression:ExpressionNode, type:Symbol):Symbol {
            var v:Symbol = verifyExpression(expression, VerificationContext.withExpectedType(type));
            if (!v) return undefined;

            var k:Symbol = v.valueType;
            result.setSymbolOf(expression, v = v.convertImplicit(type));

            if (!v)
                reportVerifyError('verifyErrors.incompatibleTypes', expression.span, { expected: type, got: k });

            return v;
        }

        private function tryConverting(expression:ExpressionNode, type:Symbol):Symbol {
            var v:Symbol = verifyExpression(expression, VerificationContext.withExpectedType(type));
            if (!v) return undefined;

            result.setSymbolOf(expression, v = v.convertImplicit(type));
            return v;
        }

        public function verifyExpression(expression:ExpressionNode, context:VerificationContext = undefined):Symbol {
            context ||= new VerificationContext;
            var r:Symbol = result.symbolOf(expression);
            if (r || result.nodeIsAlreadyVerified(expression))
                return r;

            // try verifying as constant
            var constExpCtx:VerificationContext = new VerificationContext;
            constExpCtx.expectedType = context.expectedType;
            constExpCtx.reportConstantExpressionErrors = false;
            r = verifyConstantExpression(expression, constExpCtx);
            if (r) {
                result.setSymbolOf(expression, r);
                if (context.expectedType) {
                    r = r.convertConstant(context.expectedType);
                    if (r) result.setSymbolOf(expression, r);
                }
                return result.symbolOf(expression);
            }

            var base:Symbol,
                activation:Symbol;

            if (expression is QualifiedIdNode)
                r = resolveLexicalReference(QualifiedIdNode(expression), context);
            else if (expression is DotNode) {
                base = verifyExpression(DotNode(expression).base);
                if (base)
                    r = resolveReference(base, DotNode(expression).id, context);
            }
            else if (expression is StringLiteralNode)
                r = verifyStringLiteral(StringLiteralNode(expression), context);
            else if (expression is ThisLiteralNode) {
                activation = scopeChain.currentFrame.activation;
                if (!activation)
                    reportVerifyError('verifyErrors.thisCannotBeUsedHere', expression.span);
                else r = activation.thisValue;
            }
            else if (expression is BooleanLiteralNode) semanticContext.factory.booleanConstant(BooleanLiteralNode(expression).value);
            else if (expression is NumericLiteralNode) {
                r = semanticContext.factory.numberConstant(NumericLiteralNode(expression).value);

                if (context.expectedType && semanticContext.isNumericType(context.expectedType)) r = r.convertConstant(context.expectedType);
            }
            else if (expression is StringLiteralNode) r = verifyStringLiteral(StringLiteralNode(expression), context);
            else if (expression is NullLiteralNode) r = semanticContext.factory.nullConstant(context.expectedType && context.expectedType.containsNull ? context.expectedType : semanticContext.statics.nullType);
            else if (expression is ReservedNamespaceNode)
                r = verifyReservedNamespace(ReservedNamespaceNode(expression), new VerificationContext);
            else if (expression is RegExpLiteralNode)
                r = semanticContext.factory.value(semanticContext.statics.regExpType);
            else if (expression is ObjectLiteralNode)
                r = verifyObjectLiteral(ObjectLiteralNode(expression), context);
            else if (expression is ArrayLiteralNode)
                r = verifyArrayLiteral(ArrayLiteralNode(expression), context);
            else if (expression is NewOperatorNode)
                r = verifyNewOperator(NewOperatorNode(expression));
            else if (expression is FunctionExpressionNode)
                r = verifyFunctionExpression(FunctionExpressionNode(expression));
            else if (expression is EmbedExpressionNode) {
                var embedExp:EmbedExpressionNode = EmbedExpressionNode(expression);
                var embedType:Symbol = context.expectedType ? context.expectedType.escapeType() : undefined;
                if (!embedType)
                    reportVerifyError('verifyErrors.embedMustBeTyped', expression.span);
                else if (embedType != semanticContext.statics.octetArrayType && embedType != semanticContext.statics.stringType && embedType != semanticContext.statics.xmlType)
                    reportVerifyError('verifyErrors.embeddingUnsupportedType', expression.span, { type: embedType });
                else r = semanticContext.factory.value(context.expectedType);
            }
            else if (expression is SuperNode)
                r = verifySuperExpression(SuperNode(expression));
            else if (expression is CallNode)
                r = verifyCallOperator(CallNode(expression));
            else if (expression is TypeArgumentsNode)
                r = verifyTypeArguments(TypeArgumentsNode(expression));
            else if (expression is BracketsNode)
                r = verifyBracketsOperator(BracketsNode(expression));
            else if (expression is DescendantsNode)
                r = verifyDescendantsOperator(DescendantsNode(expression));
            else if (expression is UnaryOperatorNode)
                r = verifyUnaryOperator(UnaryOperatorNode(expression));
            else if (expression is TypeOperatorNode)
                r = verifyTypeOperator(TypeOperatorNode(expression));
            else if (expression is BinaryOperatorNode)
                r = verifyBinaryOperator(BinaryOperatorNode(expression), context);
            else if (expression is TernaryNode)
                r = verifyTernaryOperator(TernaryNode(expression), context);
            else if (expression is AssignmentNode)
                r = verifyAssignmentOperator(AssignmentNode(expression));
            else if (expression is ListExpressionNode) {
                var listExp:ListExpressionNode = ListExpressionNode(expression);
                var i:uint;
                for each (var subExp:ExpressionNode in listExp.expressions) {
                    var subflags:uint = i == listExp.expressions.length - 1 ? context.flags : 0;
                    var listExpCtx:VerificationContext = new VerificationContext;
                    listExpCtx.expectedType = context.expectedType;
                    listExpCtx.flags = subflags;
                    r = verifyExpression(subExp, listExpCtx);
                    ++i;
                }
            }
            else if (expression is ParenExpressionNode)
                r = verifyExpression(ParenExpressionNode(expression).expression, context);
            else if (expression is XMLListNode)
                verifyXMLList(XMLListNode(expression)),
                r = semanticContext.factory.value(semanticContext.statics.xmlListType);
            else if (expression is XMLNode)
                verifyXML(XMLNode(expression)),
                r = semanticContext.factory.value(semanticContext.statics.xmlType);
            else if (expression is NullableTypeNode) {
                var nullableTypeExp:NullableTypeNode = NullableTypeNode(expression);
                r = verifyTypeExpression(nullableTypeExp.type);
                r = r ? semanticContext.factory.nullableType(r) : null;
            }
            else throw new Error('Verification of ' + expression + ' is unimplemented.');

            if (r) {
                // reference restrictions
                if (context.flags & VerifyFlags.UPDATE_TARGET) {
                    if (r.readOnly && !r.isObservableVariable)
                        reportVerifyError('verifyErrors.referenceIsReadOnly', expression.span);
                }
                else if (context.flags & VerifyFlags.DELETE_REFERENCE) {
                    if (!r.isDeletable)
                        reportVerifyError('verifyErrors.unsupportedDeleteOperation', expression.span);
                }
                else if (r.writeOnly)
                    reportVerifyError('verifyErrors.referenceIsWriteOnly', expression.span);

                result.setSymbolOf(expression, r);
                return r;
            }
            result.setSymbolOf(expression, null);
            return null;
        }

        private function verifySuperExpression(expression:SuperNode):Symbol {
            var limit:Symbol,
                r:Symbol,
                obj:Symbol;

            if (expression.arguments && expression.arguments.length > 0) {
                for each (var subExpr:ExpressionNode in expression.arguments)
                    verifyExpression(subExpr);
                obj = result.symbolOf(expression.arguments[expression.arguments.length -  1]);
            }
            else {
                // super expression refers to 'this'
                var activation:Symbol = scopeChain.currentFrame.activation;
                obj = activation ? activation.thisValue : undefined;
            }

            if (obj)
                limit = obj.valueType.superType || obj.valueType,
                r = semanticContext.factory.value(limit);
            else reportVerifyError('verifyErrors.superExpCannotBeUsedHere', expression.span);

            return r;
        }

        private function verifyCallOperator(expression:CallNode):Symbol {
            var base:Symbol = verifyExpression(expression.base, VerificationContext.withFlags(VerifyFlags.CALL_BASE_REFERENCE)),
                applyFn:Symbol,
                argument:Symbol,
                r:Symbol,
                subExp:ExpressionNode;

            if (base && base is Type) {
                // C.Proxy::apply()
                applyFn = base.resolveName(semanticContext.statics.proxyApply);
                applyFn = applyFn is ReferenceValue ? applyFn.property : null;
                if (applyFn is MethodSlot && applyFn.methodSignature.isApplyProxy(semanticContext)) {
                    for each (subExp in expression.arguments)
                        verifyExpression(subExp);
                    r = semanticContext.factory.applyProxyValue(base, applyFn);
                }
                else if (expression.arguments.length != 1)
                    reportVerifyError('verifyErrors.expectedExactly1Argument', expression.span);
                else {
                    argument = verifyExpression(expression.arguments[0], VerificationContext.withExpectedType(base));
                    r = argument.convertExplicit(base);
                    if (!r)
                        reportVerifyError('verifyErrors.incompatibleTypes', expression.arguments[0].span, { expected: base, got: argument.valueType });
                }
            }
            else if (base && base.valueType.escapeType() == semanticContext.statics.generatorType) {
                // applying Generator
                if (expression.arguments.length > 0)
                    reportVerifyError('verifyErrors.wrongNumberOfArguments', expression.span, { number: 0 });
                r = semanticContext.factory.value(semanticContext.statics.anyType);
            }
            else if (base) {
                // applying method with known signature
                if (base is ReferenceValue && base.property is MethodSlot)
                    verifyCallArguments(expression.arguments, expression, base.property.methodSignature),
                    r = semanticContext.factory.value(base.property.methodSignature.result);
                // applying Function object
                else if (base.valueType.escapeType() == semanticContext.statics.functionType)
                    r = semanticContext.factory.value(semanticContext.statics.anyType);
                // applying through proxy
                else {
                    applyFn = base.resolveName(semanticContext.statics.proxyApply);
                    if (applyFn is MethodSlot && applyFn.methodSignature.isApplyProxy(semanticContext))
                        r = semanticContext.factory.applyProxyValue(base, applyFn);
                    // * or Class
                    else if (base.valueType != semanticContext.statics.anyType && base.valueType != semanticContext.statics.classType)
                        reportVerifyError('verifyErrors.notCallable', expression.base.span);
                }
            }

            return r;
        }

        private function verifyObjectLiteral(literal:ObjectLiteralNode, context:VerificationContext):Symbol {
            var initType:Symbol = context.expectedType && context.expectedType.escapeType() is ClassType && context.expectedType.escapeType().classFlags & ClassFlags.ALLOW_LITERAL ? context.expectedType.escapeType() : undefined,
                fieldOrSpreadOp:Node,
                field:ObjectFieldNode,
                spreadOp:SpreadOperatorNode,
                exp:ExpressionNode,
                shorthandValue:Symbol,
                dictType:Symbol;

            if (initType) {
                for each (fieldOrSpreadOp in literal.fields) {
                    if (fieldOrSpreadOp is SpreadOperatorNode) {
                        spreadOp = SpreadOperatorNode(fieldOrSpreadOp);
                        limitType(spreadOp.expression, initType);
                        continue;
                    }
                    field = ObjectFieldNode(fieldOrSpreadOp);
                    if (!field.computed && (field.key is SimpleIdNode || field.key is StringLiteralNode)) {
                        var name:String = field.key is SimpleIdNode ? SimpleIdNode(field.key).name : StringLiteralNode(field.key).value;
                        var targetVar:Symbol = initType.delegate.resolveMultiName(scopeChain.nss, name);
                        targetVar = targetVar is VariableSlot ? targetVar : undefined;
                        result.setSymbolOf(field.key, targetVar);

                        if (!targetVar)
                            reportVerifyError('verifyErrors.initializingUndefinedProperty', field.key.span, { name: name, type: initType });

                        if (targetVar && !targetVar.valueType)
                            reportVerifyError('verifyErrors.unresolvedReference', field.key.span, { name: name }),
                            targetVar = undefined;

                        if (!field.value) {
                            shorthandValue = resolveLexicalReference(QualifiedIdNode(field.key), new VerificationContext);
                            if (targetVar && shorthandValue)
                                result.setSymbolOf(field, semanticContext.factory.targetAndValue(targetVar, shorthandValue));
                        }
                        else verifyExpression(field.value, VerificationContext.withExpectedType(targetVar ? targetVar.valueType : undefined));
                    }
                    else reportVerifyError('verifyErrors.objectFieldKeyNotAllowedHere', field.key.span),
                        verifyExpression(field.value);
                }
            }
            else {
                dictType = context.expectedType == semanticContext.statics.mapType ? semanticContext.statics.mapType : semanticContext.statics.objectType;
                for each (fieldOrSpreadOp in literal.fields) {
                    if (fieldOrSpreadOp is SpreadOperatorNode) {
                        spreadOp = SpreadOperatorNode(fieldOrSpreadOp);
                        limitType(spreadOp.expression, dictType);
                        continue;
                    }
                    field = ObjectFieldNode(fieldOrSpreadOp);
                    if (field.computed)
                        verifyExpression(field.key),
                        verifyExpression(field.value);
                    else if (!field.value) {
                        shorthandValue = resolveLexicalReference(QualifiedIdNode(field.key), new VerificationContext);
                        if (shorthandValue)
                            result.setSymbolOf(field, semanticContext.factory.targetAndValue(undefined, shorthandValue));
                    }
                    else verifyExpression(field.value);
                }
            }

            return semanticContext.factory.value(initType || dictType);
        }

        private function verifyArrayLiteral(literal:ArrayLiteralNode, context:VerificationContext):Symbol {
            var initType:Symbol = context.expectedType ? context.expectedType.escapeType() : undefined,
                element:ExpressionNode,
                spreadOp:SpreadOperatorNode,
                elementType:Symbol;

            if (initType is EnumType && initType.enumFlags & EnumFlags.FLAGS) {
                for each (element in literal.elements) {
                    if (element is SpreadOperatorNode) {
                        spreadOp = SpreadOperatorNode(element);
                        limitType(spreadOp.expression, initType);
                        continue;
                    }
                    if (element)
                        limitType(element, initType);
                }
            }
            else if (initType is TupleType) {
                var i:uint;
                if (literal.elements.length != initType.tupleElements.length)
                    reportVerifyError('verifyErrors.wrongNumberOfTupleElements', literal.span, { number: initType.tupleElements.length });
                for each (element in literal.elements) {
                    if (element is SpreadOperatorNode) {
                        reportVerifyError('verifyErrors.spreadOperatorNotAllowedHere', element.span);
                        verifyExpression(SpreadOperatorNode(element).expression);
                        ++i;
                        continue;
                    }
                    elementType = i < initType.tupleElements.length ? initType.tupleElements[i] : undefined;
                    if (element)
                        limitType(element, elementType);
                    ++i;
                }
            }
            else {
                initType = semanticContext.statics.arrayType;
                elementType = semanticContext.statics.anyType;

                for each (element in literal.elements) {
                    if (element is SpreadOperatorNode) {
                        spreadOp = SpreadOperatorNode(element);
                        limitType(spreadOp.expression, initType);
                        continue;
                    }
                    if (element)
                        limitType(element, elementType);
                }
            }

            return semanticContext.factory.value(initType);
        }

        private function verifyNewOperator(exp:NewOperatorNode):Symbol {
            var base:Symbol = verifyExpression(exp.base),
                r:Symbol;

            if (base is Type) {
                base = base.escapeType();
                var constructorFn:Symbol;
                for (var base2:Symbol = base; base2; base2 = base2.superType)
                    if (constructorFn = base2.constructorMethod)
                        break;
                if (constructorFn)
                    verifyCallArguments(exp.arguments || [], exp, constructorFn.methodSignature),
                    r = semanticContext.factory.value(base);
                else reportVerifyError('verifyErrors.cannotConstructType', exp.base.span, { type: base });
            }
            else if (base) {
                limitType(exp.base, semanticContext.statics.classType);
                for each (var expr:ExpressionNode in exp.arguments)
                    verifyExpression(expr);
                r = semanticContext.factory.value(semanticContext.statics.anyType);
            }

            return r;
        }

        private function verifyCallArguments(arguments:Array, enclosingExp:Node, signature:MethodSignature):void {
            var consumer:MethodSignatureConsumer = new MethodSignatureConsumer(signature);
            if (arguments.length < consumer.minLength || Number(arguments.length) > consumer.maxLength)
                reportVerifyError('verifyErrors.wrongNumberOfArguments', enclosingExp.span, { number: consumer.minLength });
            var param:MethodSignatureParam;
            while ((param = consumer.shift()) && consumer.index <= arguments.length) {
                if (param.position == 'required' || param.position == 'optional')
                    limitType(arguments[consumer.index - 1], param.type);
                else verifyExpression(arguments[consumer.index - 1]);
            }
        }

        private function verifyFunctionExpression(exp:FunctionExpressionNode):Symbol {
            var name:Symbol = exp.name ? semanticContext.factory.name(scopeChain.getLexicalReservedNamespace('internal'), exp.name) : undefined;
            var signature:MethodSignature;

            var activation:Symbol = semanticContext.factory.activation(semanticContext.statics.anyType);

            var pointSpan:Span = Span.point(exp.span.firstLine, exp.span.start);
            signature = resolveMethodSignature(exp.common, pointSpan, null, true);
            var fn:Symbol = semanticContext.factory.methodSlot(name, signature);
            fn.activation = activation;
            result.setSymbolOf(exp.common, fn);

            fillMethodActivation(exp.common, signature);

            fn.methodFlags |= exp.common.flags & FunctionFlags.YIELD ? MethodFlags.YIELD : 0;
            fn.methodFlags |= exp.common.flags & FunctionFlags.AWAIT ? MethodFlags.AWAIT : 0;

            if (name) activation.names.defineName(name, fn);

            enterFunction(undefined, fn, exp.common);
            verifyFunctionBody(exp.common, fn, pointSpan);
            exitFunction();

            return semanticContext.factory.functionExpValue(fn);
        }

        private function verifyBracketsOperator(exp:BracketsNode):Symbol {
            var obj:Symbol = verifyExpression(exp.base),
                r:Symbol,
                key:Symbol,
                index:uint;

            if (obj && obj.valueType.escapeType() is TupleType) {
                var tupleType:Symbol = obj.valueType.escapeType();
                key = verifyExpression(exp.key);
                if (key is NumberConstant) {
                    index = uint(key.valueOf());
                    if (index >= tupleType.tupleElements.length)
                        reportVerifyError('verifyErrors.indexOutOfTupleBounds', exp.key.span);
                    else r = semanticContext.factory.tupleElement(obj, index);
                }
                else r = semanticContext.factory.dynamicReferenceValue(obj);
            }
            else if (obj) {
                var propertyProxy:PropertyProxy = obj.valueType.delegate ? obj.valueType.delegate.findPropertyProxyInTree() : null;
                if (propertyProxy && semanticContext.isNameType(propertyProxy.keyType))
                    propertyProxy = undefined;

                key = verifyExpression(exp.key, VerificationContext.withExpectedType(propertyProxy ? propertyProxy.keyType : undefined));
                if (key && propertyProxy && key.valueType == propertyProxy.keyType)
                    r = semanticContext.factory.propertyProxyReferenceValue(obj, propertyProxy);
                else r = semanticContext.factory.dynamicReferenceValue(obj);
            }
            else verifyExpression(exp.key);

            return r;
        }

        private function verifyDescendantsOperator(exp:DescendantsNode):Symbol {
            var obj:Symbol = verifyExpression(exp.base);
            if (!obj) return undefined;

            var desc:Symbol = obj.testDescendantsSupport();
            if (desc) {
                if (exp.id.qualifier)
                    limitType(exp.id.qualifier, semanticContext.statics.namespaceType);
                if (exp.id is ExpressionIdNode)
                    verifyExpression(ExpressionIdNode(exp.id).key);
            }
            else reportVerifyError('verifyErrors.unsupportedDescendantsOperation', exp.span, { type: obj.valueType });
            return desc;
        }

        private function verifyUnaryOperator(exp:UnaryOperatorNode):Symbol {
            var r:Symbol,
                argument:Symbol;

            if (exp.type == Operator.AWAIT) {
                var awaitOperand:Symbol = verifyExpression(exp.argument);
                var promiseType:Symbol = awaitOperand.valueType.equalsOrInstantiationOf(semanticContext.statics.promiseType) ? awaitOperand.valueType : null;
                if (!promiseType && awaitOperand.valueType != semanticContext.statics.anyType && awaitOperand.valueType != semanticContext.statics.objectType)
                    reportVerifyError('verifyErrors.expectedPromise', exp.span);
                r = semanticContext.factory.value(promiseType ? promiseType.arguments[0] : awaitOperand.valueType);
            }
            else if (exp.type == Operator.YIELD)
                verifyExpression(exp.argument),
                r = semanticContext.factory.value(semanticContext.statics.anyType);
            else if (exp.type == Operator.DELETE)
                verifyExpression(exp.argument, VerificationContext.withFlags(VerifyFlags.DELETE_REFERENCE)),
                r = semanticContext.factory.value(semanticContext.statics.booleanType);
            else if (exp.type == Operator.LOGICAL_NOT)
                verifyExpression(exp.argument),
                r = semanticContext.factory.value(semanticContext.statics.booleanType);
            else if (exp.type == Operator.AS_IS) {
                argument = verifyExpression(exp.argument, new VerificationContext);

                // retain Observable reference
                if (argument is ReferenceValue && argument.property is VariableSlot && argument.property.valueType.equalsOrInstantiationOf(semanticContext.statics.observableType))
                    r = semanticContext.factory.referenceValue(argument.object, argument.property);
                else if (argument)
                    reportVerifyError('verifyErrors.operandMustBeObservable', exp.argument.span);
            }
            else if (exp.type == Operator.INCREMENT || exp.type == Operator.DECREMENT || exp.type == Operator.POST_INCREMENT || exp.type == Operator.POST_DECREMENT || exp.type == Operator.POSITIVE) {
                argument = verifyExpression(exp.argument, VerificationContext.withFlags(exp.type == Operator.POSITIVE ? 0 : VerifyFlags.UPDATE_TARGET));

                if (argument) {
                    if (!semanticContext.isNumericType(argument.valueType.escapeType()))
                        reportVerifyError('verifyErrors.operandMustBeNumeric', exp.argument.span);
                    r = semanticContext.factory.value(argument.valueType);
                }
            }
            else if (exp.type == Operator.TYPEOF)
                verifyExpression(exp.argument),
                r = semanticContext.factory.value(semanticContext.statics.stringType);
            else if (exp.type == Operator.VOID)
                verifyExpression(exp.argument),
                r = semanticContext.factory.undefinedConstant();
            else {
                argument = verifyExpression(exp.argument);
                if (argument) {
                    var proxy:Symbol = argument.valueType.delegate.findOperatorInTree(exp.type);
                    if (proxy || semanticContext.isNumericType(argument.valueType.escapeType()))
                        r = semanticContext.factory.value(proxy ? proxy.methodSignature.result : argument.valueType.escapeType());
                    else if (argument.valueType != semanticContext.statics.anyType)
                        reportVerifyError('verifyErrors.unsupportedOperation', exp.span, { operator: exp.type, type: argument.valueType });
                }
                r ||= semanticContext.factory.value(semanticContext.statics.anyType);
            }

            return r;
        }

        private function verifyTypeOperator(exp:TypeOperatorNode):Symbol {
            var left:Symbol = verifyExpression(exp.left),
                right:Symbol = exp.right is ArrayLiteralNode || exp.right is UnaryOperatorNode || right is NullableTypeNode || (exp.right is SimpleIdNode && SimpleIdNode(exp.right).name == '*') ? verifyTypeExpression(exp.right) : limitType(exp.right, semanticContext.statics.classType),
                r:Symbol;
            if (!right) return null;

            switch (exp.operator) {
                case 'as':
                    if (right is Type)
                        right = semanticContext.factory.nullableType(right);
                    if (left && right is Type) {
                        r = left.convertExplicit(right);
                        if (!r)
                            reportVerifyError('verifyErrors.incompatibleTypes', exp.left.span, { got: left.valueType, expected: right });
                        else if (r is ConversionValue)
                            r.byAsOperator = true;
                    }
                    else if (!(right is Type))
                        r = semanticContext.factory.value(semanticContext.statics.anyType);
                    else r = semanticContext.factory.value(right);
                    break;
                default:
                    r = semanticContext.factory.value(semanticContext.statics.booleanType); 
            }

            return r;
        }

        private function verifyBinaryOperator(exp:BinaryOperatorNode, context:VerificationContext):Symbol {
            var left:Symbol,
                right:Symbol,
                conv:Symbol,
                r:Symbol;

            if (exp.type == Operator.LOGICAL_AND || exp.type == Operator.LOGICAL_OR) {
                left = verifyExpression(exp.left, VerificationContext.withExpectedType(context.expectedType));
                right = verifyExpression(exp.right, left ? VerificationContext.withExpectedType(left.valueType) : undefined);
                if (left && right)
                    conv = right.convertImplicit(left.valueType),
                    result.setSymbolOf(exp.right, conv || right),
                    r = conv ? semanticContext.factory.value(left.valueType) : semanticContext.factory.incompatibleOperandsLogic();
            }
            else if (exp.type == Operator.EQUALS || exp.type == Operator.NOT_EQUALS) {
                left = verifyExpression(exp.left);
                if (left)
                    limitType(exp.right, left.valueType);
                r = semanticContext.factory.value(semanticContext.statics.booleanType);
            }
            else if (exp.type == Operator.STRICT_EQUALS || exp.type == Operator.STRICT_NOT_EQUALS)
                verifyExpression(exp.left),
                verifyExpression(exp.right),
                r = semanticContext.factory.value(semanticContext.statics.booleanType);
            else if (exp.type == Operator.IN) {
                right = verifyExpression(exp.right);
                if (right) {
                    var proxyIn:Symbol = semanticContext.validateHasPropertyProxy(right.valueType.delegate ? right.valueType.delegate.resolveName(semanticContext.statics.proxyHasProperty) : null);
                    if (proxyIn)
                        limitType(exp.left, proxyIn.methodSignature.params[0]);
                    else {
                        if (right.valueType != semanticContext.statics.anyType)
                            reportVerifyError('verifyErrors.unsupportedOperation', exp.span, { operator: Operator.IN, type: right.valueType });
                        verifyExpression(exp.left);
                    }
                }
                else verifyExpression(exp.left);

                r = semanticContext.factory.value(semanticContext.statics.booleanType);
            }
            else {
                left = verifyExpression(exp.left);
                if (left) {
                    right = verifyExpression(exp.right);

                    // any String operand will cause string concatenation
                    if (right && exp.type == Operator.ADD && (left.valueType == semanticContext.statics.stringType || right.valueType == semanticContext.statics.stringType))
                        r = semanticContext.factory.value(semanticContext.statics.stringType);
                    else {
                        right = limitType(exp.right, left.valueType);
                        var proxy:Symbol = left.valueType.delegate ? left.valueType.delegate.findOperatorInTree(exp.type) : null;
                        if (proxy || semanticContext.isNumericType(left.valueType.escapeType()))
                            r = semanticContext.factory.value(proxy ? proxy.methodSignature.result : left.valueType.escapeType());
                        else if (left.valueType != semanticContext.statics.anyType)
                            reportVerifyError('verifyErrors.unsupportedOperation', exp.span, { operator: exp.type, type: left.valueType });
                    }
                }
                else verifyExpression(exp.right);

                r ||= semanticContext.factory.value(semanticContext.statics.anyType);
            }

            return r;
        }

        private function verifyTernaryOperator(exp:TernaryNode, context:VerificationContext):Symbol {
            verifyExpression(exp.expression1);
            var result1:Symbol = verifyExpression(exp.expression2, VerificationContext.withExpectedType(context.expectedType)),
                result2:Symbol = verifyExpression(exp.expression3, VerificationContext.withExpectedType(context.expectedType)),
                r:Symbol;

            if (result1 && result2) {
                if (result1.convertImplicit(result2.valueType))
                    limitType(exp.expression2, result2.valueType),
                    r = semanticContext.factory.value(result2.valueType);
                else if (result2.convertImplicit(result1.valueType))
                    limitType(exp.expression3, result1.valueType),
                    r = semanticContext.factory.value(result1.valueType);
                else if (context.expectedType)
                    limitType(exp.expression2, context.expectedType),
                    limitType(exp.expression3, context.expectedType),
                    r = semanticContext.factory.value(context.expectedType);
                else reportVerifyError('verifyErrors.incompatibleTernaryResults', exp.span);
            }

            return r;
        }

        private function verifyAssignmentOperator(exp:AssignmentNode):Symbol {
            var left:Symbol,
                right:Symbol,
                r:Symbol;

            if (exp.left is ArrayLiteralNode || exp.left is ObjectLiteralNode) {
                if (exp.compound)
                    reportVerifyError('verifyErrors.assignmentMustNotBeCompound', exp.span);
                right = verifyExpression(exp.right);
                if (right)
                    verifyAssignmentDestructuringPattern(exp.left, right),
                    r = semanticContext.factory.value(right.valueType);
            }
            else {
                left = verifyExpression(exp.left, VerificationContext.withFlags(VerifyFlags.UPDATE_TARGET));
                if (left) {
                    limitType(exp.right, left.valueType);

                    if (exp.compound && exp.compound != Operator.LOGICAL_AND && exp.compound != Operator.LOGICAL_XOR && exp.compound != Operator.LOGICAL_OR && left.valueType != semanticContext.statics.anyType && !(left.valueType == semanticContext.statics.stringType && exp.compound == Operator.ADD)) {
                        var proxy:Symbol = left.valueType.delegate ? left.valueType.delegate.findOperatorInTree(exp.compound) : null;
                        if (!(proxy || semanticContext.isNumericType(left.valueType)))
                            reportVerifyError('verifyErrors.unsupportedOperation', exp.span, { operator: exp.compound, type: left.valueType });
                    }

                    r = right ? semanticContext.factory.value(right.valueType) : null;
                }
                else verifyExpression(exp.right);
            }

            return r;
        }

        private function verifyAssignmentDestructuringPattern(exp:ExpressionNode, value:Symbol):void {
            var simpleId:SimpleIdNode,
                objectLiteral:ObjectLiteralNode,
                arrayLiteral:ArrayLiteralNode,
                target:Symbol,
                nonConvertedValue:Symbol,
                nonConvertedFieldValue:Symbol;

            if (simpleId = exp as SimpleIdNode) {
                if (simpleId.qualifier)
                    reportSyntaxError('syntaxErrors.illegalDestructuringPattern', exp.span);
                target = verifyExpression(simpleId, VerificationContext.withFlags(VerifyFlags.UPDATE_TARGET));
                if (target) {
                    nonConvertedValue = value;
                    value = value.convertImplicit(target.valueType);
                    if (!value)
                        reportVerifyError('verifyErrors.incompatibleTypes', exp.span, { expected: target.valueType, got: nonConvertedValue.valueType });
                    if (value)
                        result.setSymbolOf(simpleId, semanticContext.factory.targetAndValue(target, value));
                }
            }
            else if (objectLiteral = exp as ObjectLiteralNode) {
                for each (var fieldOrSpreadOp:Node in objectLiteral.fields) {
                    if (fieldOrSpreadOp is SpreadOperatorNode) {
                        reportSyntaxError('syntaxErrors.illegalDestructuringPattern', fieldOrSpreadOp.span);
                        continue;
                    }
                    var field:ObjectFieldNode = ObjectFieldNode(fieldOrSpreadOp);

                    if (!field.computed && field.key is SimpleIdNode) {
                        var fieldValue:Symbol = resolveReference(value, QualifiedIdNode(field.key), new VerificationContext);

                        if (field.value)
                            verifyAssignmentDestructuringPattern(field.value, fieldValue ? fieldValue : semanticContext.factory.value(semanticContext.statics.anyType));
                        else {
                            target = resolveReference(value, QualifiedIdNode(field.key), new VerificationContext);
                            if (target && target.readOnly)
                                reportVerifyError('verifyErrors.referenceIsReadOnly', field.key.span);
                            if (target && fieldValue) {
                                nonConvertedFieldValue = fieldValue;
                                fieldValue = fieldValue.convertImplicit(target.valueType);
                                if (!fieldValue)
                                    reportVerifyError('verifyErrors.incompatibleTypes', field.span, { expected: target.valueType, got: nonConvertedFieldValue.valueType });
                            }
                        }

                        if (fieldValue)
                            result.setSymbolOf(field, semanticContext.factory.targetAndValue(target, fieldValue));
                    }
                    else reportSyntaxError('syntaxErrors.illegalDestructuringPattern', field.span);
                }
                result.setSymbolOf(exp, value);
            }
            else if (arrayLiteral = exp as ArrayLiteralNode) {
                var tupleType:Symbol = value.valueType.escapeType() is TupleType ? value.valueType.escapeType() : null,
                    subExp:ExpressionNode,
                    elementType:Symbol;
                if (tupleType) {
                    var index:uint;

                    if (arrayLiteral.elements.length > tupleType.tupleElements.length)
                        reportVerifyError('verifyErrors.wrongNumberOfTupleElements', exp.span, { number: tupleType.tupleElements.length });

                    for each (subExp in arrayLiteral.elements) {
                        if (subExp is SpreadOperatorNode) {
                            reportSyntaxError('syntaxErrors.illegalDestructuringPattern', subExp.span);
                            ++index;
                            continue;
                        }
                        if (subExp)
                            verifyAssignmentDestructuringPattern(subExp, index < tupleType.tupleElements.length ? semanticContext.factory.tupleElement(value, index) : semanticContext.factory.value(semanticContext.statics.anyType));
                        ++index;
                    }
                }
                else if (value.valueType == semanticContext.statics.anyType) {
                    for each (subExp in arrayLiteral.elements) {
                        if (subExp is SpreadOperatorNode) {
                            verifyAssignmentDestructuringPattern(SpreadOperatorNode(subExp).expression, semanticContext.factory.value(semanticContext.statics.arrayType));
                            continue;
                        }
                        if (subExp)
                            verifyAssignmentDestructuringPattern(subExp, semanticContext.factory.value(semanticContext.statics.anyType));
                    }
                }
                // go by Proxy
                else {
                    var arrayPropertyProxy:PropertyProxy = value.valueType.delegate ? value.valueType.delegate.findPropertyProxyInTree() : null;
                    arrayPropertyProxy = arrayPropertyProxy && semanticContext.isNumericType(arrayPropertyProxy.keyType) ? arrayPropertyProxy : null;

                    if (arrayPropertyProxy) {
                        elementType = arrayPropertyProxy.valueType;
                        for each (subExp in arrayLiteral.elements) {
                            if (subExp is SpreadOperatorNode) {
                                verifyAssignmentDestructuringPattern(SpreadOperatorNode(subExp).expression, semanticContext.factory.value(semanticContext.statics.arrayType));
                                continue;
                            }
                            if (subExp)
                                verifyAssignmentDestructuringPattern(subExp, semanticContext.factory.value(elementType));
                        }
                    }
                    else reportVerifyError('verifyErrors.arrayDestructuringNotSupported', exp.span, { type: value.valueType });
                }

                result.setSymbolOf(exp, value);
            }
            else reportSyntaxError('syntaxErrors.illegalDestructuringPattern', exp.span);
        }

        private function verifyXMLList(exp:XMLListNode):void {
            for each (var subExp:XMLNode in exp.nodes)
                verifyXML(subExp);
        }

        private function verifyXML(exp:XMLNode):void {
            var element:XMLElementNode,
                text:XMLTextNode;

            if (element = exp as XMLElementNode) {
                if (element.openName is ExpressionNode)
                    verifyExpression(ExpressionNode(element.openName));
                if (element.closeName is ExpressionNode)
                    verifyExpression(ExpressionNode(element.closeName));
                for each (var attrib:XMLAttributeNode in element.attributes)
                    if (attrib.value is ExpressionNode)
                        verifyExpression(ExpressionNode(attrib.value));
                for each (var child:XMLNode in element.childNodes)
                    verifyXML(child);
            }
            else if (text = exp as XMLTextNode) {
                if (text.content is ExpressionNode)
                    verifyExpression(ExpressionNode(text.content));
            }
        }

        private function resolveMethodSignature(common:FunctionCommonNode, declarationSpan:Span, baseSignature:MethodSignature = null, forFunctionExp:Boolean = false):MethodSignature {
            var r:MethodSignature;

            if (baseSignature)
                r = resolveMethodSignatureWithBase(common, declarationSpan, baseSignature);
            else {
                var params:Array,
                    optParams:Array,
                    hasRest:Boolean,
                    fnResult:Symbol,
                    binding:VarBindingNode,
                    type:Symbol,
                    typeExp:ExpressionNode;

                if (common.params) {
                    params = [];
                    for each (binding in common.params) {
                        typeExp = binding.pattern.getPatternTypeExpression();
                        type = typeExp ? verifyTypeExpression(typeExp) : null;
                        if (!typeExp && _compilerOptions.warnings.noTypeDeclaration !== false && !forFunctionExp)
                            warn('warnings.missingTypeDeclaration', binding.pattern.span);
                        params.push(type || semanticContext.statics.anyType);
                    }
                }

                if (common.optParams) {
                    optParams = [];
                    for each (binding in common.optParams) {
                        typeExp = binding.pattern.getPatternTypeExpression();
                        type = typeExp ? verifyTypeExpression(typeExp) : null;
                        if (!typeExp && _compilerOptions.warnings.noTypeDeclaration !== false && !forFunctionExp)
                            warn('warnings.missingTypeDeclaration', binding.pattern.span);
                        optParams.push(type || semanticContext.statics.anyType);
                    }
                }

                if (common.rest) hasRest = true;

                if (common.result)
                    fnResult = verifyTypeExpression(common.result) || semanticContext.statics.anyType;
                else if (common.flags & FunctionFlags.CONSTRUCTOR)
                    fnResult = semanticContext.statics.voidType;
                else {
                    if (_compilerOptions.warnings.noTypeDeclaration !== false && !forFunctionExp)
                        warn('verifyErrors.missingReturnTypeDeclaration', declarationSpan);
                    fnResult = semanticContext.statics.anyType;
                }

                if (common.flags & FunctionFlags.YIELD)
                    fnResult = semanticContext.statics.generatorType;
                else if (common.flags & FunctionFlags.AWAIT) {
                    fnResult = fnResult.escapeType();
                    if (!fnResult.equalsOrInstantiationOf(semanticContext.statics.promiseType))
                        fnResult = semanticContext.factory.instantiatedType(semanticContext.statics.promiseType, [fnResult]);
                }

                r = semanticContext.factory.methodSignature(params, optParams, hasRest, fnResult);
            }

            return r;
        }

        private function resolveMethodSignatureWithBase(common:FunctionCommonNode, declarationSpan:Span, baseSignature:MethodSignature):MethodSignature {
            var invalidated:Boolean,
                i:uint,
                j:uint,
                paramList:Array = common.params,
                optParamList:Array = common.optParams,
                restId:RestParamNode = common.rest,
                type:Symbol,
                binding:VarBindingNode,
                typedId:TypedIdNode;

            p: while (1) {
                if (paramList) {
                    if (!baseSignature.params || paramList.length != baseSignature.params.length) {
                        invalidated = true;
                        break;
                    }
                    for each (binding in paramList) {
                        typedId = binding.pattern as TypedIdNode;
                        if (typedId && typedId.type) {
                            type = verifyTypeExpression(typedId.type);
                            if (type && type != baseSignature.params[i]) {
                                invalidated = true;
                                break p;
                            }
                        }
                    }
                    paramList = null;
                }
                else if (optParamList) {
                    if (!baseSignature.optParams || optParamList.length != baseSignature.optParams.length) {
                        invalidated = true;
                        break p;
                    }
                    for each (binding in optParamList) {
                        typedId = binding.pattern as TypedIdNode;
                        if (typedId && typedId.type) {
                            type = verifyTypeExpression(typedId.type);
                            if (type && type != baseSignature.optParams[i]) {
                                invalidated = true;
                                break p;
                            }
                        }
                    }
                    optParamList = null;
                }
                else if (restId) {
                    if (!baseSignature.hasRest)
                        invalidated = true;
                    restId = null;
                }
                else break;
            }
            if (common.result) {
                type = verifyTypeExpression(common.result);
                if (type && type != baseSignature.result)
                    invalidated = true;
            }
            if (invalidated)
                reportVerifyError('verifyErrors.functionSignatureMustMatch', declarationSpan, { mustMatch: baseSignature });

            return baseSignature;
        }

        private function fillMethodActivation(common:FunctionCommonNode, signature:MethodSignature):void {
            var activation:Symbol = result.symbolOf(common).activation,
                internalNs:Symbol = scopeChain.getLexicalReservedNamespace('internal'),
                i:uint,
                type:Symbol,
                binding:VarBindingNode;

            enterFunction(activation, null, null);
            scopeChain.enterFrame(activation);

            for each (binding in common.params)
                type = signature.params && i < signature.params.length ? signature.params[i] : semanticContext.statics.anyType,
                verifyDestructuringPattern1(binding.pattern, false, internalNs, activation.names),
                verifyDestructuringPattern2(binding.pattern, semanticContext.factory.value(type)),
                ++i;

            i = 0;

            for each (binding in common.optParams) {
                type = signature.optParams && i < signature.optParams.length ? signature.optParams[i] : semanticContext.statics.anyType;
                verifyDestructuringPattern1(binding.pattern, false, internalNs, activation.names);

                var constant:Symbol;
                if (binding.initialiser)
                    constant = limitConstantType(binding.initialiser, type);

                verifyDestructuringPattern2(binding.pattern, constant || semanticContext.factory.value(type));
                ++i;
            }

            if (common.rest) {
                var name:Symbol = semanticContext.factory.name(internalNs, common.rest.name);
                var restVar:Symbol = semanticContext.factory.variableSlot(name, false, semanticContext.statics.anyType);
                result.setSymbolOf(common.rest, restVar);
                if (!activation.names.hasName(name))
                    activation.names.defineName(name, restVar);
            }

            scopeChain.exitFrame();
            exitFunction();
        }

        private function verifyFunctionBody(common:FunctionCommonNode, fn:Symbol, declarationSpan:Span):void {
            var signature:MethodSignature = fn.methodSignature;
            var activation:Symbol = fn.activation;

            enterFunction(null, fn, common);
            scopeChain.enterFrame(activation);

            if (common.body is BlockNode) {
                var block:BlockNode = BlockNode(common.body);
                verifyStatement(block);

                var r:Symbol = signature.result;
                if (r != semanticContext.statics.voidType && r != semanticContext.statics.anyType && !(common.flags & FunctionFlags.AWAIT) && !(common.flags & FunctionFlags.YIELD) && !verifyReturnPath(block))
                    reportVerifyError('verifyErrors.notAllPathsReturnValue', declarationSpan);
            }
            else if (common.body) {
                if (common.flags & FunctionFlags.AWAIT)
                    reportSyntaxError('syntaxErrors.awaitMustAppearWithinBlock', declarationSpan);
                else if (common.flags & FunctionFlags.YIELD)
                    reportSyntaxError('syntaxErrors.yieldMustAppearWithinBlock', declarationSpan);
                limitType(ExpressionNode(common.body), signature.result);
            }

            scopeChain.exitFrame();
            exitFunction();
        }

        private function verifyReturnPath(directive:DirectiveNode) {
            var directives:Array,
                subdirective:DirectiveNode,
                block:BlockNode,
                tryStatement:TryStatementNode,
                ifStatement:IfStatementNode,
                switchStatement:SwitchStatementNode,
                i:uint;

            if (block = directive as BlockNode) {
                directives = block.directives;
                if (directives.length == 0) return false;
                for (i = 0; i != directives.length; ++i)
                    if (verifyReturnPath(directives[i]))
                        return true;
            }
            else if (directive is ReturnNode || directive is ThrowNode)
                return true;
            else if (tryStatement = directive as TryStatementNode) {
                if (!verifyReturnPath(tryStatement.mainElement))
                    return false;
                if (tryStatement.finallyElement)
                    return verifyReturnPath(tryStatement.finallyElement);
                for each (var catchElement:CatchNode in tryStatement.catchElements)
                    if (!verifyReturnPath(catchElement.block))
                        return false;
                return true;
            }
            else if (ifStatement = directive as IfStatementNode)
                return ifStatement.alternative ? verifyReturnPath(ifStatement.consequent) && verifyReturnPath(ifStatement.alternative) : false;
            else if (switchStatement = directive as SwitchStatementNode)
                for each (var caseElement:SwitchCaseNode in switchStatement.caseNodes)
                    if (!caseElement.expression && caseElement.directives && caseElement.directives.length != 0 && verifyReturnPath(caseElement.directives[caseElement.directives.length - 1]))
                        return true;

            return false;
        }

        private function verifyDestructuringPattern1(exp:Node, readOnly:Boolean, qual:Symbol, intoNames:Names):void {
            var simpleId:SimpleIdNode,
                typedId:TypedIdNode,
                objectLiteral:ObjectLiteralNode,
                arrayLiteral:ArrayLiteralNode,
                variable:Symbol,
                name:Symbol,
                k:Symbol;

            if ((simpleId = exp as SimpleIdNode) || (typedId = exp as TypedIdNode)) {
                if (simpleId && simpleId.qualifier)
                    reportSyntaxError('syntaxErrors.illegalDestructuringPattern', exp.span);
                name = semanticContext.factory.name(qual, simpleId ? simpleId.name : typedId.name);
                variable = semanticContext.factory.variableSlot(name, readOnly, null);
                k = intoNames.resolveName(name);
                if (k) {
                    if (k is VariableSlot && _compilerOptions.allowDuplicates)
                        variable = k;
                    else reportVerifyError('verifyErrors.namespaceConflict', exp.span, { 'namespace': qual });
                }
                else intoNames.defineName(name, variable);
                result.setSymbolOf(exp, semanticContext.factory.targetAndValue(variable, null));
            }
            else if (objectLiteral = exp as ObjectLiteralNode) {
                for each (var fieldOrSpreadOp:Node in objectLiteral.fields) {
                    if (fieldOrSpreadOp is SpreadOperatorNode) {
                        reportSyntaxError('syntaxErrors.illegalDestructuringPattern', fieldOrSpreadOp.span);
                        continue;
                    }
                    var field:ObjectFieldNode = ObjectFieldNode(fieldOrSpreadOp);

                    if (!field.computed && !!(simpleId = field.key as SimpleIdNode)) {
                        variable = null;
                        if (field.value)
                            verifyDestructuringPattern1(field.value, readOnly, qual, intoNames);
                        else {
                            name = semanticContext.factory.name(qual, simpleId.name);
                            variable = semanticContext.factory.variableSlot(name, readOnly, null);
                            k = intoNames.resolveName(name);
                            if (k) {
                                if (k is VariableSlot && _compilerOptions.allowDuplicates)
                                    variable = k;
                                else reportVerifyError('verifyErrors.namespaceConflict', simpleId.span, { 'namespace': qual });
                            }
                            else intoNames.defineName(name, variable);
                        }
                        result.setSymbolOf(field, semanticContext.factory.targetAndValue(variable, null));
                    }
                    else reportSyntaxError('syntaxErrors.illegalDestructuringPattern', field.span);
                }
            }
            else if (arrayLiteral = exp as ArrayLiteralNode) {
                var subExp:ExpressionNode;
                for each (subExp in arrayLiteral.elements) {
                    if (subExp is SpreadOperatorNode) {
                        verifyDestructuringPattern1(SpreadOperatorNode(subExp).expression, readOnly, qual, intoNames);
                        continue;
                    }
                    if (subExp)
                        verifyDestructuringPattern1(subExp, readOnly, qual, intoNames);
                }
            }
            else reportSyntaxError('syntaxErrors.illegalDestructuringPattern', exp.span);
        }

        private function verifyDestructuringPattern2(exp:Node, value:Symbol, context:VerificationContext = undefined):void {
            context ||= new VerificationContext;

            var simpleId:SimpleIdNode,
                typedId:TypedIdNode,
                objectLiteral:ObjectLiteralNode,
                arrayLiteral:ArrayLiteralNode,
                target:Symbol,
                targetAndValue:Symbol,
                nonConvertedValue:Symbol,
                nonConvertedFieldValue:Symbol;

            if ((simpleId = exp as SimpleIdNode) || (typedId = exp as TypedIdNode)) {
                targetAndValue = result.symbolOf(exp);
                target = targetAndValue.target;
                target.valueType = typedId && typedId.type ? verifyTypeExpression(typedId.type) : null;
                if (target.valueType) {
                    nonConvertedValue = value;
                    value = value.convertImplicit(target.valueType);
                    if (!value)
                        reportVerifyError('verifyErrors.incompatibleTypes', exp.span, { expected: target.valueType, got: nonConvertedValue.valueType });
                }
                else target.valueType = value.valueType;

                target.valueType = context.turnObservables ? semanticContext.factory.instantiatedType(semanticContext.statics.observableType, [target.valueType]) : target.valueType;
                targetAndValue.value = value;
            }
            else if (objectLiteral = exp as ObjectLiteralNode) {
                for each (var fieldOrSpreadOp:Node in objectLiteral.fields) {
                    if (fieldOrSpreadOp is SpreadOperatorNode) {
                        reportSyntaxError('syntaxErrors.illegalDestructuringPattern', fieldOrSpreadOp.span);
                        continue;
                    }
                    var field:ObjectFieldNode = ObjectFieldNode(fieldOrSpreadOp);

                    if (!field.computed && field.key is SimpleIdNode) {
                        var fieldValue:Symbol = resolveReference(value, QualifiedIdNode(field.key), new VerificationContext);
                        targetAndValue = result.symbolOf(field);
                        target = targetAndValue.target;

                        if (field.value)
                            verifyDestructuringPattern2(field.value, fieldValue ? fieldValue : semanticContext.factory.value(semanticContext.statics.anyType), context);
                        else if (target && fieldValue)
                            target.valueType = fieldValue.valueType;

                        if (fieldValue)
                            targetAndValue.value = fieldValue;
                    }
                }
                result.setSymbolOf(exp, value);
            }
            else if (arrayLiteral = exp as ArrayLiteralNode) {
                var tupleType:Symbol = value.valueType.escapeType() is TupleType ? value.valueType.escapeType() : null,
                    subExp:ExpressionNode,
                    elementType:Symbol;
                // tuple
                if (tupleType) {
                    var index:uint;

                    if (arrayLiteral.elements.length > tupleType.tupleElements.length)
                        reportVerifyError('verifyErrors.wrongNumberOfTupleElements', exp.span, { number: tupleType.tupleElements.length });

                    for each (subExp in arrayLiteral.elements) {
                        if (subExp is SpreadOperatorNode) {
                            reportSyntaxError('syntaxErrors.illegalDestructuringPattern', subExp.span);
                            ++index;
                            continue;
                        }
                        if (subExp)
                            verifyDestructuringPattern2(subExp, index < tupleType.tupleElements.length ? semanticContext.factory.tupleElement(value, index) : semanticContext.factory.value(semanticContext.statics.anyType), context);
                        ++index;
                    }
                }
                // go by Proxy
                else {
                    var arrayPropertyProxy:PropertyProxy = value.valueType.delegate ? value.valueType.delegate.findPropertyProxyInTree() : null;
                    arrayPropertyProxy = arrayPropertyProxy && semanticContext.isNumericType(arrayPropertyProxy.keyType) ? arrayPropertyProxy : null;

                    if (arrayPropertyProxy) {
                        elementType = arrayPropertyProxy.valueType;
                        for each (subExp in arrayLiteral.elements) {
                            if (subExp is SpreadOperatorNode) {
                                verifyDestructuringPattern2(SpreadOperatorNode(subExp).expression, semanticContext.factory.value(semanticContext.statics.arrayType), context);
                                continue;
                            }
                            if (subExp)
                                verifyDestructuringPattern2(subExp, semanticContext.factory.value(elementType), context);
                        }
                    }
                    else {
                        if (value.valueType != semanticContext.statics.anyType)
                            reportVerifyError('verifyErrors.arrayDestructuringNotSupported', exp.span, { type: value.valueType });
                        for each (subExp in arrayLiteral.elements) {
                            if (subExp is SpreadOperatorNode) {
                                verifyDestructuringPattern2(SpreadOperatorNode(subExp).expression, semanticContext.factory.value(semanticContext.statics.arrayType), context);
                                continue;
                            }
                            if (subExp)
                                verifyDestructuringPattern2(subExp, semanticContext.factory.value(semanticContext.statics.anyType), context);
                        }
                    }
                }

                result.setSymbolOf(exp, value);
            }
        }

        public function verifyPrograms(programs:Array):void {
            var packageObject:Symbol,
                packageFrame:Symbol,
                pd:PhaseDistributor,
                program:ProgramNode,
                packageDefinition:PackageDefinitionNode;
            pd = new PhaseDistributor(this);

            for each (program in programs)
                for each (packageDefinition in program.packages)
                    enterScript(packageDefinition.script),
                    packageObject = semanticContext.factory.packageSymbol(packageDefinition.id),
                    packageFrame = semanticContext.factory.packageFrame(packageObject),
                    packageFrame.defaultNamespace = packageObject.publicNs,
                    result.setSymbolOf(packageDefinition, packageObject),
                    result.setSymbolOf(packageDefinition.block, packageFrame),
                    exitScript();

            while (pd.hasRemaining) {
                for each (program in programs)
                    for each (packageDefinition in program.packages)
                        enterScript(packageDefinition.script),
                        scopeChain.enterFrame(result.symbolOf(packageDefinition.block)),
                        pd.verify(packageDefinition.block.directives),
                        scopeChain.exitFrame(),
                        exitScript();
                pd.nextPhase();
            }

            for each (program in programs) {
                if (!program.directives)
                    continue;
                enterScript(program.script);

                var activation:Symbol = semanticContext.factory.activation(semanticContext.statics.anyType);
                activation.internalNs = semanticContext.factory.reservedNamespaceConstant('internal', null);
                activation.defaultNamespace = activation.internalNs;
                activation.openNamespaceList.addItem(activation.internalNs);
                result.setSymbolOf(program, activation);

                enterFunction(activation, null, null);
                scopeChain.enterFrame(activation);
                verifyDirectives(program.directives);
                scopeChain.exitFrame();
                exitFunction();

                exitScript();
            }

            resolveForeignCodeDescription();
        }

        private function resolveForeignCodeDescription():void {
            if (_compilerOptions.foreign)
                return;
            for (var baseExpSrc:String in _compilerOptions.foreign) {
                var parser:Parser = new Parser(baseExpSrc);
                var baseExp:ExpressionNode = parser.parseExpression(false, OperatorPrecedence.POSTFIX_OPERATOR);
                enterScript(parser.script);
                var baseSymbol:Symbol = baseExp ? verifyExpression(baseExp) : null;
                exitScript();

                if (!baseSymbol)
                    continue;
                if (baseSymbol is ReferenceValue && baseSymbol.property is MethodSlot)
                    findMethod(baseSymbol, _compilerOptions.foreign[baseExpSrc]);
                else if (baseSymbol is ReferenceValue && baseSymbol.property is VirtualSlot)
                    findVirtualSlot(baseSymbol, _compilerOptions.foreign[baseExpSrc]);
                else if (baseSymbol is Type)
                    findType(baseSymbol, _compilerOptions.foreign[baseExpSrc]);
            }

            function findType(type:Symbol, description:*):void {
                if (description.foreignName)
                    type.foreignName = description.foreignName;
                for (var name:String in description.instance) {
                    var instanceTrait:Symbol = type.delegate ? type.delegate.resolveMultiName(null, name) : null;
                    if (instanceTrait is MethodSlot)
                        findMethod(instanceTrait, description.instance[name], type.delegate);
                    else if (instanceTrait is VirtualSlot)
                        findVirtualSlot(instanceTrait, description.instance[name], type.delegate);
                }
            }

            function findMethod(fn:Symbol, description:*, delegate:Symbol = null):void {
                if (description.foreignName)
                    fn.foreignName = description.foreignName;
                for (var paramSeqSrc:String in description.optimizations) {
                    var parser:Parser = new Parser(paramSeqSrc)
                    var typeExpList:ListExpressionNode = parser.parseTypeExpressionList() as ListExpressionNode;
                    var paramSeq:Array = typeExpList ? verifyTypeExpressionList(typeExpList) : null;
                    var replName:String = description.optimizations[paramSeqSrc];
                    var replFn:Symbol = (delegate ? delegate.resolveMultiName(null, replName) : fn.definedIn.resolveMultiName(null, replName)) as MethodSlot;
                    var optimization:MethodOptimization;
                    if (paramSeq && replFn)
                        optimization = new MethodOptimization,
                        optimization.argumentTypes = paramSeq,
                        optimization.replacementMethod = replFn,
                        fn.methodOptimizations ||= [],
                        fn.methodOptimizations.push(optimization);
                }
            }

            function findVirtualSlot(slot:Symbol, description:*, delegate:Symbol = null):void {
                if (description.getter)
                    findMethod(description.getter, description.getter, delegate);
                if (description.setter)
                    findMethod(description.setter, description.setter, delegate);
            }
        }

        public function verifyTypeExpressionList(list:ListExpressionNode):Array {
            var r:Array = [];
            for each (var exp:ExpressionNode in list.expressions) {
                var t:Symbol = verifyTypeExpression(exp);
                if (!t) return null;
                r.push(t);
            }
            return r;
        }

        private function verifyStatement(statement:StatementNode):void {
            var bindings:Array;

            if (statement is ExpressionStatementNode)
                verifyExpression(ExpressionStatementNode(statement).expression);
            else if (statement.isIterationStatement) {
                if (statement is ForStatementNode)
                    verifyForStatement(ForStatementNode(statement));
                else if (statement is ForInStatementNode)
                    verifyForInStatement(ForInStatementNode(statement));
                else if (statement is WhileStatementNode) {
                    var whileStatement:WhileStatementNode = WhileStatementNode(statement);
                    verifyExpression(whileStatement.expression);
                    verifyStatement(whileStatement.substatement);
                }
                else if (statement is DoStatementNode)
                    verifyStatement(DoStatementNode(statement).substatement),
                    verifyExpression(DoStatementNode(statement).expression);
            }
            else if (statement is LabeledStatementNode)
                verifyStatement(LabeledStatementNode(statement).substatement);
            else if (statement is BlockNode) {
                var blockFrame:Symbol = semanticContext.factory.frame();
                result.setSymbolOf(statement, blockFrame);
                blockFrame.internalNs = scopeChain.getLexicalReservedNamespace('internal');
                blockFrame.defaultNamespace = blockFrame.internalNs;
                scopeChain.enterFrame(blockFrame);
                verifyDirectives(BlockNode(statement).directives);
                scopeChain.exitFrame();
            }
            else if (statement is BreakNode) {
            }
            else if (statement is ContinueNode) {
            }
            else if (statement is ReturnNode)
                verifyReturnStatement(ReturnNode(statement));
            else if (statement is DefaultXMLNamespaceStatementNode)
                limitType(DefaultXMLNamespaceStatementNode(statement).expression, semanticContext.statics.namespaceType);
            else if (statement is EmptyStatementNode) {
            }
            else if (statement is IfStatementNode) {
                var ifStatement:IfStatementNode = IfStatementNode(statement);
                verifyExpression(ifStatement.expression);
                verifyStatement(ifStatement.consequent);
                if (ifStatement.alternative)
                    verifyStatement(ifStatement.alternative);
            }
            else if (statement is SuperStatementNode)
                verifySuperStatement(SuperStatementNode(statement));
            else if (statement is SwitchStatementNode)
                verifySwitchStatement(SwitchStatementNode(statement));
            else if (statement is SwitchTypeStatementNode)
                verifySwitchTypeStatement(SwitchTypeStatementNode(statement));
            else if (statement is ThrowNode)
                verifyExpression(ThrowNode(statement).expression);
            else if (statement is TryStatementNode)
                verifyTryStatement(TryStatementNode(statement));
            else if (statement is WithStatementNode)
                verifyWithStatement(WithStatementNode(statement));
            else throw new Error('Unprocessed statement ' + statement + '.');
        }

        private function verifyForStatement(statement:ForStatementNode):void {
            var frame:Symbol = semanticContext.factory.frame();
            result.setSymbolOf(statement, frame);
            scopeChain.enterFrame(frame);

            if (statement.expression1) {
                if (statement.expression1 is SimpleVarDeclarationNode) {
                    var decl:SimpleVarDeclarationNode = SimpleVarDeclarationNode(statement.expression1);
                    var binding:VarBindingNode;
                    for each (binding in decl.bindings)
                        verifyDestructuringPattern1(binding.pattern, decl.readOnly, scopeChain.getLexicalReservedNamespace('internal'), frame.names);
                    for each (binding in decl.bindings)
                        verifyVarBinding(binding);
                }
                else verifyExpression(ExpressionNode(statement.expression1));
            }

            if (statement.expression2) verifyExpression(statement.expression2);
            if (statement.expression3) verifyExpression(statement.expression3);

            verifyStatement(statement.substatement);
            scopeChain.exitFrame();
        }

        private function verifyForInStatement(statement:ForInStatementNode):void {
            var frame:Symbol = semanticContext.factory.frame();
            result.setSymbolOf(statement, frame);
            scopeChain.enterFrame(frame);

            var iterable:Symbol = verifyExpression(statement.right),
                itemType:Symbol;
            if (iterable) {
                // Generator or Range
                if (iterable.valueType.escapeType() == semanticContext.statics.generatorType || iterable.valueType.escapeType() == semanticContext.statics.rangeType)
                    itemType = semanticContext.statics.anyType;
                // proxy
                else {
                    var nextNameIndexProxy:Symbol = semanticContext.validateNextNameIndexProxy(iterable.valueType.delegate ? iterable.valueType.delegate.resolveName(semanticContext.statics.proxyNextNameIndex) : null),
                        nextNameOrValueProxy:Symbol = semanticContext.validateNextNameOrValueProxy(iterable.valueType.delegate ? iterable.valueType.delegate.resolveName(statement.isEach ? semanticContext.statics.proxyNextValue : semanticContext.statics.proxyNextName) : null);

                    if ((!nextNameIndexProxy || !nextNameOrValueProxy || nextNameIndexProxy.methodSignature.result != nextNameOrValueProxy.methodSignature.params[0]) && iterable.valueType != semanticContext.statics.anyType)
                        reportVerifyError('verifyErrors.unsupportedIterationWithType', statement.right.span, { type: iterable.valueType });
                    else if (iterable.valueType == semanticContext.statics.anyType)
                        itemType = semanticContext.statics.anyType;
                    else itemType = nextNameOrValueProxy.methodSignature.result;
                }
            }
            itemType ||= semanticContext.statics.anyType;

            var decl:SimpleVarDeclarationNode = statement.left as SimpleVarDeclarationNode;
            if (decl) {
                var binding:VarBindingNode = decl.bindings[0];
                verifyDestructuringPattern1(binding.pattern, decl.readOnly, scopeChain.getLexicalReservedNamespace('internal'), frame.names);
                verifyDestructuringPattern2(binding.pattern, semanticContext.factory.value(itemType));
            }
            else {
                var target:Symbol = verifyExpression(ExpressionNode(statement.left), VerificationContext.withFlags(VerifyFlags.UPDATE_TARGET)),
                    targetConv:Symbol;
                if (target && !(targetConv = semanticContext.factory.value(itemType).convertImplicit(target.valueType)))
                    reportVerifyError('verifyErrors.wrongIterationItemType', statement.left.span, { type: itemType });
            }

            verifyStatement(statement.substatement); 
            scopeChain.exitFrame();
        }

        private function verifyTryStatement(statement:TryStatementNode):void {
            verifyStatement(statement.mainElement);
            for each (var catchElement:CatchNode in statement.catchElements) {
                var frame:Symbol = semanticContext.factory.frame();
                result.setSymbolOf(catchElement.block, frame);
                frame.defaultNamespace = scopeChain.getLexicalReservedNamespace('internal');
                verifyDestructuringPattern1(catchElement.pattern, false, frame.defaultNamespace, frame.names);

                var exceptionType:Symbol,
                    patternTypeExpr:ExpressionNode = catchElement.pattern.getPatternTypeExpression();
                if (patternTypeExpr)
                    exceptionType = verifyTypeExpression(patternTypeExpr);
                else reportVerifyError('verifyErrors.untypedException', catchElement.pattern.span);
                exceptionType ||= semanticContext.statics.anyType;

                verifyDestructuringPattern2(catchElement.pattern, semanticContext.factory.value(exceptionType));

                scopeChain.enterFrame(frame);
                verifyDirectives(catchElement.block.directives);
                scopeChain.exitFrame();
            }

            if (statement.finallyElement)
                verifyStatement(statement.finallyElement);
        }

        private function verifySwitchStatement(statement:SwitchStatementNode):void {
            var discriminant:Symbol = verifyExpression(statement.discriminant);
            for each (var caseElement:SwitchCaseNode in statement.caseNodes) {
                if (caseElement.expression) {
                    if (discriminant)
                        limitType(caseElement.expression, discriminant.valueType);
                    else verifyExpression(caseElement.expression);
                }
                if (caseElement.directives)
                    verifyDirectives(caseElement.directives);
            }
        }

        private function verifySwitchTypeStatement(statement:SwitchTypeStatementNode):void {
            var discriminant:Symbol = verifyExpression(statement.discriminant),
                conv:Symbol;
            for each (var caseElement:SwitchTypeCaseNode in statement.caseNodes) {
                var frame:Symbol = semanticContext.factory.frame();
                result.setSymbolOf(caseElement.block, frame);
                frame.defaultNamespace = scopeChain.getLexicalReservedNamespace('internal');
                verifyDestructuringPattern1(caseElement.pattern, false, frame.defaultNamespace, frame.names);

                var matchType:Symbol,
                    patternTypeExpr:ExpressionNode = caseElement.pattern.getPatternTypeExpression();
                if (patternTypeExpr)
                    matchType = verifyTypeExpression(patternTypeExpr);
                else reportVerifyError('verifyErrors.untypedSwitchTypeCase', caseElement.pattern.span);
                matchType ||= semanticContext.statics.anyType;

                verifyDestructuringPattern2(caseElement.pattern, semanticContext.factory.value(matchType));

                scopeChain.enterFrame(frame);
                verifyDirectives(caseElement.block.directives);
                scopeChain.exitFrame();
            }
        }

        private function verifySuperStatement(statement:SuperStatementNode):void {
            var enclosingClass:Symbol = scopeChain.currentFrame.parentFrame.parentFrame.symbol;
            var superClass:Symbol = enclosingClass.superType;
            if (!superClass)
                throw new Error('Super statement found no super class.');
            var constructorFn:Symbol;
            for (var class2:Symbol = superClass; class2; class2 = class2.superType)
                if (constructorFn = class2.constructorMethod)
                    break;
            if (!constructorFn)
                throw new Error('Super statement: super class has no constructor definition.');
            verifyCallArguments(statement.arguments, statement, constructorFn.methodSignature);
            result.setSymbolOf(statement, constructorFn);
        }

        private function verifyWithStatement(statement:WithStatementNode):void {
            var object:Symbol = verifyExpression(statement.expression);
            if (object) {
                var frame:Symbol = semanticContext.factory.withFrame(object.valueType);
                result.setSymbolOf(statement, frame);
                scopeChain.enterFrame(frame);
                verifyStatement(statement.substatement);
                scopeChain.exitFrame();
            }
        }

        private function verifyReturnStatement(statement:ReturnNode):void {
            var signature:MethodSignature = _openedFunction && _openedFunction.methodSlot ? _openedFunction.methodSlot.methodSignature : null;
            var returnType:Symbol = signature ? signature.result : null;

            if (statement.expression) {
                // return at generator function
                if (returnType && (_openedFunction.methodSlot.methodFlags & MethodFlags.YIELD))
                    verifyExpression(statement.expression);
                // return at asynchronous function
                else if (returnType && (_openedFunction.methodSlot.methodFlags & MethodFlags.AWAIT))
                    limitType(statement.expression, returnType.arguments[0]);
                else if (returnType)
                    limitType(statement.expression, returnType);
                else verifyExpression(statement.expression);
            }
            else if (returnType && returnType != semanticContext.statics.voidType && returnType != semanticContext.statics.anyType && !(_openedFunction.methodSlot.methodFlags & MethodFlags.YIELD) && !(_openedFunction.methodSlot.methodFlags & MethodFlags.AWAIT && returnType != semanticContext.statics.promiseAnyType))
                reportVerifyError('verifyErrors.returnStatementMustReturnValue', statement.span);
        }

        public function verifyTypeExpression(exp:ExpressionNode):Symbol {
            var r:Symbol = result.symbolOf(exp);
            if (r || result.nodeIsAlreadyVerified(exp))
                return r;

            var type:Symbol;

            if (exp is QualifiedIdNode) {
                if (!(exp is SimpleIdNode && !QualifiedIdNode(exp).qualifier && SimpleIdNode(exp).name == '*')) {
                    type = verifyConstantExpression(exp);
                    if (type && !(type is Type))
                        reportVerifyError('verifyErrors.typeNotFound', exp.span),
                        type = null;
                }
            }
            else if (exp is DotNode) {
                type = verifyConstantExpression(exp);
                if (type && !(type is Type))
                    reportVerifyError('verifyErrors.typeNotFound', exp.span),
                    type = null;
            }
            else if (exp is VoidTypeNode)
                type = semanticContext.statics.voidType;
            else if (exp is TypeArgumentsNode)
                type = verifyTypeArguments(TypeArgumentsNode(exp));
            else if (exp is NullableTypeNode) {
                var nullableTypeExp:NullableTypeNode = NullableTypeNode(exp);
                type = verifyTypeExpression(nullableTypeExp.type);
                type = type ? semanticContext.factory.nullableType(type) : null;
            }
            else if (exp is UnaryOperatorNode)
                reportVerifyError('verifyErrors.typeNotFound', exp.span);
            else if (exp is ArrayLiteralNode) {
                var arrayLiteral:ArrayLiteralNode = ArrayLiteralNode(exp),
                    tupleElements:Array = [];
                for each (var arrayElement:ExpressionNode in arrayLiteral.elements) {
                    if (arrayElement is SpreadOperatorNode) {
                        reportVerifyError('verifyErrors.spreadOperatorNotAllowedHere', arrayElement.span);
                        continue;
                    }
                    tupleElements.push((arrayElement ? verifyTypeExpression(arrayElement) : null) || semanticContext.statics.anyType);
                }
                if (tupleElements.length > 1)
                    type = semanticContext.factory.tupleType(tupleElements);
                else reportVerifyError('verifyErrors.typeNotFound', exp.span);
            }

            type ||= semanticContext.statics.anyType;
            result.setSymbolOf(exp, type);
            return type;
        }

        private function verifyTypeArguments(exp:TypeArgumentsNode):Symbol {
            var base:Symbol = verifyTypeExpression(exp.base),
                r:Symbol;
            if (base) {
                base = base.escapeType() is InstantiatedType ? base.escapeType().originalDefinition : base;
                var typeParams:Array = base.typeParams;
                if (typeParams) {
                    if (exp.arguments.length > typeParams.length)
                        reportVerifyError('verifyErrors.wrongNumberOfArguments', exp.span, { number: typeParams.length });
                    var argumentTypes:Array = [],
                        index:uint;

                    for (index = 0; index != exp.arguments.length; ++index) {
                        var argType:Symbol = verifyTypeExpression(exp.arguments[index]);

                        if (index < typeParams.length)
                            argumentTypes.push(argType);
                    }

                    for (index = index; index < typeParams.length; ++index)
                        argumentTypes.push(semanticContext.statics.anyType);

                    r = semanticContext.factory.instantiatedType(base, argumentTypes);
                }
                else reportVerifyError('verifyErrors.typeIsNotParameterized', exp.base.span),
                    r = base;
            }
            return r || semanticContext.statics.anyType;
        }
    }
}