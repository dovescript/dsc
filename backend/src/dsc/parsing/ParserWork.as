package dsc.parsing {
    import flash.filesystem.*;
    import flash.errors.IOError;
    import flash.utils.ByteArray;
    import flash.utils.Dictionary;

    import dsc.*;
    import dsc.parsing.ast.*;
    import dsc.semantics.*;

    import com.siteblade.util.CharArray;

    internal final class ParserWork {
        public var lexer:Lexer;
        public var script:Script;
        public var token:TokenState;
        public var previousToken:TokenState = new TokenState;
        public var locations:Vector.<uint> = new Vector.<uint>;
        public var curlyStack:Array = [];
        public var attributeCombination:AttributeCombination;
        public var functionFlagsStack:Vector.<uint> = new Vector.<uint>;

        /**
         * Result after parsing a Directive or Statement.
         */
        private var semicolonInserted:Boolean;

        /**
         * Result of the methods <code>filterUnaryOperator()</code> and <code>filterBinaryOperator()</code>.
         */
        private var nextPrecedence:OperatorPrecedence;

        /*
         * Result of the methods <code>filterUnaryOperator()</code> and <code>filterBinaryOperator()</code>,
         * also assigned manually in short regions of the code.
         */
        public var filteredOperator:Operator;

        public function ParserWork(lexer:Lexer) { this.lexer = lexer, this.script = this.lexer.script, this.token = this.lexer.token }

        public function clear():void { lexer.mode = LexerMode.NORMAL, curlyStack.length = 0, locations.length = 0, functionFlagsStack.length = 0 }

        public function markLocation(span:Span = undefined):void { locations.push(span ? span.start : token.start, span ? span.firstLine : token.firstLine) }
        public function popLocation():Span { return new Span(locations.pop(), locations.pop(), previousToken.lastLine, previousToken.end) }
        public function duplicateLocation():void { locations.push(locations[locations.length - 2], locations[locations.length - 1]) }

        public function get functionFlags():int { return functionFlagsStack.length ? functionFlagsStack[functionFlagsStack.length - 1] : -1 }
        public function set functionFlags(flags:int):void { functionFlagsStack[functionFlagsStack.length - 1]|= flags }

        public function getTokenLocation():SourceLocation { return new SourceLocation(script, token.span) }

        public function openParen(wordId:String):void { curlyStack.push(new CurlySection(wordId, token.span)), expect(Token.LPAREN) }

        public function closeParen():void {
            var sec:CurlySection = curlyStack.pop();

            if (token.type != Token.RPAREN) throw reportSyntaxError('syntaxErrors.expectingToClose', getTokenLocation(), { what: Token.LPAREN, toClose: new ProblemWord(sec.wordId), atLine: sec.span.firstLine  });

            shiftToken();
        }

        public function openBracket(wordId:String):void { curlyStack.push(new CurlySection(wordId, token.span)), expect(Token.LBRACKET) }

        public function closeBracket():void {
            var sec:CurlySection = curlyStack.pop();

            if (token.type != Token.RBRACKET) throw reportSyntaxError('syntaxErrors.expectingToClose', getTokenLocation(), { what: Token.LPAREN, toClose: new ProblemWord(sec.wordId), atLine: sec.span.firstLine  });

            shiftToken();
        }

        public function openBrace(wordId:String):void { curlyStack.push(new CurlySection(wordId, token.span)), expect(Token.LBRACE) }

        public function closeBrace():void {
            var sec:CurlySection = curlyStack.pop();

            if (token.type != Token.RBRACE) throw reportSyntaxError('syntaxErrors.expectingToClose', getTokenLocation(), { what: Token.LPAREN, toClose: new ProblemWord(sec.wordId), atLine: sec.span.firstLine  });

            shiftToken();
        }

        public function openLeftAngle(wordId:String):void { curlyStack.push(new CurlySection(wordId, token.span)), expect(Token.LT) }

        public function closeRightAngle():void {
            var sec:CurlySection = curlyStack.pop();

            if (token.type == Token.RIGHT_SHIFT || token.type == Token.UNSIGNED_RIGHT_SHIFT || token.type == Token.GE || token.type == Token.UNSIGNED_RSHIFT_ASSIGN || token.type == Token.RSHIFT_ASSIGN) {
                token.type =
                    token.type == Token.RIGHT_SHIFT ? Token.GT : token.type == Token.GE ? Token.EQUALS :
                    token.type == Token.UNSIGNED_RIGHT_SHIFT ? Token.RIGHT_SHIFT : token.type == Token.UNSIGNED_RSHIFT_ASSIGN ? Token.RSHIFT_ASSIGN : Token.GE;
                previousToken.start = token.start, previousToken.firstLine = token.firstLine,
                previousToken.end = token.end + 1, previousToken.lastLine = token.lastLine;
                ++token.start;
            }

            else if (token.type != Token.GT) throw reportSyntaxError('syntaxErrors.expectingToClose', getTokenLocation(), { what: Token.GT, toClose: new ProblemWord(sec.wordId), atLine: sec.span.firstLine });

            else shiftToken();
        }

        public function reportSyntaxError(msgId:String, location:SourceLocation, variables:* = undefined):Problem { return script.collect(new Problem(msgId, 'syntaxError', location, variables)) }

        public function reportVerifyError(msgId:String, location:SourceLocation, variables:* = undefined):Problem { return script.collect(new Problem(msgId, 'verifyError', location, variables)) }

        public function warn(msgId:String, location:SourceLocation, variables:* = undefined):Problem { return script.collect(new Problem(msgId, 'warning', location, variables)) }

        public function shiftToken():void { previousToken.firstLine = token.firstLine, previousToken.start = token.start, previousToken.lastLine = token.lastLine, previousToken.end = token.end, lexer.shift() }

        public function consume(tokenType:Token):Boolean { if (token.type == tokenType) return shiftToken(), true; return false }

        public function consumeIdentifier(keyword:Boolean = false):String {
            if (token.type == Token.IDENTIFIER || (keyword ? token.type.isKeyword : false)) {
                var r:String = token.string; shiftToken(); return r
            }
            return null;
        }

        public function consumeContextKeyword(keyword:String):Boolean { if (token.type == Token.IDENTIFIER && token.string == keyword) return shiftToken(), true; return false }

        public function expect(tokenType:Token):Problem {
            if (token.type == tokenType) { return shiftToken(), null; }

            else {
                var problem:Problem = reportSyntaxError('syntaxErrors.expectingBefore', getTokenLocation(), { what: tokenType, before: token.type });
                return shiftToken(), problem;
            }
        }

        public function expectIdentifier(keyword:Boolean = false):String {
            var r:String = token.string;
            if (token.type.isKeyword) {
                shiftToken();
                return r;
            }

            var problem:Problem = expect(Token.IDENTIFIER);
            if (problem) throw problem;

            return r;
        }

        public function expectIdentifierOrKeyword():String {
            return expectIdentifier(true);
        }

        public function expectContextKeyword(keyword:String):Problem {
            if (token.type == Token.IDENTIFIER && token.string == keyword) return shiftToken(), null;

            else {
                var problem:Problem = reportSyntaxError('syntaxErrors.expectingBefore', getTokenLocation(), { what: keyword, before: token.type });
                return shiftToken(), problem;
            }
        }

        public function get tokenIsAtNewLine():Boolean { return previousToken.lastLine != token.firstLine }

        public function invalidateLineBreak():void {
            if (tokenIsAtNewLine)
                reportSyntaxError('syntaxErrors.unexpectedBefore', getTokenLocation(), { what: new ProblemWord('syntaxErrors.words.lineBreak'), before: token.type });
        }

        public function parseTypeExpression():ExpressionNode {
            var exp:ExpressionNode = parseNonPostfixExpression();
            if (consume(Token.QUESTION_MARK)) {
                markLocation(exp.span);
                exp = new NullableTypeNode(exp);
                exp.span = popLocation();
            }
            return exp;
        }

        public function parseTypeExpressionList():ExpressionNode {
            markLocation();
            var list:Array = [];
            do
                list.push(parseTypeExpression());
            while (consume(Token.COMMA));
            var r:ExpressionNode = new ListExpressionNode(list);
            r.span = popLocation();
            return r;
        }

        public function parseNonAssignmentExpression(allowIn:Boolean = true):ExpressionNode { return parseExpression(allowIn, OperatorPrecedence.TERNARY_OPERATOR, false) }
        public function parseNonPostfixExpression():ExpressionNode { return parseExpression(false, OperatorPrecedence.UNARY_OPERATOR, false, false) }

        public function parseExpression(allowIn:Boolean = true, minPrecedence:OperatorPrecedence = null, includeAssignment:Boolean = true, includeNonTypePostfixOperators:Boolean = true):ExpressionNode {
            var x:ExpressionNode = parseOptExpression(allowIn, minPrecedence || OperatorPrecedence.LIST_OPERATOR, includeAssignment, includeNonTypePostfixOperators);

            if (!x) throw reportSyntaxError('syntaxErrors.unallowedHere', getTokenLocation(), { what: token.type });

            return x;
        }

        public function parseOptExpression(allowIn:Boolean = true, minPrecedence:OperatorPrecedence = null, includeAssignment:Boolean = true, includeNonTypePostfixOperators:Boolean = true):ExpressionNode {
            minPrecedence ||= OperatorPrecedence.LIST_OPERATOR;

            var r:ExpressionNode = parseOptPrimaryExpression();

            var operator:Operator, span:Span;

            if (!r) {

            if (token.type == Token.SUPER && minPrecedence.valueOf() <= OperatorPrecedence.UNARY_OPERATOR.valueOf()) {
                markLocation(), shiftToken();
                r = new SuperNode(parseOptArguments()), r.span = popLocation();
            }
            else if (minPrecedence.valueOf() <= OperatorPrecedence.ASSIGNMENT_OPERATOR.valueOf() && token.type == Token.YIELD) {
                markLocation(), shiftToken();
                r = new UnaryOperatorNode(Operator.YIELD, parseExpression(allowIn, OperatorPrecedence.ASSIGNMENT_OPERATOR)), r.span = popLocation();

                if (functionFlags == -1 || (functionFlags & FunctionFlags.AWAIT)) reportSyntaxError('syntaxErrors.unallowedHere', getTokenLocation(), { what: 'yield' });

                else functionFlags |= FunctionFlags.YIELD;
            }
            else if (minPrecedence.valueOf() <= OperatorPrecedence.UNARY_OPERATOR.valueOf() && token.type == Token.NEW) {
                markLocation(), shiftToken();
                var newBase:ExpressionNode = parseOptPrimaryExpression();

                if (!newBase) throw reportSyntaxError('syntaxErrors.unallowedHere', getTokenLocation(), { what: token.type });

                var propertyOperator:ExpressionNode;

                while (propertyOperator = parseOptPropertyOperator(newBase)) newBase = propertyOperator;

                r = new NewOperatorNode(newBase, parseOptArguments()), r.span = popLocation();
            }
            else if (minPrecedence.valueOf() <= OperatorPrecedence.UNARY_OPERATOR.valueOf() && filterUnaryOperator(token.type)) {
                operator = filteredOperator, markLocation(), shiftToken();
                r = new UnaryOperatorNode(operator, parseExpression(allowIn, nextPrecedence)), r.span = popLocation();

                // check await operator

                if (operator == Operator.AWAIT) {
                    if (functionFlags == -1 || (functionFlags & FunctionFlags.YIELD)) reportSyntaxError('syntaxErrors.unallowedHere', getTokenLocation(), { what: 'await' });

                    else functionFlags |= FunctionFlags.AWAIT;
                }
            }
            else if (token.type == Token.QUESTION_MARK && minPrecedence.valueOf() <= OperatorPrecedence.UNARY_OPERATOR.valueOf()) {
                markLocation(), shiftToken();
                r = new NullableTypeNode(parseTypeExpression()), r.span = popLocation();
            }
            else if (token.type == Token.INCREMENT || token.type == Token.DECREMENT) {
                operator = token.type == Token.INCREMENT ? Operator.INCREMENT : Operator.DECREMENT;
                markLocation(), shiftToken(), invalidateLineBreak();
                r = new UnaryOperatorNode(operator, parseExpression(allowIn, OperatorPrecedence.POSTFIX_OPERATOR)), r.span = popLocation();
            }

            }

            return r ? parseSubexpression(r, allowIn, minPrecedence, includeAssignment, includeNonTypePostfixOperators) : null;
        }

        public function filterUnaryOperator(tokenType:Token):Boolean {
            filteredOperator = undefined;

            if (!tokenType.isKeyword && !tokenType.isPunctuator) return false;

            switch (tokenType) {

            case Token.VOID: return filteredOperator = Operator.VOID, nextPrecedence = OperatorPrecedence.UNARY_OPERATOR, true;

            case Token.TYPEOF: return filteredOperator = Operator.TYPEOF, nextPrecedence = OperatorPrecedence.UNARY_OPERATOR, true;

            case Token.DELETE: return filteredOperator = Operator.DELETE, nextPrecedence = OperatorPrecedence.POSTFIX_OPERATOR, true;

            case Token.AWAIT: return filteredOperator = Operator.AWAIT, nextPrecedence = OperatorPrecedence.UNARY_OPERATOR, true;

            case Token.EXCLAMATION_MARK: return filteredOperator = Operator.LOGICAL_NOT, nextPrecedence = OperatorPrecedence.UNARY_OPERATOR, true;

            case Token.PLUS: return filteredOperator = Operator.POSITIVE, nextPrecedence = OperatorPrecedence.UNARY_OPERATOR, true;

            case Token.MINUS: return filteredOperator = Operator.NEGATE, nextPrecedence = OperatorPrecedence.UNARY_OPERATOR, true;

            case Token.BIT_NOT: return filteredOperator = Operator.BITWISE_NOT, nextPrecedence = OperatorPrecedence.UNARY_OPERATOR, true;

            }

            return false;
        }

        public function filterBinaryOperator(tokenType:Token):Boolean {
            filteredOperator = undefined;

            if (!tokenType.isPunctuator) return false;

            switch (tokenType) {

            case Token.PLUS: return filteredOperator = Operator.ADD, nextPrecedence = OperatorPrecedence.ADDITIVE_OPERATOR;

            case Token.MINUS: return filteredOperator = Operator.SUBTRACT, nextPrecedence = OperatorPrecedence.ADDITIVE_OPERATOR;

            case Token.TIMES: return filteredOperator = Operator.MULTIPLY, nextPrecedence = OperatorPrecedence.MULTIPLICATIVE_OPERATOR;

            case Token.SLASH: return filteredOperator = Operator.DIVIDE, nextPrecedence = OperatorPrecedence.MULTIPLICATIVE_OPERATOR;

            case Token.REMAINDER: return filteredOperator = Operator.REMAINDER, nextPrecedence = OperatorPrecedence.MULTIPLICATIVE_OPERATOR;

            case Token.LEFT_SHIFT: return filteredOperator = Operator.LEFT_SHIFT, nextPrecedence = OperatorPrecedence.SHIFT_OPERATOR;

            case Token.RIGHT_SHIFT: return filteredOperator = Operator.RIGHT_SHIFT, nextPrecedence = OperatorPrecedence.SHIFT_OPERATOR;

            case Token.UNSIGNED_RIGHT_SHIFT: return filteredOperator = Operator.UNSIGNED_RIGHT_SHIFT, nextPrecedence = OperatorPrecedence.SHIFT_OPERATOR;

            case Token.BIT_AND: return filteredOperator = Operator.BITWISE_AND, nextPrecedence = OperatorPrecedence.BIT_AND_OPERATOR;

            case Token.BIT_XOR: return filteredOperator = Operator.BITWISE_XOR, nextPrecedence = OperatorPrecedence.BIT_XOR_OPERATOR;

            case Token.BIT_OR: return filteredOperator = Operator.BITWISE_OR, nextPrecedence = OperatorPrecedence.BIT_OR_OPERATOR;

            case Token.LOGICAL_AND: return filteredOperator = Operator.LOGICAL_AND, nextPrecedence = OperatorPrecedence.LOGICAL_AND_OPERATOR;

            case Token.LOGICAL_OR: return filteredOperator = Operator.LOGICAL_OR, nextPrecedence = OperatorPrecedence.LOGICAL_OR_OPERATOR;

            case Token.EQUALS: return filteredOperator = Operator.EQUALS, nextPrecedence = OperatorPrecedence.EQUALITY_OPERATOR;

            case Token.NOT_EQUALS: return filteredOperator = Operator.NOT_EQUALS, nextPrecedence = OperatorPrecedence.EQUALITY_OPERATOR;

            case Token.STRICT_EQUALS: return filteredOperator = Operator.STRICT_EQUALS, nextPrecedence = OperatorPrecedence.EQUALITY_OPERATOR;

            case Token.STRICT_NOT_EQUALS: return filteredOperator = Operator.STRICT_NOT_EQUALS, nextPrecedence = OperatorPrecedence.EQUALITY_OPERATOR;

            case Token.LT: return filteredOperator = Operator.LT, nextPrecedence = OperatorPrecedence.RELATIONAL_OPERATOR;

            case Token.GT: return filteredOperator = Operator.GT, nextPrecedence = OperatorPrecedence.RELATIONAL_OPERATOR;

            case Token.LE: return filteredOperator = Operator.LE, nextPrecedence = OperatorPrecedence.RELATIONAL_OPERATOR;

            case Token.GE: return filteredOperator = Operator.GE, nextPrecedence = OperatorPrecedence.RELATIONAL_OPERATOR;

            }

            return false;
        }

        public function parseSubexpression(base:ExpressionNode, allowIn:Boolean, minPrecedence:OperatorPrecedence, includeAssignment:Boolean = true, includeNonTypePostfixOperators:Boolean = true):ExpressionNode {
            var node:ExpressionNode = base, node2:ExpressionNode, node3:ExpressionNode, id:QualifiedIdNode, propertyOperator:ExpressionNode;

            while (1) {
                if (propertyOperator = parseOptPropertyOperator(node, includeNonTypePostfixOperators)) node = propertyOperator;

                else if (includeNonTypePostfixOperators && (token.type == Token.LPAREN && (!tokenIsAtNewLine || script.getLineIndent(base.span.firstLine) < script.getLineIndent(token.firstLine))))
                    node = new CallNode(node, parseArguments()), markLocation(base.span), node.span = popLocation();
                else if ((token.type == Token.AS || token.type == Token.IS || token.type == Token.INSTANCEOF) && minPrecedence.valueOf() <= OperatorPrecedence.RELATIONAL_OPERATOR.valueOf()) {
                    var typeOp:String = token.type == Token.AS ? 'as' : token.type == Token.IS ? 'is' : 'instanceof';
                    shiftToken();
                    if (token.type == Token.IS && typeOp == 'as')
                        shiftToken(),
                        node = new UnaryOperatorNode(Operator.AS_IS, node),
                        node.span = popLocation();
                    else node = new TypeOperatorNode(typeOp, node, parseExpression(false, OperatorPrecedence.POSTFIX_OPERATOR)), markLocation(base.span), node.span = popLocation();
                }
                else if (filterBinaryOperator(token.type) && minPrecedence.valueOf() <= nextPrecedence.valueOf())
                    shiftToken(),
                    node = new BinaryOperatorNode(filteredOperator, node, parseExpression(allowIn, OperatorPrecedence.valueOf(nextPrecedence.valueOf() + 1), includeAssignment)), markLocation(base.span), node.span = popLocation();
                else if (minPrecedence.valueOf() <= OperatorPrecedence.RELATIONAL_OPERATOR.valueOf() && allowIn && consume(Token.IN)) node = new BinaryOperatorNode(Operator.IN, node, parseExpression(allowIn, OperatorPrecedence.SHIFT_OPERATOR)), markLocation(base.span), node.span = popLocation();

                else if (minPrecedence.valueOf() <= OperatorPrecedence.TERNARY_OPERATOR.valueOf() && consume(Token.QUESTION_MARK)) {
                    // ConditionalExpression
                    node2 = parseExpression(allowIn, OperatorPrecedence.ASSIGNMENT_OPERATOR, includeAssignment);
                    var node3:ExpressionNode;

                    if (consume(Token.COLON)) node3 = parseExpression(allowIn, OperatorPrecedence.TERNARY_OPERATOR, includeAssignment);

                    else throw expect(Token.COLON);

                    node = new TernaryNode(node, node2, node3), markLocation(base.span), node.span = popLocation();
                }
                else if (token.type.isAssignment && minPrecedence.valueOf() <= OperatorPrecedence.ASSIGNMENT_OPERATOR.valueOf() && includeAssignment) {
                    var compoundOperator:Operator = token.type.getCompoundAssignmentOperator();
                    shiftToken();
                    node = new AssignmentNode(compoundOperator, node, parseExpression(allowIn, OperatorPrecedence.ASSIGNMENT_OPERATOR)), markLocation(base.span), node.span = popLocation();
                }
                else if (token.type == Token.COMMA && minPrecedence.valueOf() <= OperatorPrecedence.LIST_OPERATOR.valueOf()) {
                    var expressions:Array = [ node ];

                    while (consume(Token.COMMA)) expressions.push(parseExpression(allowIn, OperatorPrecedence.ASSIGNMENT_OPERATOR, includeAssignment));

                    node = new ListExpressionNode(expressions), markLocation(base.span), node.span = popLocation();
                }
                else if (includeNonTypePostfixOperators && (token.type == Token.INCREMENT || token.type == Token.DECREMENT)) {
                    var updateOp:Operator = token.type == Token.INCREMENT ? Operator.POST_INCREMENT : Operator.POST_DECREMENT;
                    invalidateLineBreak(), shiftToken();
                    node = new UnaryOperatorNode(updateOp, node), markLocation(base.span), node.span = popLocation();
                }
                else break;
            }

            return node;
        }

        private function parseOptPropertyOperator(base:ExpressionNode, includeNonTypePostfixOperators:Boolean = true):ExpressionNode {
            var node:ExpressionNode, node2:ExpressionNode, id:QualifiedIdNode;

            if (consume(Token.DOT)) {
                if (node2 = parseOptQualifiedIdentifier(false, true)) node = new DotNode(base, QualifiedIdNode(node2)), markLocation(base.span), node.span = popLocation();

                else if (token.type == Token.LT) {
                    openLeftAngle('syntaxErrors.words.argumentList');
                    var arrowArguments:Array = [];

                    do arrowArguments.push(parseTypeExpression()); while (consume(Token.COMMA));

                    closeRightAngle();
                    node = new TypeArgumentsNode(base, arrowArguments), markLocation(base.span), node.span = popLocation();
                }

                else expectIdentifier();
            }
            else if (token.type == Token.LBRACKET && includeNonTypePostfixOperators && (!this.tokenIsAtNewLine || script.getLineIndent(base.span.firstLine) < script.getLineIndent(token.firstLine))) {
                openBracket('expression');
                node2 = parseExpression();
                closeBracket();

                node = new BracketsNode(base, node2), markLocation(base.span), node.span = popLocation();
            }
            else if (token.type == Token.DESCENDANTS && includeNonTypePostfixOperators) {
                id = QualifiedIdNode(parseQualifiedIdentifier());

                if (id is AttributeIdNode) reportSyntaxError('syntaxErrors.unallowedHere', new SourceLocation(script, id.span), { what: new ProblemWord('syntaxErrors.words.attributeId') });

                node = new DescendantsNode(base, id), markLocation(base.span), node.span = popLocation();
            }

            return node;
        }

        private function parseOptPrimaryExpression():ExpressionNode {
            markLocation();
            var r:ExpressionNode, str:String;
            {
                if (str = consumeIdentifier()) return parseIdentifierStartedExpression(str);

                if (token.type == Token.STRING_LITERAL) return r = new StringLiteralNode(token.string), shiftToken(), r.span = popLocation(), r;

                if (token.type == Token.NUMERIC_LITERAL) return r = new NumericLiteralNode(token.number), shiftToken(), r.span = popLocation(), r;

                if (token.type == Token.BOOLEAN_LITERAL) return r = new BooleanLiteralNode(token.boolean), shiftToken(), r.span = popLocation(), r;

                if (token.type == Token.NULL_LITERAL) return r = new NullLiteralNode, shiftToken(), r.span = popLocation(), r;

                if (token.type == Token.THIS_LITERAL) return r = new ThisLiteralNode, shiftToken(), r.span = popLocation(), r;

                if (token.type == Token.SLASH || token.type == Token.DIVIDE_ASSIGN) return lexer.scanRegExpLiteral(), r = new RegExpLiteralNode(token.string, token.regExpFlags), shiftToken(), r.span = popLocation(), r;

                if (token.type == Token.LPAREN) {
                    popLocation();
                    r = parseParenListExpression();
                    return token.type == Token.COLON_COLON ? parseQualifiedIdentifierFinal(r) : r;
                }

                if (r = parseOptReservedNamespace()) return popLocation(), token.type == Token.COLON_COLON ? parseQualifiedIdentifierFinal(r) : r;

                if (token.type == Token.LBRACKET) return popLocation(), parseArrayLiteral();

                if (token.type == Token.LBRACE) return popLocation(), parseObjectLiteral();

                if (token.type == Token.FUNCTION) {
                    markLocation();
                    shiftToken();
                    str = consumeIdentifier(true);
                    var fnCommon:FunctionCommonNode = parseFunctionCommon();
                    r = new FunctionExpressionNode(str, fnCommon), r.span = popLocation();

                    if (!fnCommon.body) reportSyntaxError('syntaxErrors.functionMustContainBody', new SourceLocation(script, r.span));

                    return r;
                }

                if (token.type == Token.LT) {
                    if (lexer.source[0] == 0x21 || lexer.source[0] == 0x3f) return lexer.scanXMLMarkup(), r = new XMLMarkupNode(token.string), shiftToken(), r.span = popLocation(), r;

                    else {
                        lexer.mode = LexerMode.XML_TAG, shiftToken();

                        if (token.type == Token.GT) return parseXMLList(popLocation());

                        else return parseXMLElement(true, popLocation());
                    }
                }

                if (r = parseOptQualifiedIdentifier()) return popLocation(), r;
            }

            return popLocation(), undefined;
        }

        public function parseParenListExpression():ExpressionNode {
            markLocation(), openParen('syntaxErrors.words.parens');
            var expr:ExpressionNode = parseExpression();
            closeParen();
            var r:ExpressionNode = new ParenExpressionNode(expr);
            return r.span = popLocation(), r;
        }

        public function parseArguments():Array {
            var r:Array = [];
            openParen('syntaxErrors.words.argumentList');

            do {
                if (token.type == Token.RPAREN)
                    break;
                r.push(parseExpression(true, OperatorPrecedence.ASSIGNMENT_OPERATOR));
            } while(consume(Token.COMMA));

            closeParen();
            return r;
        }

        public function parseOptArguments():Array { return token.type == Token.LPAREN ? parseArguments() : undefined }

        public function parseIdentifierStartedExpression(str:String):ExpressionNode {
            if (token.type == Token.STRING_LITERAL && str == 'embed') {
                var src:String = token.string;
                shiftToken();
                var r:ExpressionNode = new EmbedExpressionNode(src);
                r.span = popLocation();
                return r;
            }

            var id:ExpressionNode = new SimpleIdNode(undefined, str);
            id.span = popLocation();
            return parseQualifiedIdentifierFinal(id);
        }

        public function parseQualifiedIdentifier(simpleOnly:Boolean = false):ExpressionNode {
            var r:ExpressionNode = parseOptQualifiedIdentifier(simpleOnly);

            if (!r) throw expect(Token.IDENTIFIER);

            return r;
        }

        public function parseOptQualifiedIdentifier(simpleOnly:Boolean = false, allowKeyword:Boolean = false):ExpressionNode {
            markLocation();
            var r:ExpressionNode, str:String = consumeIdentifier(allowKeyword), brackets:ExpressionNode;

            if (str) r = new SimpleIdNode(undefined, str), r.span = popLocation();

            else if (token.type == Token.LPAREN) {
                popLocation();
                r = parseParenListExpression();

                if (r && token.type != Token.COLON_COLON) throw expect(Token.COLON_COLON);
            }
            else if (token.type == Token.TIMES) {
                shiftToken();
                r = new SimpleIdNode(undefined, '*'), r.span = popLocation();
            }
            else if (token.type == Token.ATTRIBUTE && !simpleOnly) {
                shiftToken();

                if (token.type == Token.ATTRIBUTE) reportSyntaxError('syntaxErrors.unallowedHere', getTokenLocation(), { what: token.type });

                if (token.type == Token.LBRACKET) openBracket('syntaxErrors.words.expression'), brackets = parseExpression(), closeBracket();

                if (brackets) {
                    var bracketsId:ExpressionIdNode = new ExpressionIdNode(undefined, brackets);
                    bracketsId.span = brackets.span;
                    r = new AttributeIdNode(bracketsId);
                }

                else r = new AttributeIdNode(QualifiedIdNode(parseQualifiedIdentifier()));

                r.span = popLocation();
            }
            else {
                popLocation();
                r = parseOptReservedNamespace();

                if (r && token.type != Token.COLON_COLON) throw expect(Token.COLON_COLON);
            }

            if (r) return parseQualifiedIdentifierFinal(r, simpleOnly);

            return undefined;
        }

        public function parseQualifiedIdentifierFinal(expr:ExpressionNode, simpleOnly:Boolean = false):ExpressionNode {
            if (consume(Token.COLON_COLON)) {
                markLocation(expr.span);

                if (token.type == Token.LBRACKET && !simpleOnly) openBracket('syntaxErrors.words.expression'), expr = new ExpressionIdNode(expr, parseExpression()), closeBracket();

                else if (consume(Token.TIMES)) expr = new SimpleIdNode(expr, '*');

                else expr = new SimpleIdNode(expr, expectIdentifier(true));

                expr.span = popLocation();
            }

            return expr;
        }

        public function parseArrayLiteral():ExpressionNode {
            var elements:Array = [];

            markLocation(), openBracket('syntaxErrors.words.expression');

            do {
                while (consume(Token.COMMA)) elements.push(null);

                if (token.type == Token.RBRACKET) break;

                if (token.type == Token.ELLIPSIS) {
                    markLocation();
                    shiftToken();
                    var spreadOp:SpreadOperatorNode = new SpreadOperatorNode(parseExpression(true, OperatorPrecedence.ASSIGNMENT_OPERATOR));
                    spreadOp.span = popLocation();
                    elements.push(spreadOp);
                }
                else {
                    var element:ExpressionNode = parseOptExpression(true, OperatorPrecedence.ASSIGNMENT_OPERATOR);

                    if (!element) break;

                    elements.push(element);
                }
            } while (consume(Token.COMMA));

            closeBracket();

            var r:ExpressionNode = new ArrayLiteralNode(elements, consume(Token.COLON) ? parseTypeExpression() : null);
            return r.span = popLocation(), r;
        }

        public function parseObjectLiteral():ExpressionNode {
            var fields:Array = [];
            markLocation(), openBrace('syntaxErrors.words.expression');

            do {
                if (token.type == Token.RBRACE) break;

                if (token.type == Token.ELLIPSIS) {
                    markLocation();
                    shiftToken();
                    var spreadOp:SpreadOperatorNode = new SpreadOperatorNode(parseExpression(true, OperatorPrecedence.ASSIGNMENT_OPERATOR));
                    spreadOp.span = popLocation();
                    fields.push(spreadOp);
                }

                else {
                    var field:ObjectFieldNode = parseOptObjectField();

                    if (!field) break;

                    fields.push(field);
                }
            } while (consume(Token.COMMA));

            closeBrace();
            var r:ExpressionNode = new ObjectLiteralNode(fields, consume(Token.COLON) ? parseTypeExpression() : null);
            return r.span = popLocation(), r;
        }

        private function parseOptObjectField():ObjectFieldNode {
            markLocation();

            var computed:Boolean, key:ExpressionNode, shorthandAvailable:Boolean;

            if (token.type == Token.IDENTIFIER) key = new SimpleIdNode(undefined, token.string), markLocation(), shiftToken(), key.span = popLocation(), shorthandAvailable = true;

            else if (token.type == Token.NUMERIC_LITERAL || token.type == Token.STRING_LITERAL) key = parseOptPrimaryExpression();

            else if (token.type == Token.LBRACKET) computed = true, openBracket('syntaxErrors.words.expression'), key = parseExpression(), closeBracket();

            else return popLocation(), undefined;

            var value:ExpressionNode;

            if (token.type != Token.COLON && !shorthandAvailable) expect(Token.COLON);

            else if (consume(Token.COLON)) value = parseExpression(true, OperatorPrecedence.ASSIGNMENT_OPERATOR);

            var field:ObjectFieldNode = new ObjectFieldNode(computed, key, value);
            return field.span = popLocation(), field;
        }

        private function parseXMLList(start:Span):ExpressionNode {
            markLocation(start);
            lexer.mode = LexerMode.XML_CONTENT;
            shiftToken();

            var nodes:Array = parseXMLContent();
            lexer.mode = LexerMode.NORMAL;
            expect(Token.GT);

            var r:ExpressionNode = new XMLListNode(nodes);
            return r.span = popLocation(), r;
        }

        private function parseXMLElement(asRoot:Boolean, start:Span):XMLNode {
            markLocation(start);
            var openName:Object, closeName:Object, attributes:Array, children:Array;

            if (token.type == Token.LBRACE) {
                lexer.mode = LexerMode.NORMAL;
                openBrace('syntaxErrors.words.expression');
                openName = parseExpression();
                lexer.mode = LexerMode.XML_TAG;
                closeBrace();
            }
            else openName = token.string, expect(Token.XML_NAME);

            while (consume(Token.XML_WHITESPACE)) {
                var attribute:XMLAttributeNode;

                if (token.type == Token.LBRACE) markLocation(), lexer.mode = LexerMode.NORMAL, openBrace('syntaxErrors.words.expression'), attribute = new XMLAttributeNode(undefined, parseExpression()), attribute.span = popLocation(), attributes ||= [], attributes.push(attribute), lexer.mode = LexerMode.XML_TAG, closeBrace();

                // start 'name=value'

                else if (token.type == Token.XML_NAME) {
                    markLocation();
                    var attributeName:String = token.string, attributeValue:Object;
                    shiftToken(), consume(Token.XML_WHITESPACE);

                    var problem:Problem = expect(Token.ASSIGN);

                    if (problem) throw problem;

                    consume(Token.XML_WHITESPACE);

                    if (token.type == Token.LBRACE) lexer.mode = LexerMode.NORMAL, openBrace('syntaxErrors.words.expression'), attributeValue = parseExpression(), lexer.mode = LexerMode.XML_TAG, closeBrace();

                    else attributeValue = token.string, expect(Token.XML_ATTRIBUTE_VALUE);

                    attribute = new XMLAttributeNode(attributeName, attributeValue), attribute.span = popLocation();
                    attributes ||= [], attributes.push(attribute);
                }

                // end 'name=value'

                else break;
            }

            if (token.type == Token.XML_SLASH_GT) {
                lexer.mode = asRoot ? LexerMode.NORMAL : LexerMode.XML_CONTENT;
                shiftToken();
            }
            else {
                lexer.mode = LexerMode.XML_CONTENT;
                children = parseXMLContent();

                if (token.type == Token.LBRACE) lexer.mode = LexerMode.NORMAL, openBrace('syntaxErrors.words.expression'), closeName = parseExpression(), lexer.mode = LexerMode.XML_TAG, closeBrace();

                else closeName = token.string, expect(Token.XML_NAME);

                lexer.mode = asRoot ? LexerMode.NORMAL : LexerMode.XML_CONTENT;
                expect(Token.GT);
            }

            var r:XMLNode = new XMLElementNode(openName, closeName, attributes, children);
            return r.span = popLocation(), r;
        }

        public function parseXMLContent():Array {
            var r:Array = [], singleNode:XMLNode;
 
            while (1) {
                if (token.type == Token.LT) markLocation(), lexer.mode = LexerMode.XML_TAG, shiftToken(), r.push(parseXMLElement(false, popLocation()));

                else if (token.type == Token.XML_MARKUP) markLocation(), singleNode = new XMLMarkupNode(token.string), shiftToken(), singleNode.span = popLocation(), r.push(singleNode);

                else if (token.type == Token.XML_TEXT) markLocation(), singleNode = new XMLTextNode(token.string), shiftToken(), singleNode.span = popLocation(), r.push(singleNode);

                else if (token.type == Token.LBRACE) lexer.mode = LexerMode.NORMAL, openBrace('syntaxErrors.words.expression'), singleNode = new XMLTextNode(parseExpression()), lexer.mode = LexerMode.XML_CONTENT, closeBrace(), singleNode.span = popLocation(), r.push(singleNode);

                else { lexer.mode = LexerMode.XML_TAG, expect(Token.LT); break }
            }

            return r;
        }

        private function parseOptReservedNamespace():ExpressionNode {
            var type:String = token.type == Token.PUBLIC ? 'public' : token.type == Token.PRIVATE ? 'private' : token.type == Token.PROTECTED ? 'protected' : token.type == Token.INTERNAL ? 'internal' : null;

            if (!type) return null;

            markLocation();
            shiftToken();
            var r:ExpressionNode = new ReservedNamespaceNode(type);
            return r.span = popLocation(), r;
        }

        public function parseDestructuringPattern():Node {
            var r:Node = parseOptDestructuringPattern();

            if (!r) expectIdentifier();

            return r;
        }

        public function parseOptDestructuringPattern():Node {
            if (token.type == Token.LBRACE || token.type == Token.LBRACKET) return parseOptPrimaryExpression();

            else if (token.type == Token.IDENTIFIER || token.type.isKeyword) {
                markLocation();
                var name:String = consumeIdentifier(true);
                var type:ExpressionNode = consume(Token.COLON) ? parseTypeExpression() : undefined;
                var r:TypedIdNode = new TypedIdNode(name, type);
                return r.span = popLocation(), r;
            }

            else return undefined;
        }

        public function parseStatement(context:ParserContext):StatementNode {
            var r:StatementNode = parseOptStatement(context);

            if (!r) throw reportSyntaxError('syntaxErrors.unallowedHere', getTokenLocation(), { what: token.type });

            return r;
        }

        public function parseOptStatement(context:ParserContext):StatementNode {
            semicolonInserted = false;
            var marker:Span, stmt:StatementNode, substmt:StatementNode, str:String, expr:ExpressionNode, dp:Node;

            if (token.type == Token.IDENTIFIER) return marker = token.span, parseIdentifierStartedStatement(consumeIdentifier(), context, marker);

            else if (token.type.isKeyword) {
                // SuperStatement, SuperExpression
                if (token.type == Token.SUPER) {
                    markLocation(), shiftToken();
                    var superArguments:Array = parseOptArguments();

                    if (superArguments && token.type != Token.DOT) {
                        parseSemicolon();
                        stmt = new SuperStatementNode(superArguments), stmt.span = popLocation();

                        if (!context.atConstructorBlock || context.foundSuperStatement) reportSyntaxError('syntaxErrors.unallowedHere', new SourceLocation(script, stmt.span), { what: new ProblemWord('syntaxErrors.words.superStatement') });
                    }
                    else {
                        duplicateLocation(), duplicateLocation();
                        expr = new SuperNode(superArguments), expr.span = popLocation();
                        expr = parseSubexpression(expr, true, OperatorPrecedence.LIST_OPERATOR);
                        parseSemicolon();
                        stmt = new ExpressionStatementNode(expr), stmt.span = popLocation();
                    }
                }
                // BreakStatement
                else if (token.type == Token.BREAK) {
                    markLocation(), shiftToken(), marker = token.span;
                    str = tokenIsAtNewLine ? undefined : consumeIdentifier();
                    parseSemicolon();
                    stmt = new BreakNode(str), stmt.span = popLocation();

                    var breakTarget:Node;

                    if (str) {
                        if (!( breakTarget = context.labels ? context.labels[str] : undefined )) reportSyntaxError('syntaxErrors.undefinedLabel', new SourceLocation(script, marker), { label: str });
                    }
                    else if (!( breakTarget = context.lastBreakableStatement )) reportSyntaxError('syntaxErrors.unallowedHere', new SourceLocation(script, stmt.span), { what: 'break' });

                    BreakNode(stmt).targetStatement = breakTarget;
                }

                // ContinueStatement
                else if (token.type == Token.CONTINUE) {
                    markLocation(), shiftToken(), marker = token.span;
                    str = tokenIsAtNewLine ? undefined : consumeIdentifier();
                    parseSemicolon();
                    stmt = new ContinueNode(str), stmt.span = popLocation();

                    var contTarget:Node;

                    if (str) {
                        if (!( contTarget = context.labels ? context.labels[str] : undefined )) reportSyntaxError('syntaxErrors.undefinedLabel', new SourceLocation(script, marker), { label: str });
                    }
                    else if (!( contTarget = context.lastContinuableStatement )) reportSyntaxError('syntaxErrors.unallowedHere', new SourceLocation(script, stmt.span), { what: 'continue' });

                    ContinueNode(stmt).targetStatement = contTarget;
                }

                // ReturnStatement
                else if (token.type == Token.RETURN) {
                    markLocation(), shiftToken(), parseSemicolon(), expr = undefined;

                    if (!semicolonInserted && (expr = parseOptExpression())) parseSemicolon();

                    stmt = new ReturnNode(expr), stmt.span = popLocation();

                    if (functionFlags == -1) throw reportSyntaxError('syntaxErrors.unallowedHere', new SourceLocation(script, stmt.span), { what: Token.RETURN });
                }

                // ThrowStatement
                else if (token.type == Token.THROW) {
                    markLocation(), shiftToken();
                    expr = parseExpression(), parseSemicolon();
                    stmt = new ThrowNode(expr), stmt.span = popLocation();
                }

                // default xml namespace = xmlNS
                else if (token.type == Token.DEFAULT) {
                    markLocation(), shiftToken(), invalidateLineBreak();
                    expectContextKeyword('xml'), invalidateLineBreak(), expectContextKeyword('namespace'), expect(Token.ASSIGN);
                    expr = parseNonAssignmentExpression(false), parseSemicolon();
                    stmt = new DefaultXMLNamespaceStatementNode(expr), stmt.span = popLocation();
                }

                // WithStatement
                else if (token.type == Token.WITH) {
                    markLocation(), shiftToken(), expr = parseParenListExpression();
                    substmt = parseSubstatement(context.clone());
                    stmt = new WithStatementNode(ParenExpressionNode(expr).expression, substmt), stmt.span = popLocation();
                }

                // TryStatement
                else if (token.type == Token.TRY) {
                    markLocation();
                    var tryElement:BlockNode = parseBlock(context.clone()), catchElements:Array = [], finallyElement:BlockNode;

                    while (token.type == Token.CATCH) {
                        markLocation(), shiftToken(), dp = undefined;

                        openParen('syntaxErrors.words.parens');
                        dp = parseDestructuringPattern();
                        closeParen();

                        var catchElement:CatchNode = new CatchNode(dp, undefined);
                        var catchContext:ParserContext = context.clone();
                        catchContext.lastContinuableStatement = catchElement;
                        catchElement.block = parseBlock(catchContext);
                        catchElement.span = popLocation();
                        catchElements.push(catchElement);
                    }

                    if (consume(Token.FINALLY)) finallyElement = parseBlock(context.clone());

                    if (catchElements.length == 0 && !finallyElement) expect(Token.CATCH);

                    stmt = new TryStatementNode(tryElement, catchElements, finallyElement), stmt.span = popLocation();
                }
                else if (token.type == Token.SWITCH) stmt = parseSwitchStatement(context);

                else if (token.type == Token.FOR) stmt = parseForStatement(context);

                else if (token.type == Token.WHILE) {
                    markLocation(), shiftToken();
                    var whileCondition:ExpressionNode = ParenExpressionNode(parseParenListExpression()).expression;
                    stmt = new WhileStatementNode(whileCondition, undefined);

                    var whileContext:ParserContext = context.clone();
                    whileContext.lastBreakableStatement = stmt;
                    whileContext.lastContinuableStatement = stmt;

                    if (context.nextLoopLabel) whileContext.labels ||= new Dictionary, whileContext.labels[context.nextLoopLabel] = stmt;

                    WhileStatementNode(stmt).substatement = parseSubstatement(whileContext);
                    stmt.span = popLocation();
                }
                else if (token.type == Token.DO) {
                    markLocation(), shiftToken();

                    stmt = new DoStatementNode(undefined, undefined);

                    var doContext:ParserContext = context.clone();
                    doContext.lastBreakableStatement = stmt;
                    doContext.lastContinuableStatement = stmt;

                    if (context.nextLoopLabel) doContext.labels ||= new Dictionary, doContext.labels[context.nextLoopLabel] = stmt;

                    DoStatementNode(stmt).substatement = parseSubstatement(doContext);

                    if (!semicolonInserted) reportSyntaxError('syntaxErrors.expectingBefore', getTokenLocation(), { what: Token.SEMICOLON, before: token.type });

                    expect(Token.WHILE);
                    DoStatementNode(stmt).expression = ParenExpressionNode(parseParenListExpression()).expression;
                    parseSemicolon(), stmt.span = popLocation();
                }
                else if (token.type == Token.IF) {
                    markLocation(), shiftToken();
                    expr = ParenExpressionNode(parseParenListExpression()).expression;
                    var ifConsequent:StatementNode = parseSubstatement(context.clone());
                    var ifAlternative:StatementNode;

                    if (token.type == Token.ELSE) {
                        if (!semicolonInserted) reportSyntaxError('syntaxErrors.expectingBefore', getTokenLocation(), { what: Token.SEMICOLON, before: token.type });

                        shiftToken(), ifAlternative = parseSubstatement(context.clone());
                    }

                    stmt = new IfStatementNode(expr, ifConsequent, ifAlternative), stmt.span = popLocation();
                }
                else {
                    expr = parseOptExpression();

                    if (expr) parseSemicolon(), stmt = new ExpressionStatementNode(expr), markLocation(expr.span), stmt.span = popLocation();
                }
            }

            else if (token.type == Token.LBRACE) stmt = parseBlock(context);

            else {
                expr = parseOptExpression();

                if (expr) parseSemicolon(), stmt = new ExpressionStatementNode(expr), markLocation(expr.span), stmt.span = popLocation();
            }

            return stmt;
        }

        public function parseSubstatement(context:ParserContext):StatementNode { return token.type == Token.SEMICOLON ? parseEmptyStatement() : parseStatement(context) }

        public function parseSemicolon():void { semicolonInserted = consume(Token.SEMICOLON) || tokenIsAtNewLine || token.type == Token.RBRACE }

        public function parseEmptyStatement():StatementNode {
            markLocation(), shiftToken();
            var r:StatementNode = new EmptyStatementNode;
            semicolonInserted = true;
            return r.span = popLocation(), r;
        }

        public function parseVarBinding(allowIn:Boolean = true):VarBindingNode {
            markLocation();
            var pattern:Node = parseDestructuringPattern();
            var initialiser:ExpressionNode = consume(Token.ASSIGN) ? parseExpression(allowIn, OperatorPrecedence.ASSIGNMENT_OPERATOR) : undefined;
            var r:VarBindingNode = new VarBindingNode(pattern, initialiser);
            return r.span = popLocation(), r;
        }

        public function parseOptSimpleVarDeclaration(allowIn:Boolean = true):SimpleVarDeclarationNode {
            var prefix:int = token.type == Token.VAR ? 0 : token.type == Token.CONST ? 1 : -1;

            if (prefix == -1) return undefined;

            markLocation(), shiftToken();
            var bindings:Array = [];

            do bindings.push(parseVarBinding(allowIn)); while (consume(Token.COMMA));

            var r:SimpleVarDeclarationNode = new SimpleVarDeclarationNode(prefix == 1, bindings);
            return r.span = popLocation(), r;
        }

        public function parseIdentifierStartedStatement(str:String, context:ParserContext, marker:Span):StatementNode {
            markLocation(marker);
            var r:StatementNode;

            if (consume(Token.COLON)) {
                var labeledStatementContext:ParserContext = context.clone();
                labeledStatementContext.nextLoopLabel = str;
                var substmt:StatementNode = parseSubstatement(labeledStatementContext);

                if (!substmt.isIterationStatement) reportSyntaxError('syntaxErrors.illegalLabeledStatement', new SourceLocation(script, substmt.span));

                r = new LabeledStatementNode(str, substmt);
            }
            else {
                duplicateLocation();
                var exp:ExpressionNode = parseSubexpression(parseIdentifierStartedExpression(str), true, OperatorPrecedence.LIST_OPERATOR);
                parseSemicolon();
                r = new ExpressionStatementNode(exp);
            }

            return r.span = popLocation(), r;
        }

        public function parseSwitchStatement(context:ParserContext):StatementNode {
            markLocation(), shiftToken();

            if (consumeContextKeyword('type')) return parseSwitchTypeStatement(context);

            var discriminant:ExpressionNode = ParenExpressionNode(parseParenListExpression()).expression,
                lastCase:SwitchCaseNode,
                expr:ExpressionNode,
                cases:Array = [];

            openBrace('syntaxErrors.words.block');
            semicolonInserted = true;

            var r:StatementNode = new SwitchStatementNode(discriminant, cases),
                switchContext:ParserContext = context.clone();
            switchContext.lastBreakableStatement = r;

            while (token.type != Token.RBRACE) {
                if (!semicolonInserted) throw reportSyntaxError('syntaxErrors.expectingBefore', getTokenLocation(), { what: Token.SEMICOLON, before: token.type });

                markLocation();

                if (consume(Token.CASE)) {
                    expr = parseExpression(), expect(Token.COLON);
                    lastCase = new SwitchCaseNode(expr, undefined);
                    lastCase.span = popLocation();
                    cases.push(lastCase);
                }
                else if (consume(Token.DEFAULT)) {
                    expect(Token.COLON);
                    lastCase = new SwitchCaseNode(undefined, undefined);
                    lastCase.span = popLocation();
                    cases.push(lastCase);
                }
                else if (lastCase) {
                    popLocation();
                    var drtv:DirectiveNode = parseOptDirective(switchContext);

                    if (!drtv) break;

                    lastCase.directives ||= [], lastCase.directives.push(drtv);
                    lastCase.span = new Span(lastCase.span.firstLine, lastCase.span.start, drtv.span.lastLine, drtv.span.end);
                }
                else break;
            }

            closeBrace(), semicolonInserted = true;
            return r.span = popLocation(), r;
        }

        private function parseSwitchTypeStatement(context:ParserContext):StatementNode {
            var discriminant:ExpressionNode = ParenExpressionNode(parseParenListExpression()).expression,
                cases:Array = [];

            openBrace('syntaxErrors.words.block');

            while (token.type == Token.CASE) {
                markLocation(), shiftToken(), openParen('syntaxErrors.words.parens');
                var pattern:Node = parseDestructuringPattern();
                closeParen();
                var block:BlockNode = parseBlock(context.clone());
                var caseElement:SwitchTypeCaseNode = new SwitchTypeCaseNode(pattern, block);
                caseElement.span = popLocation();
                cases.push(caseElement);
            }

            closeBrace(), semicolonInserted = true;
            var r:StatementNode = new SwitchTypeStatementNode(discriminant, cases);
            return r.span = popLocation(), r;
        }

        public function parseForStatement(context:ParserContext):StatementNode {
            markLocation(), shiftToken();

            if (consumeContextKeyword('each')) return parseForEachStatement(context);

            openParen('syntaxErrors.words.parens');
            var exp1:Node = parseOptSimpleVarDeclaration(false)
                , exp2:ExpressionNode, exp3:ExpressionNode;
            exp1 = exp1 ? exp1 : parseOptExpression(false, OperatorPrecedence.POSTFIX_OPERATOR);

            if (exp1 && token.type == Token.IN) return parseForInStatement(false, exp1, context);

            if (exp1 is ExpressionNode) exp1 = parseSubexpression(ExpressionNode(exp1), false, OperatorPrecedence.LIST_OPERATOR);

            expect(Token.SEMICOLON), exp2 = parseOptExpression(), expect(Token.SEMICOLON), exp3 = parseOptExpression();
            closeParen();

            var r:ForStatementNode = new ForStatementNode(exp1, exp2, exp3, undefined);

            var substatementContext:ParserContext = context.clone();
            substatementContext.lastBreakableStatement = r;
            substatementContext.lastContinuableStatement = r;

            if (context.nextLoopLabel) substatementContext.labels ||= new Dictionary, substatementContext.labels[context.nextLoopLabel] = r;

            r.substatement = parseSubstatement(substatementContext);
            return r.span = popLocation(), r;
        }

        public function parseForEachStatement(context:ParserContext):StatementNode {
            openParen('syntaxErrors.words.parens');
            var left:Node = parseOptSimpleVarDeclaration() || parseExpression(false, OperatorPrecedence.POSTFIX_OPERATOR);
            return parseForInStatement(true, left, context);
        }

        public function parseForInStatement(each:Boolean, left:Node, context:ParserContext):StatementNode {
            var decl:SimpleVarDeclarationNode = left is SimpleVarDeclarationNode ? SimpleVarDeclarationNode(left) : undefined;

            if (decl && ( decl.bindings.length != 1 || decl.bindings[0].initialiser )) reportSyntaxError('syntaxErrors.illegalForInVarDeclaration', new SourceLocation(script, decl.span));

            if (!consume(Token.IN)) throw expect(Token.IN);

            var right:ExpressionNode = parseExpression();
            closeParen();
            var r:ForInStatementNode = new ForInStatementNode(each, left, right, undefined);

            var substatementContext:ParserContext = context.clone();
            substatementContext.lastBreakableStatement = r;
            substatementContext.lastContinuableStatement = r;

            if (context.nextLoopLabel) substatementContext.labels ||= new Dictionary, substatementContext.labels[context.nextLoopLabel] = r;

            r.substatement = parseSubstatement(substatementContext);
            return r.span = popLocation(), r;
        }

        public function parseBlock(context:ParserContext):BlockNode {
            markLocation(), openBrace('syntaxErrors.words.block');

            var directives:Array = parseOptDirectives(context);

            while (token.type != Token.RBRACE && token.type != Token.EOF && directives.length != 0 && !semicolonInserted) throw reportSyntaxError('syntaxErrors.expectingBefore', getTokenLocation(), { what: Token.SEMICOLON, before: token.type });

            closeBrace(), semicolonInserted = true;
            var r:BlockNode = new BlockNode(directives);
            return r.span = popLocation(), r;
        }

        public function parseOptDirectives(context:ParserContext):Array {
            var r:Array = [], drtv:DirectiveNode = parseOptDirective(context);

            if (!drtv) return r;

            r.push(drtv);

            while (1) {
                if (semicolonInserted && (drtv = parseOptDirective(context))) r.push(drtv);

                else if (token.type == Token.SEMICOLON) r.push(parseEmptyStatement());

                else break;
            }

            return r;
        }

        private function parseOptDirective(context:ParserContext):DirectiveNode {
            semicolonInserted = false;
            var str:String, drtv:DirectiveNode, expr:ExpressionNode, marker:Span;

            if (token.type == Token.IDENTIFIER) {
                markLocation(), str = consumeIdentifier();

                if (str == 'include') return parseIncludeDirective(context);

                else if (token.type == Token.IDENTIFIER && !tokenIsAtNewLine) {
                    attributeCombination = new AttributeCombination, duplicateLocation();

                    // AnnotatableDefinition

                    if (drtv = parseOptAnnotatableDefinition(popLocation(), context, str)) popLocation();

                    // AnnotatableDefinition

                    else {
                        duplicateLocation(), validateAttribute(str, popLocation()), parseAttributeCombination(), drtv = parseOptAnnotatableDefinition(popLocation(), context);

                        if (!drtv) throw reportSyntaxError('syntaxErrors.unexpectedToken', getTokenLocation());
                    }

                    return drtv;
                }

                // AnnotatableDefinition

                else if (token.type.isKeyword && precedingReservedNamespace && !tokenIsAtNewLine) {
                    attributeCombination = new AttributeCombination, duplicateLocation(), validateAttribute(str, popLocation()), parseAttributeCombination(), drtv = parseOptAnnotatableDefinition(popLocation(), context);

                    if (!drtv) throw reportSyntaxError('syntaxErrors.unexpectedToken', getTokenLocation());

                    return drtv;
                }

                // AnnotatableDefinition

                else if (precedingKeywordDefinition) {
                    return attributeCombination = new AttributeCombination, duplicateLocation(), validateAttribute(str, popLocation()), parseOptAnnotatableDefinition(popLocation(), context);
                }

                else return parseIdentifierStartedStatement(str, context, popLocation());
            }
            else if (token.type.isKeyword) {
                if (token.type == Token.IMPORT) return parseImportDirective();

                else if (token.type == Token.USE) return parseUseDirective();

                // AnnotatableDefinition

                else if (precedingKeywordDefinition) return attributeCombination = new AttributeCombination, parseOptAnnotatableDefinition(token.span, context);

                else if (expr = parseOptReservedNamespace()) {
                    if (token.type == Token.IDENTIFIER || precedingKeywordDefinition) {
                        attributeCombination = new AttributeCombination, attributeCombination.accessModifier = expr, parseAttributeCombination(), markLocation(expr.span), drtv = parseOptAnnotatableDefinition(popLocation(), context);

                        if (!drtv) throw reportSyntaxError('syntaxErrors.unexpectedToken', getTokenLocation());

                        return drtv;
                    }
                    else {
                        if (token.type == Token.COLON_COLON) expr = parseQualifiedIdentifierFinal(expr);

                        return expr = parseSubexpression(expr, true, OperatorPrecedence.LIST_OPERATOR), parseSemicolon(), markLocation(expr.span), drtv = new ExpressionStatementNode(expr), drtv.span = popLocation(), drtv;
                    }
                }
                else return parseOptStatement(context);
            }
            else if (token.type == Token.LBRACKET) return parseBracketStartedDirective(context);

            else if (token.type == Token.SEMICOLON) return parseEmptyStatement();

            else return parseOptStatement(context);

            return drtv;
        }

        private function parseBracketStartedDirective(context:ParserContext):DirectiveNode {
            markLocation();
            var drtv:DirectiveNode, brackets:ExpressionNode;
            var expr:ExpressionNode = parseArrayLiteral();

            while (token.type == Token.LBRACKET) openBracket('syntaxErrors.words.expression'), brackets = parseExpression(), closeBracket(), markLocation(expr.span), expr = new BracketsNode(expr, brackets), expr.span = popLocation();

            if (token.type == Token.IDENTIFIER || precedingKeywordDefinition || precedingReservedNamespace) {
                markLocation(expr.span), attributeCombination = new AttributeCombination, attributeCombination.metaData = filterMetaData(expr), parseAttributeCombination(), drtv = parseOptAnnotatableDefinition(popLocation(), context);

                if (!drtv) throw reportSyntaxError('syntaxErrors.unexpectedToken', getTokenLocation());

                return drtv;
            }
            else return expr = parseSubexpression(expr, true, OperatorPrecedence.LIST_OPERATOR), drtv = new ExpressionStatementNode(expr), parseSemicolon(), markLocation(expr.span), drtv.span = popLocation(), drtv;
        }

        private function filterMetaData(node:Node):Array {
            var r:Array = [], arrayLiteral:ArrayLiteralNode;

            while (node is BracketsNode) processSingleMetaData(BracketsNode(node).key, r), node = BracketsNode(node).base;

            arrayLiteral = ArrayLiteralNode(node);

            if (arrayLiteral.elements.length > 0) processSingleMetaData(arrayLiteral.elements[0], r);

            return r;
        }

        private function processSingleMetaData(expr:ExpressionNode, result:Array):void {
            var metaData:MetaData, name:String;
            var callNode:CallNode = expr is CallNode ? CallNode(expr) : undefined;

            if (callNode) {
                if (callNode.base is SimpleIdNode) name = SimpleIdNode(callNode.base).name;

                if (name) {
                    metaData = new MetaData(name, new SourceLocation(script, expr.span));
                    for each (var callArgument:ExpressionNode in callNode.arguments) {
                        var entry:MetaDataEntry = filterMetaDataEntry(callArgument);

                        if (entry) metaData.entries.push(entry);
                    }
                }
            }
            else if (expr is SimpleIdNode) {
                name = SimpleIdNode(expr).name;
                metaData = new MetaData(name, new SourceLocation(script, expr.span));
            }

            if (metaData) result.push(metaData);
        }

        private function filterMetaDataEntry(expr:ExpressionNode):MetaDataEntry {
            var assignExp:AssignmentNode = expr is AssignmentNode ? AssignmentNode(expr) : undefined;
            var name:String, value:*, simpleId:SimpleIdNode;

            if (assignExp && !assignExp.compound) {
                simpleId = assignExp.left is SimpleIdNode ? SimpleIdNode(assignExp.left) : undefined;

                if (simpleId) name = simpleId.name;

                value = assignExp.right is StringLiteralNode ? StringLiteralNode(assignExp.right).value : assignExp.right is NumericLiteralNode ? NumericLiteralNode(assignExp.right).value : assignExp.right is BooleanLiteralNode ? BooleanLiteralNode(assignExp.right).value : undefined;

                if (name && value !== undefined) return new MetaDataEntry(name, value, new SourceLocation(script, expr.span));
            }
            else {
                value = assignExp.right is StringLiteralNode ? StringLiteralNode(assignExp.right).value : assignExp.right is NumericLiteralNode ? NumericLiteralNode(assignExp.right).value : assignExp.right is BooleanLiteralNode ? BooleanLiteralNode(assignExp.right).value : undefined;

                if (value !== undefined) return new MetaDataEntry(undefined, value, new SourceLocation(script, expr.span));
            }

            return undefined;
        }

        /*
         * AttributeCombination
         */
        private function validateAttribute(str:String, span:Span):void {
            switch (str) {
                case 'static': attributeCombination.staticModifier = true; break;

                case 'override': attributeCombination.overrideModifier = true; break;

                case 'native': attributeCombination.nativeModifier = true; break;

                case 'final': attributeCombination.finalModifier = true; break;

                case 'dynamic': attributeCombination.dynamicModifier = true; break;

                default:
                    if (attributeCombination.accessModifier) reportSyntaxError('syntaxErrors.duplicateAccessModifier', new SourceLocation(script, span));

                    else attributeCombination.accessModifier = new SimpleIdNode(undefined, str), attributeCombination.accessModifier.span = span;
            }
        }

        private function get precedingKeywordDefinition():Boolean { return token.type.isKeyword && (token.type == Token.VAR || token.type == Token.CONST || token.type == Token.FUNCTION || token.type == Token.CLASS || token.type == Token.INTERFACE) }

        private function get precedingContextKeywordDefinition():Boolean { return token.type == Token.IDENTIFIER && (token.string == 'enum' || token.string == 'type' || token.string == 'namespace'); }

        private function get precedingReservedNamespace():Boolean { return token.type == Token.PUBLIC || token.type == Token.PRIVATE || token.type == Token.PROTECTED || token.type == Token.INTERNAL }

        private function parseAttributeCombination():void {
            var startPhase:Boolean = !!attributeCombination.metaData || attributeCombination.hasModifiers;

            while (1) {
                var str:String = token.string;

                if (token.type == Token.IDENTIFIER && !precedingContextKeywordDefinition) {
                    if (!startPhase) invalidateLineBreak();

                    validateAttribute(str, token.span), shiftToken();
                }
                else if (precedingReservedNamespace) {
                    if (!startPhase) invalidateLineBreak();

                    var ns:ExpressionNode = parseOptReservedNamespace();

                    if (attributeCombination.accessModifier) reportSyntaxError('syntaxErrors.duplicateAccessModifier', new SourceLocation(script, ns.span));

                    else attributeCombination.accessModifier = ns;
                }
                else break;

                startPhase = false;
            }
        }

        private function parseIncludeDirective(context:ParserContext, allowPackages:Boolean = true):IncludeDirectiveNode {
            var src:String = token.string;
            expect(Token.STRING_LITERAL), parseSemicolon();
            var r:IncludeDirectiveNode = new IncludeDirectiveNode(src);
            r.span = popLocation();

            // process source

            var file:File = r.src.slice(0, 5) != 'file:' && script.url ? new File(script.url).resolvePath(r.src) : new File(r.src);
            var text:CharArray;
            var fileStream:FileStream = new FileStream;
            fileStream.open(file, 'read');

            try { var ba:ByteArray = new ByteArray; fileStream.readBytes(ba); ba.position = 0; text = new CharArray(ba) }

            catch (error:IOError) { reportSyntaxError('syntaxErrors.includeDirectiveFailure', new SourceLocation(script, r.span), { msg: error.message }) }

            if (!text) return r;

            r.subscript = new Script(file.url, text), script._includesScripts ||= [], script._includesScripts.push(r.subscript);

            try {
                var parser:ParserWork = new ParserWork(new Lexer(r.subscript));

                try { parser.lexer.shift() } catch (problem:Problem) {}

                var topIncludings:Array;

                if (allowPackages) {
                    while (parser.token.type == Token.PACKAGE) r.subpackages ||= [], r.subpackages.push(parser.parsePackageDefinition());

                    while (parser.token.type == Token.IDENTIFIER) {
                        parser.markLocation(), parser.shiftToken();
                        var drtv:IncludeDirectiveNode = parser.parseIncludeDirective(context, true);

                        if (drtv.subpackages) {
                            for each (var p:PackageDefinitionNode in drtv.subpackages) r.subpackages ||= [], r.subpackages.push(p);

                            drtv.subpackages = undefined;
                        }

                        topIncludings ||= [], topIncludings.push(drtv);

                        if (drtv.subdirectives && drtv.subdirectives.length > 0) break;
                    }
                }

                var directives:Array = parser.parseOptDirectives(context);

                if (topIncludings) for (var i:int = topIncludings.length - 1; i != -1; --i) directives.unshift(topIncludings[i]);

                r.subdirectives = directives;

                if (parser.token.type != Token.EOF) parser.reportSyntaxError('syntaxErrors.unallowedHere', parser.getTokenLocation(), { what: parser.token.type });
            }
            catch (problem:Problem) {
            }

            if (r.subscript.problems.length > 0) { for each (var problem:Problem in r.subscript.problems) script.collect(problem); return r }

            return r;
        }

        private function parseUseDirective():DirectiveNode {
            markLocation(), shiftToken();
            var r:DirectiveNode;

            if (consume(Token.DEFAULT)) expectContextKeyword('namespace'), r = new UseDefaultDirectiveNode(parseExpression());

            else expectContextKeyword('namespace'), r = new UseDefaultDirectiveNode(parseExpression());

            return parseSemicolon(), r.span = popLocation(), r;
        }

        private function parseImportDirective():DirectiveNode {
            markLocation(), shiftToken(), markLocation();
            var str:String = expectIdentifierOrKeyword(),
                alias:String,
                aliasSpan:Span,
                importName:Array = [];

            if (token.type == Token.ASSIGN) alias = str, aliasSpan = popLocation(), shiftToken(), markLocation(), importName.push(expectIdentifierOrKeyword());

            else { importName.push(str); if (token.type != Token.DOT) expect(Token.DOT) }

            var wildcard:Boolean;

            while (consume(Token.DOT)) {
                if (consume(Token.TIMES)) { wildcard = true; break }

                importName.push(expectIdentifierOrKeyword());
            }

            parseSemicolon();
            var r:ImportDirectiveNode = new ImportDirectiveNode(alias, importName.join('.'), wildcard);
            return r.aliasSpan = aliasSpan, r.importNameSpan = popLocation(), r.span = popLocation(), r;
        }

        private function parsePackageDefinition():PackageDefinitionNode {
            markLocation(), shiftToken();
            var id:String = expectIdentifierOrKeyword() || '';

            while (consume(Token.DOT)) id += '.' + expectIdentifierOrKeyword();

            var blockContext:ParserContext = new ParserContext;
            blockContext.atPackageFrame = true;
            var block:BlockNode = parseBlock(blockContext);
            var r:PackageDefinitionNode = new PackageDefinitionNode(id, block);
            return r.span = popLocation(), r.script = script, r;
        }

        private function parseOptAnnotatableDefinition(marker:Span, context:ParserContext, str:String = undefined):DirectiveNode {
            if (!str) {
                if (token.type.isKeyword) {
                    if (token.type == Token.CLASS) return parseClassDefinition(marker, context);

                    if (token.type == Token.INTERFACE) return parseInterfaceDefinition(marker, context);

                    if (token.type == Token.FUNCTION) return parseFunctionDefinition(marker, context);

                    if (token.type == Token.VAR || token.type == Token.CONST) return parseVarDefinition(marker, context);
                }
                else str = expectIdentifier();
            }

            switch (str) {
                case 'enum': return parseEnumDefinition(marker, context);

                case 'type': return parseTypeDefinition(marker, context);

                case 'namespace': return parseNamespaceDefinition(marker, context);

                default: return undefined;
            }
        }

        private function parseVarDefinition(marker:Span, context:ParserContext):DirectiveNode {
            markLocation(marker);
            var readOnly:Boolean = token.type == Token.CONST;

            if (!readOnly && context.atEnumFrame) reportSyntaxError('syntaxErrors.illegalEnumVarDeclaration', getTokenLocation());

            shiftToken();
            var bindings:Array = [], attributeCombination:AttributeCombination = this.attributeCombination;

            do {
                var binding:VarBindingNode = parseVarBinding(true);

                if (context.atEnumFrame && (!(binding.pattern is TypedIdNode) || TypedIdNode(binding.pattern).type))
                    reportSyntaxError('syntaxErrors.illegalEnumVarDeclaration', new SourceLocation(script, binding.span));
                else if (context.atClassFrame && !(binding.pattern is TypedIdNode))
                    reportSyntaxError('syntaxErrors.destructuringNotAllowedHere', new SourceLocation(script, binding.pattern.span));

                bindings.push(binding);
            }
            while (consume(Token.COMMA));

            parseSemicolon();
            var r:DefinitionNode = new VarDefinitionNode(readOnly, bindings);
            completeDefinition(r, attributeCombination);

            if (r.modifiers & Modifiers.STATIC && !context.atClassFrame && !context.atEnumFrame) reportSyntaxError('syntaxErrors.modifierNotAllowedHere', new SourceLocation(script, r.span), { modifier: 'static' });

            if (r.modifiers & Modifiers.OVERRIDE) reportSyntaxError('syntaxErrors.modifierNotAllowedHere', new SourceLocation(script, r.span), { modifier: 'override' });

            if (r.modifiers & Modifiers.NATIVE) reportSyntaxError('syntaxErrors.modifierNotAllowedHere', new SourceLocation(script, r.span), { modifier: 'native' });

            if (r.modifiers & Modifiers.FINAL) reportSyntaxError('syntaxErrors.modifierNotAllowedHere', new SourceLocation(script, r.span), { modifier: 'final' });

            if (r.modifiers & Modifiers.DYNAMIC) reportSyntaxError('syntaxErrors.modifierNotAllowedHere', new SourceLocation(script, r.span), { modifier: 'dynamic' });

            return r;
        }

        private function parseFunctionDefinition(marker:Span, context:ParserContext):DirectiveNode {
            markLocation(marker), shiftToken();
            var attributeCombination:AttributeCombination = this.attributeCombination,
                nameSpan:Span = token.span,
                str:String = expectIdentifier(true),
                getter:Boolean,
                setter:Boolean,
                atConstructor:Boolean;

            if (token.type == Token.IDENTIFIER) {
                if (str == 'get') getter = true, nameSpan = token.span, str = consumeIdentifier(true);

                else if (str == 'set') setter = true, nameSpan = token.span, str = consumeIdentifier(true);
            }
            else if (str == context.classLocalName) atConstructor = true;

            var common:FunctionCommonNode = parseFunctionCommon(true, atConstructor);
            var r:FunctionDefinitionNode = new FunctionDefinitionNode(str, common);
            r.nameSpan = nameSpan,
            common.flags |= (atConstructor ? FunctionFlags.CONSTRUCTOR : 0) | (getter ? FunctionFlags.GETTER : 0) | (setter ? FunctionFlags.SETTER : 0);
            completeDefinition(r, attributeCombination);

            if (r.modifiers & Modifiers.STATIC && !context.atClassFrame && !context.atEnumFrame) reportSyntaxError('syntaxErrors.modifierNotAllowedHere', new SourceLocation(script, nameSpan), { modifier: 'static' });

            if (r.modifiers & Modifiers.FINAL && !context.atClassFrame) reportSyntaxError('syntaxErrors.modifierNotAllowedHere', new SourceLocation(script, nameSpan), { modifier: 'final' });

            if (r.modifiers & Modifiers.OVERRIDE && !context.atClassFrame) reportSyntaxError('syntaxErrors.modifierNotAllowedHere', new SourceLocation(script, nameSpan), { modifier: 'override' });

            if (r.modifiers & Modifiers.DYNAMIC) reportSyntaxError('syntaxErrors.modifierNotAllowedHere', new SourceLocation(script, nameSpan), { modifier: 'dynamic' });

            if (common.flags & FunctionFlags.YIELD && (common.flags & FunctionFlags.CONSTRUCTOR || common.flags & FunctionFlags.GETTER || common.flags & FunctionFlags.SETTER)) reportSyntaxError('syntaxErrors.functionMustNotContainYield', new SourceLocation(script, nameSpan));

            if (common.flags & FunctionFlags.AWAIT && (common.flags & FunctionFlags.CONSTRUCTOR || common.flags & FunctionFlags.GETTER || common.flags & FunctionFlags.SETTER)) reportSyntaxError('syntaxErrors.functionMustNotContainAwait', new SourceLocation(script, nameSpan));

            if (r.modifiers & Modifiers.NATIVE) {
                if (context.atInterfaceFrame) reportSyntaxError('syntaxErrors.modifierNotAllowedHere', new SourceLocation(script, nameSpan), { modifier: 'native' });

                if (r.common.body) reportSyntaxError('syntaxErrors.functionMustOmitBody', new SourceLocation(script, nameSpan));
            }
            else if (!context.atInterfaceFrame && !common.body) reportSyntaxError('syntaxErrors.functionMustContainBody', new SourceLocation(script, nameSpan));

            return r;
        }

        private function parseFunctionCommon(fromFunctionDefinition:Boolean = false, atConstructor:Boolean = false):FunctionCommonNode {
            markLocation(), openParen('syntaxErrors.words.argumentList');
            var params:Array, optParams:Array, rest:RestParamNode;

            if (token.type != Token.RPAREN) {
                do {
                    if (consume(Token.ELLIPSIS)) { markLocation(), rest = new RestParamNode(expectIdentifier()), rest.span = popLocation(); break }

                    var binding:VarBindingNode = parseVarBinding(true);

                    if (binding.initialiser) optParams ||= [], optParams.push(binding);

                    else {
                        if (optParams) reportSyntaxError('syntaxErrors.illegalRequiredParameter', new SourceLocation(script, binding.span));

                        params ||= [], params.push(binding);
                    }
                }
                while (consume(Token.COMMA));
            }

            closeParen();
            var result:ExpressionNode;

            if (consume(Token.COLON)) {
                if (token.type == Token.VOID) markLocation(), shiftToken(), result = new VoidTypeNode, result.span = popLocation();

                else result = parseTypeExpression();
            }

            if (atConstructor && result) reportSyntaxError('syntaxErrors.constructorMustNotSpecifyResultType', new SourceLocation(script, result.span));

            functionFlagsStack.push(0);

            var body:Node = parseFunctionBody(fromFunctionDefinition, atConstructor);
            var flags:uint = functionFlagsStack.pop();
            var common:FunctionCommonNode = new FunctionCommonNode(params, optParams, rest, result, body);
            common.flags = flags;
            return common.span = popLocation(), common;
        }

        private function parseFunctionBody(fromFunctionDefinition:Boolean = false, atConstructor:Boolean = false):Node {
            var context:ParserContext = new ParserContext;
            context.atConstructorBlock = atConstructor;
            var block:BlockNode = token.type == Token.LBRACE ? parseBlock(context) : undefined;

            if (block) return block;

            if (token.type == Token.EOF || (tokenIsAtNewLine && script.getLineIndent(token.firstLine) <= script.getLineIndent(previousToken.lastLine)) || (token.type == Token.SEMICOLON && fromFunctionDefinition)) {
                if (fromFunctionDefinition) parseSemicolon();

                return undefined;
            }

            var exp:ExpressionNode = parseExpression(true, OperatorPrecedence.ASSIGNMENT_OPERATOR);

            if (fromFunctionDefinition) parseSemicolon();

            return exp;
        }

        private function parseNamespaceDefinition(marker:Span, context:ParserContext):DirectiveNode {
            markLocation(marker);
            var attributeCombination:AttributeCombination = this.attributeCombination;
            var nameSpan:Span = token.span;
            var str:String = expectIdentifier(true);
            var r:DefinitionNode;

            if (token.type == Token.LBRACE) {
                var block:BlockNode = parseBlock(new ParserContext);
                r = new ObjectDefinitionNode(str, block);
                r.nameSpan = nameSpan, completeDefinition(r, attributeCombination);

                if (r.modifiers & Modifiers.STATIC && !context.atClassFrame && !context.atEnumFrame) reportSyntaxError('syntaxErrors.modifierNotAllowedHere', new SourceLocation(script, nameSpan), { modifier: 'static' });

                if (r.modifiers & Modifiers.OVERRIDE) reportSyntaxError('syntaxErrors.modifierNotAllowedHere', new SourceLocation(script, nameSpan), { modifier: 'override' });

                if (r.modifiers & Modifiers.NATIVE) reportSyntaxError('syntaxErrors.modifierNotAllowedHere', new SourceLocation(script, nameSpan), { modifier: 'native' });

                if (context.atClassFrame || context.atEnumFrame || context.atInterfaceFrame)
                    r.modifiers |= Modifiers.STATIC;
                return r;
            }
            var exp:ExpressionNode = consume(Token.ASSIGN) ? parseExpression() : undefined;
            parseSemicolon();
            r = new NamespaceDefinitionNode(str, exp);
            r.nameSpan = nameSpan;
            completeDefinition(r, attributeCombination);

            if (r.modifiers & Modifiers.STATIC && !context.atClassFrame && !context.atEnumFrame) reportSyntaxError('syntaxErrors.modifierNotAllowedHere', new SourceLocation(script, nameSpan), { modifier: 'static' });

            if (r.modifiers & Modifiers.OVERRIDE) reportSyntaxError('syntaxErrors.modifierNotAllowedHere', new SourceLocation(script, nameSpan), { modifier: 'override' });

            if (r.modifiers & Modifiers.NATIVE) reportSyntaxError('syntaxErrors.modifierNotAllowedHere', new SourceLocation(script, nameSpan), { modifier: 'native' });

            if (r.modifiers & Modifiers.FINAL) reportSyntaxError('syntaxErrors.modifierNotAllowedHere', new SourceLocation(script, nameSpan), { modifier: 'final' });

            if (r.modifiers & Modifiers.DYNAMIC) reportSyntaxError('syntaxErrors.modifierNotAllowedHere', new SourceLocation(script, nameSpan), { modifier: 'dynamic' });

            return r;
        }

        private function parseTypeDefinition(marker:Span, context:ParserContext):DirectiveNode {
            markLocation(marker);
            var attributeCombination:AttributeCombination = this.attributeCombination;
            var nameSpan:Span = token.span;
            var str:String = expectIdentifier(true);
            expect(Token.ASSIGN);
            var type:ExpressionNode = parseTypeExpression();
            parseSemicolon();
            var r:DefinitionNode = new TypeDefinitionNode(str, type);
            r.nameSpan = nameSpan;
            completeDefinition(r, attributeCombination);

            if (r.modifiers & Modifiers.STATIC && !context.atClassFrame && !context.atEnumFrame) reportSyntaxError('syntaxErrors.modifierNotAllowedHere', new SourceLocation(script, nameSpan), { modifier: 'static' });

            if (r.modifiers & Modifiers.OVERRIDE) reportSyntaxError('syntaxErrors.modifierNotAllowedHere', new SourceLocation(script, nameSpan), { modifier: 'override' });

            if (r.modifiers & Modifiers.NATIVE) reportSyntaxError('syntaxErrors.modifierNotAllowedHere', new SourceLocation(script, nameSpan), { modifier: 'native' });

            if (r.modifiers & Modifiers.FINAL) reportSyntaxError('syntaxErrors.modifierNotAllowedHere', new SourceLocation(script, nameSpan), { modifier: 'final' });

            if (r.modifiers & Modifiers.DYNAMIC) reportSyntaxError('syntaxErrors.modifierNotAllowedHere', new SourceLocation(script, nameSpan), { modifier: 'dynamic' });

            if (context.atClassFrame || context.atEnumFrame || context.atInterfaceFrame)
                r.modifiers |= Modifiers.STATIC;

            return r;
        }

        private function parseClassDefinition(marker:Span, context:ParserContext):DirectiveNode {
            markLocation(marker), shiftToken();
            var attributeCombination:AttributeCombination = this.attributeCombination;
            var nameSpan:Span = token.span;
            var name:String = expectIdentifier(true);
            var extendsElement:ExpressionNode, implementsList:Array;

            if (consumeContextKeyword('extends')) extendsElement = parseTypeExpression();

            if (consumeContextKeyword('implements')) {
                implementsList ||= [];

                do implementsList.push(parseTypeExpression()); while (consume(Token.COMMA));
            }

            var blockContext:ParserContext = new ParserContext;
            blockContext.atClassFrame = true, blockContext.classLocalName = name;
            var block:BlockNode = parseBlock(blockContext);
            var r:DefinitionNode = new ClassDefinitionNode(name, extendsElement, implementsList, block);
            r.nameSpan = nameSpan, completeDefinition(r, attributeCombination);

            if (r.modifiers & Modifiers.STATIC && !context.atClassFrame && !context.atEnumFrame) reportSyntaxError('syntaxErrors.modifierNotAllowedHere', new SourceLocation(script, nameSpan), { modifier: 'static' });

            if (r.modifiers & Modifiers.OVERRIDE) reportSyntaxError('syntaxErrors.modifierNotAllowedHere', new SourceLocation(script, nameSpan), { modifier: 'override' });

            if (r.modifiers & Modifiers.NATIVE) reportSyntaxError('syntaxErrors.modifierNotAllowedHere', new SourceLocation(script, nameSpan), { modifier: 'native' });

            if (context.atClassFrame || context.atEnumFrame || context.atInterfaceFrame)
                r.modifiers |= Modifiers.STATIC;

            return r;
        }

        private function parseInterfaceDefinition(marker:Span, context:ParserContext):DirectiveNode {
            markLocation(marker), shiftToken();
            var attributeCombination:AttributeCombination = this.attributeCombination;
            var nameSpan:Span = token.span;
            var name:String = expectIdentifier(true);
            var extendsList:Array;

            if (consumeContextKeyword('extends')) {
                extendsList ||= [];

                do extendsList.push(parseTypeExpression()); while (consume(Token.COMMA));
            }

            var blockContext:ParserContext = new ParserContext;
            blockContext.atInterfaceFrame = true;
            var block:BlockNode = parseBlock(blockContext);
            var r:DefinitionNode = new InterfaceDefinitionNode(name, extendsList, block);
            r.nameSpan = nameSpan, completeDefinition(r, attributeCombination);

            for each (var drtv:DirectiveNode in block.directives) if (!(drtv is FunctionDefinitionNode || drtv is ClassDefinitionNode || drtv is InterfaceDefinitionNode || drtv is EnumDefinitionNode || drtv is TypeDefinitionNode)) reportSyntaxError('syntaxErrors.interfaceUnallowedDirective', new SourceLocation(script, drtv.span));

            if (r.modifiers & Modifiers.STATIC && !context.atClassFrame && !context.atEnumFrame) reportSyntaxError('syntaxErrors.modifierNotAllowedHere', new SourceLocation(script, nameSpan), { modifier: 'static' });

            if (r.modifiers & Modifiers.OVERRIDE) reportSyntaxError('syntaxErrors.modifierNotAllowedHere', new SourceLocation(script, nameSpan), { modifier: 'override' });

            if (r.modifiers & Modifiers.NATIVE) reportSyntaxError('syntaxErrors.modifierNotAllowedHere', new SourceLocation(script, nameSpan), { modifier: 'native' });

            if (r.modifiers & Modifiers.FINAL) reportSyntaxError('syntaxErrors.modifierNotAllowedHere', new SourceLocation(script, nameSpan), { modifier: 'final' });

            if (r.modifiers & Modifiers.DYNAMIC) reportSyntaxError('syntaxErrors.modifierNotAllowedHere', new SourceLocation(script, nameSpan), { modifier: 'dynamic' });

            if (context.atClassFrame || context.atEnumFrame || context.atInterfaceFrame)
                r.modifiers |= Modifiers.STATIC;

            return r;
        }

        private function parseEnumDefinition(marker:Span, context:ParserContext):DirectiveNode {
            markLocation(marker);
            var attributeCombination:AttributeCombination = this.attributeCombination;
            var nameSpan:Span = token.span;
            var name:String = expectIdentifier(true);
            var numericType:ExpressionNode = consume(Token.COLON) ? parseTypeExpression() : undefined;
            var blockContext:ParserContext = new ParserContext;
            blockContext.atEnumFrame = true;
            var block:BlockNode = parseBlock(blockContext);
            var r:DefinitionNode = new EnumDefinitionNode(name, numericType, block);
            r.nameSpan = nameSpan, completeDefinition(r, attributeCombination);

            if (r.modifiers & Modifiers.STATIC && !context.atClassFrame && !context.atEnumFrame) reportSyntaxError('syntaxErrors.modifierNotAllowedHere', new SourceLocation(script, nameSpan), { modifier: 'static' });

            if (r.modifiers & Modifiers.OVERRIDE) reportSyntaxError('syntaxErrors.modifierNotAllowedHere', new SourceLocation(script, nameSpan), { modifier: 'override' });

            if (r.modifiers & Modifiers.NATIVE) reportSyntaxError('syntaxErrors.modifierNotAllowedHere', new SourceLocation(script, nameSpan), { modifier: 'native' });

            if (r.modifiers & Modifiers.FINAL) reportSyntaxError('syntaxErrors.modifierNotAllowedHere', new SourceLocation(script, nameSpan), { modifier: 'final' });

            if (r.modifiers & Modifiers.DYNAMIC) reportSyntaxError('syntaxErrors.modifierNotAllowedHere', new SourceLocation(script, nameSpan), { modifier: 'dynamic' });

            if (context.atClassFrame || context.atEnumFrame || context.atInterfaceFrame)
                r.modifiers |= Modifiers.STATIC;

            return r;
        }

        private function completeDefinition(node:DefinitionNode, attributeCombination:AttributeCombination):void {
            node.span = popLocation();
            node.accessModifier = attributeCombination.accessModifier;
            node.metaData = attributeCombination.metaData;
            node.modifiers = (attributeCombination.finalModifier ? Modifiers.FINAL : 0) | (attributeCombination.nativeModifier ? Modifiers.NATIVE : 0) | (attributeCombination.overrideModifier ? Modifiers.OVERRIDE : 0) | (attributeCombination.staticModifier ? Modifiers.STATIC : 0) | (attributeCombination.dynamicModifier ? Modifiers.DYNAMIC : 0);
        }

        public function parseProgram():ProgramNode {
            markLocation();
            var packages:Array = [];

            while (token.type == Token.PACKAGE) packages.push(parsePackageDefinition());

            var context:ParserContext = new ParserContext;
            functionFlagsStack.push(FunctionFlags.AWAIT);
            var topIncludings:Array;

            while (token.type == Token.IDENTIFIER && token.string == 'include') {
                markLocation(), shiftToken();
                var drtv:IncludeDirectiveNode = parseIncludeDirective(context, true)

                if (drtv.subpackages) {
                    for each (var p:PackageDefinitionNode in drtv.subpackages) packages.push(p);

                    drtv.subpackages = undefined;
                }

                topIncludings ||= [], topIncludings.push(drtv);

                if (drtv.subdirectives && drtv.subdirectives.length > 0) break;
            }

            var directives:Array = parseOptDirectives(context);

            if (topIncludings) for (var i:int = topIncludings.length - 1; i != -1; --i) directives.unshift(topIncludings[i]);

            while (token.type != Token.EOF) {
                var drtv2:Array = parseOptDirectives(context);

                if (drtv2.length > 0) { var span:Span = drtv2[0].span; reportSyntaxError('syntaxErrors.expectingBefore', new SourceLocation(script, Span.point(span.firstLine, span.start)), { what: Token.SEMICOLON, before: new ProblemWord('syntaxErrors.words.directive') }) }

                else reportSyntaxError('syntaxErrors.unallowedHere', getTokenLocation(), { what: token.type }), shiftToken();
            }

            functionFlagsStack.pop();

            var program:ProgramNode = new ProgramNode(packages, directives);
            return program.script = script, program.span = popLocation(), program;
        }
    }
}