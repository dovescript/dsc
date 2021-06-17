package dsc.parsing {

    import com.siteblade.util.CharArray;

    import dsc.*;

    import dsc.parsing.ast.CommentNode;

    public final class Lexer {

        public var token:TokenState = new TokenState;

        public var mode:LexerMode = LexerMode.NORMAL;

        private var _source:CharArray;

        private var _line:uint = 1;

        private var _script:Script;

        /**
         * Constructs a Lexer object.
         *
         * The <i>options</i> parameter accepts <code>initialLine</code>, <code>initialLineStart</code> and <code>initialIndex</code> properties.
         */
        public function Lexer(script:Script, options:* = undefined) {
            _script = script;
            _source = _script.text;
            options ||= {};

            // initial location

            _source.position = uint(options.initialIndex), _line = uint(options.initialLine || 1);

            var lineStart:uint = uint(options.initialLineStart);

            for (var i:uint = 1; i != _line; ++i) _script._lineStarts.push(lineStart);
        }

        public function get script():Script { return _script }

        public function get source():CharArray { return _source }

        private function reportUnexpectedCharacter():Problem {
            var problem:Problem;

            if (!_source.hasRemaining) problem = new Problem('syntaxErrors.empty', 'syntaxError', getCharacterLocation());

            else problem = new Problem('syntaxErrors.unexpectedCharacter', 'syntaxError', getCharacterLocation(), { charac: String.fromCharCode(_source[0]) });

            return _script.collect(problem);
        }

        private function getCharacterLocation():SourceLocation { return new SourceLocation(_script, Span.point(_line, _source.position)) }

        private function getCharacterAsProblemArgument():* { return _source.hasRemaining ? String.fromCharCode(_source[0]) : Token.EOF }

        private function beginToken():void { token.start = _source.position, token.firstLine = _line }

        private function endToken(type:Token):void { token.type = type, token.end = _source.position, token.lastLine = _line }

        private function endDeviatedToken(type:Token, length:uint):void { _source.position += length, endToken(type) }

        public function shift():void {
            if (mode == LexerMode.NORMAL) _scan();

            else if (mode == LexerMode.XML_TAG) _scanXMLTag();

            else _scanXMLContent();
        }

        public function scanRegExpLiteral():void {
            var cv:uint;
            _source.position = token.start + 1, _source.beginSlice();

            while (1) {
                cv = _source[0];
                if (cv == 0x5c) {
                    _source.shift();
                    if (!scanLineTerminator(_source[0])) {
                        if (!_source.hasRemaining) throw reportUnexpectedCharacter();
                        _source.shift();
                    }
                }
                else if (cv == 0x2f) break;

                else if (!_source.hasRemaining) throw reportUnexpectedCharacter();

                else if (!scanLineTerminator(cv)) _source.shift();
            }

            var body:String = _source.endSlice();
            _source.shift();
            var flags:String = '';

            while (1) {
                cv = _source[0];

                if (SourceCharacter.isIdentifierPart(cv)) flags += String.fromCharCode(_source.shift());

                else if (cv == 0x5c) {
                    var start:uint = _source.position;
                    _source.shift();

                    if (_source[0] == 0x75) _source.shift(), cv = scanUnicodeEscape(), flags += String.fromCharCode(cv);

                    else {
                        if (!_source.hasRemaining) throw reportUnexpectedCharacter();
                        flags += String.fromCharCode(_source.shift());
                    }
                }
                else break;
            }

            endToken(Token.REG_EXP_LITERAL);
            token.string = body;
            token.regExpFlags = flags;
        }

        private function _scan():void {
            var cv:uint;

            while (1) {
                cv = _source[0];

                if (SourceCharacter.isWhiteSpace(cv)) _source.shift();

                else if (!scanLineTerminator(cv) && !scanComment()) break;
            }

            beginToken();

            // Identifier

            if (SourceCharacter.isIdentifierStart(cv)) {
                _source.beginSlice(), _source.shift();

                while (1) {
                    cv = _source[0];

                    if (SourceCharacter.isIdentifierPart(cv)) _source.shift();

                    else if (cv == 0x5c) { scanEscapedIdentifier(_source.endSlice()); break }

                    else {
                        var idName:String = _source.endSlice();
                        var keyword:Token = filterKeyword(idName);
                        endToken(keyword ? keyword : Token.IDENTIFIER);
                        token.string = idName;
                        break;
                    }
                }
            }

            else if (SourceCharacter.isDecimalDigit(cv)) scanNumericLiteral(cv, false);

            else {
                var sp:String = _source.slice(0, 4);

                if (sp == '>>>=') { endDeviatedToken(Token.UNSIGNED_RSHIFT_ASSIGN, 4); return }

                sp = sp.slice(0, 3);

                switch (sp) {

                case '...': endDeviatedToken(Token.ELLIPSIS, 3); return;

                case '&&=': endDeviatedToken(Token.LOGICAL_AND_ASSIGN, 3); return;

                case '^^=': endDeviatedToken(Token.LOGICAL_XOR_ASSIGN, 3); return;

                case '||=': endDeviatedToken(Token.LOGICAL_OR_ASSIGN, 3); return;

                case '>>>': endDeviatedToken(Token.UNSIGNED_RIGHT_SHIFT, 3); return;

                case '===': endDeviatedToken(Token.STRICT_EQUALS, 3); return;

                case '!==': endDeviatedToken(Token.STRICT_NOT_EQUALS, 3); return;

                case '<<=': endDeviatedToken(Token.LSHIFT_ASSIGN, 3); return;

                case '>>=': endDeviatedToken(Token.RSHIFT_ASSIGN, 3); return;

                }

                sp = sp.slice(0, 2);

                switch (sp) {

                case '..': endDeviatedToken(Token.DESCENDANTS, 2); return;

                case '::': endDeviatedToken(Token.COLON_COLON, 2); return;

                case '++': endDeviatedToken(Token.INCREMENT, 2); return;

                case '--': endDeviatedToken(Token.DECREMENT, 2); return;

                case '<<': endDeviatedToken(Token.LEFT_SHIFT, 2); return;

                case '>>': endDeviatedToken(Token.RIGHT_SHIFT, 2); return;

                case '==': endDeviatedToken(Token.EQUALS, 2); return;

                case '!=': endDeviatedToken(Token.NOT_EQUALS, 2); return;

                case '<=': endDeviatedToken(Token.LE, 2); return;

                case '>=': endDeviatedToken(Token.GE, 2); return;

                case '&&': endDeviatedToken(Token.LOGICAL_AND, 2); return;

                case '||': endDeviatedToken(Token.LOGICAL_OR, 2); return;

                case '+=': endDeviatedToken(Token.ADD_ASSIGN, 2); return;

                case '-=': endDeviatedToken(Token.SUBTRACT_ASSIGN, 2); return;

                case '*=': endDeviatedToken(Token.MULTIPLY_ASSIGN, 2); return;

                case '/=': endDeviatedToken(Token.DIVIDE_ASSIGN, 2); return;

                case '%=': endDeviatedToken(Token.REMAINDER_ASSIGN, 2); return;

                case '&=': endDeviatedToken(Token.BIT_AND_ASSIGN, 2); return;

                case '^=': endDeviatedToken(Token.BIT_XOR_ASSIGN, 2); return;

                case '|=': endDeviatedToken(Token.BIT_OR_ASSIGN, 2); return;

                }

                cv = sp.charCodeAt(0);

                switch (cv) {

                case 0x2e:
                    if (SourceCharacter.isDecimalDigit(_source[1])) { scanNumericLiteral(0, true); return }

                    endDeviatedToken(Token.DOT, 1); return;

                case 0x2c: endDeviatedToken(Token.COMMA, 1); return;

                case 0x3d: endDeviatedToken(Token.ASSIGN, 1); return;

                case 0x3a: endDeviatedToken(Token.COLON, 1); return;

                case 0x3b: endDeviatedToken(Token.SEMICOLON, 1); return;

                case 0x28: endDeviatedToken(Token.LPAREN, 1); return;

                case 0x29: endDeviatedToken(Token.RPAREN, 1); return;

                case 0x5b: endDeviatedToken(Token.LBRACKET, 1); return;

                case 0x5d: endDeviatedToken(Token.RBRACKET, 1); return;

                case 0x7b: endDeviatedToken(Token.LBRACE, 1); return;

                case 0x7d: endDeviatedToken(Token.RBRACE, 1); return;

                // StringLiteral

                case 0x22: case 0x27: case 0x2018: case 0x201c: scanStringLiteral(cv); return;

                case 0x40: endDeviatedToken(Token.ATTRIBUTE, 1); return;

                case 0x3f: endDeviatedToken(Token.QUESTION_MARK, 1); return;

                case 0x21: endDeviatedToken(Token.EXCLAMATION_MARK, 1); return;

                case 0x2242: endDeviatedToken(Token.NOT_EQUALS, 1); return;

                case 0x2b: endDeviatedToken(Token.PLUS, 1); return;

                case 0x2d: case 0x2212: endDeviatedToken(Token.MINUS, 1); return;

                case 0x2a: case 0xd7: endDeviatedToken(Token.TIMES, 1); return;

                case 0x2f: endDeviatedToken(Token.SLASH, 1); return;

                case 0x25: endDeviatedToken(Token.REMAINDER, 1); return;

                case 0x26: endDeviatedToken(Token.BIT_AND, 1); return;

                case 0x5e: endDeviatedToken(Token.BIT_XOR, 1); return;

                case 0x7c: endDeviatedToken(Token.BIT_OR, 1); return;

                case 0x7e: endDeviatedToken(Token.BIT_NOT, 1); return;

                case 0x3c: endDeviatedToken(Token.LT, 1); return;

                case 0x3e: endDeviatedToken(Token.GT, 1); return;

                case 0x2264:endDeviatedToken(Token.LE, 1); return;

                case 0x2265: endDeviatedToken(Token.GE, 1); return;

                // Identifier

                case 0x5c:
                    _source.shift();

                    if (_source[0] == 0x75) _source.shift(), cv = scanUnicodeEscape();

                    else {
                        if (!_source.hasRemaining) throw reportUnexpectedCharacter();

                        cv = _source.shift();
                    }

                    scanEscapedIdentifier(String.fromCharCode(cv)); return;

                default:
                    if (_source.hasRemaining) throw reportUnexpectedCharacter();

                    else endToken(Token.EOF);

                }
            }
        }

        private function scanLineTerminator(cv:uint):Boolean {
            if (SourceCharacter.isLineTerminator(cv)) {
                if (cv == 0x0d && _source[1] == 0x0a) _source.shift();

                return _source.shift(), ++_line, _script._lineStarts.push(_source.position), true;
            }

            return false;
        }

        private function scanComment():Boolean {
            if (_source[0] != 0x2f) return false;

            var node:CommentNode, cv:uint = _source[1];

            if (cv == 0x2a) {
                var location:SourceLocation = getCharacterLocation(), builder:Array = [], nested:uint = 1;
                _source.position += 2, _source.beginSlice();

                while (1) {
                    cv = _source[0];

                    if (cv == 0x2a && _source[1] == 0x2f) {
                        if (!!(--nested)) _source.position += 2;

                        else { builder.push(_source.endSlice()), _source.position += 2; break }
                    }
                    else if (cv == 0x2f && _source[1] == 0x2a) ++nested, _source.position += 2;

                    else if (SourceCharacter.isLineTerminator(cv)) builder.push(_source.endSlice()), scanLineTerminator(cv), builder.push(cv == 0x0d ? '\n' : String.fromCharCode(cv)), _source.beginSlice();

                    else if (_source.hasRemaining) _source.shift();

                    else throw reportUnexpectedCharacter();
                }

                return node = new CommentNode(builder.join(''), true), node.span = new Span(location.span.firstLine, location.span.start, _line, _source.position), _script.comments.push(node), true;
            }

            if (cv == 0x2f) {
                var start:uint = _source.position;
                _source.position += 2,_source.beginSlice();

                while (_source.hasRemaining && !SourceCharacter.isLineTerminator(_source[0])) _source.shift();

                return node = new CommentNode(_source.endSlice(), false), node.span = new Span(_line, start, _line, _source.position), _script.comments.push(node), true;
            }

            return false;
        }

        private function scanNumericLiteral(cv:uint, point:Boolean):void {
            _source.beginSlice(), _source.shift();

            var prependDot:Boolean = point,
                appendDot:Boolean,
                appendZero:Boolean;

            if (point) do _source.shift(); while (SourceCharacter.isDecimalDigit(_source[0]));

            else {
                if (cv == 0x30) {
                    cv = _source[0];

                    if (cv == 0x78 || cv == 0x58) { scanHexLiteral(); return; }
                }
                else while (SourceCharacter.isDecimalDigit(_source[0])) _source.shift();

                appendDot = true;

                if (_source[0] == 0x2e) {
                    appendDot = false, appendZero = true, _source.shift();

                    while (SourceCharacter.isDecimalDigit(_source[0])) appendZero = false, _source.shift();
                }
            }

            cv = _source[0];

            if (cv == 0x65 || cv == 0x45) {
                appendDot = false, appendZero = false, _source.shift(), cv = _source[0];

                if (cv == 0x2b || cv == 0x2d) _source.shift();

                if (!SourceCharacter.isDecimalDigit(_source[0])) throw reportUnexpectedCharacter();

                while (SourceCharacter.isDecimalDigit(_source[0])) _source.shift();
            }

            endToken(Token.NUMERIC_LITERAL), token.number = Number( (prependDot ? '0' : '') + _source.endSlice() + (appendDot ? '.0' : appendZero ? '0' : '') );
        }

        private function scanHexLiteral():void {
            _source.shift();
            var value:uint = scanHexDigit(), digit:int = -1;

            while ((digit = SourceCharacter.hexDigitMV(_source[0])) != -1) value = (value << 4) | digit, _source.shift();

            endToken(Token.NUMERIC_LITERAL), token.number = value;
        }

        private function scanStringLiteral(delim:uint):void {
            _source.shift();
            if (_source[0] == delim && _source[1] == delim) { scanTripleStringLiteral(delim); return }

            delim = delim == 0x2018 ? 0x2019 : delim == 0x201c ? 0x201d : delim;

            var builder:Array;
            _source.beginSlice();

            while (1) {
                var cv:uint = _source[0];

                if (cv == 0x5c) builder ||= [], builder.push(_source.endSlice(), scanEscapeSequence()), _source.beginSlice();

                else if (cv == delim) break;

                else if (SourceCharacter.isLineTerminator(cv)) _script.collect(new Problem('syntaxErrors.illegalLineBreak', 'syntaxError', getCharacterLocation())), scanLineTerminator(cv);

                else if (!_source.hasRemaining) throw reportUnexpectedCharacter();

                else _source.shift();
            }

            var str:String = _source.endSlice();
            if (builder) builder.push(str);
            _source.shift(), endToken(Token.STRING_LITERAL), token.string = builder ? builder.join('') : str;
        }

        private function scanTripleStringLiteral(delim:uint):void {
            var lines:Array = [], builder:Array = [];
            _source.position += 2, scanLineTerminator(_source[0]), _source.beginSlice();

            delim = delim == 0x2018 ? 0x2019 : delim == 0x201c ? 0x201d : delim;

            while (1) {
                var cv:uint = _source[0];

                if (cv == 0x5c) builder.push(_source.endSlice(), scanEscapeSequence()), _source.beginSlice();

                else if (cv == delim && _source[1] == delim && _source[2] == delim) break;

                else if (SourceCharacter.isLineTerminator(cv)) builder.push(_source.endSlice()), lines.push(builder.join('')), builder.length = 0, scanLineTerminator(cv), _source.beginSlice();

                else if (!_source.hasRemaining) throw reportUnexpectedCharacter();

                else _source.shift();
            }

            builder.push(_source.endSlice()), lines.push(builder.join('')), _source.position += 3, endToken(Token.STRING_LITERAL), token.string = joinTripleStringLiteralLines(lines);
        }

        private function joinTripleStringLiteralLines(lines:Array):String {
            var leadLine:String = lines.pop(), indent:uint, i:uint;

            for (i = 0; i != leadLine.length; ++i) if (!SourceCharacter.isWhiteSpace(leadLine.charCodeAt(i))) break;

            indent = i;

            lines = lines.map(function(line) {
                for (i = 0; i != leadLine.length; ++i) if (!SourceCharacter.isWhiteSpace(leadLine.charCodeAt(i)) || i >= indent) break;

                return line.slice(i);
            });

            return lines.push(leadLine.slice(indent)), lines.join('\n');
        }

        private function scanEscapedIdentifier(lastString:String):void {
            var builder:Array = [lastString]; _source.beginSlice();

            while (1) {
                var cv:uint = _source[0];

                if (SourceCharacter.isIdentifierPart(cv)) _source.shift();

                else if (cv == 0x5c) {
                    builder.push(_source.endSlice()), _source.shift();

                    if (_source[0] == 0x75) _source.shift(), cv = scanUnicodeEscape();

                    else if (!_source.hasRemaining) throw reportUnexpectedCharacter();

                    else cv = _source.shift();

                    builder.push(String.fromCharCode(cv)), _source.beginSlice();
                }

                else break;
            }

            builder.push(_source.endSlice()), endToken(Token.IDENTIFIER), token.string = builder.join('');
        }

        private function filterKeyword(str:String):Token {
            switch (str.length) {

            case 1: return undefined;

            case 2: return str == 'as' ? Token.AS : str == 'do' ? Token.DO : str == 'if' ? Token.IF : str == 'in' ? Token.IN : str == 'is' ? Token.IS : undefined;

            case 3: return str == 'for' ? Token.FOR : str == 'new' ? Token.NEW : str == 'try' ? Token.TRY : str == 'use' ? Token.USE : str == 'var' ? Token.VAR : undefined;

            case 4:
                if (str == 'true') return token.boolean = true, Token.BOOLEAN_LITERAL;

                return str == 'case' ? Token.CASE : str == 'else' ? Token.ELSE : str == 'null' ? Token.NULL_LITERAL : str == 'this' ? Token.THIS_LITERAL : str == 'void' ? Token.VOID : str == 'with' ? Token.WITH : undefined;

            case 5:
                if (str == 'false') return token.boolean = false, Token.BOOLEAN_LITERAL;

                return str == 'break' ? Token.BREAK : str == 'catch' ? Token.CATCH : str == 'class' ? Token.CLASS : str == 'const' ? Token.CONST : str == 'super' ? Token.SUPER : str == 'throw' ? Token.THROW : str == 'while' ? Token.WHILE : str == 'yield' ? Token.YIELD : str == 'await' ? Token.AWAIT : undefined;

            case 6: return str == 'delete' ? Token.DELETE : str == 'import' ? Token.IMPORT : str == 'public' ? Token.PUBLIC : str == 'return' ? Token.RETURN : str == 'switch' ? Token.SWITCH : str == 'typeof' ? Token.TYPEOF : undefined;

            case 7: return str == 'default' ? Token.DEFAULT : str == 'finally' ? Token.FINALLY : str == 'package' ? Token.PACKAGE : str == 'private' ? Token.PRIVATE : undefined;

            case 8: return str == 'continue' ? Token.CONTINUE : str == 'function' ? Token.FUNCTION : str == 'internal' ? Token.INTERNAL : undefined;

            case 9: return str == 'interface' ? Token.INTERFACE : str == 'protected' ? Token.PROTECTED : undefined;

            case 10: return str == 'instanceof' ? Token.INSTANCEOF : undefined;

            default: return undefined;

            }
        }

        private function scanEscapeSequence():String {
            _source.shift();
            if (!_source.hasRemaining) throw reportUnexpectedCharacter();

            var cv:uint = _source.shift();

            switch (cv) {
                case 0x75: return String.fromCharCode(scanUnicodeEscape());

                case 0x78: return String.fromCharCode((scanHexDigit() << 4) | scanHexDigit());

                case 0x6e: return '\n';

                case 0x72: return '\r';

                case 0x76: return '\v';

                case 0x74: return '\t';

                case 0x62: return '\b';

                case 0x66: return '\f';

                case 0x30: return '\0';

                case 0x22: return '"';

                case 0x27: return "'";

                case 0x5c: return '\\';
            }

            --_source.position;

            if (scanLineTerminator(cv)) return '';

            return reportUnexpectedCharacter(), _source.shift(), '';
        }

        private function scanUnicodeEscape():uint {
            var cv:uint = _source[0];

            if (cv == 0x7b) {
                _source.shift();
                var r:uint = scanHexDigit();

                while (1) {
                    if (_source[0] == 0x7d) { _source.shift(); break }

                    r = (r << 4) | scanHexDigit();
                }

                return r > 0x10ffff ? 0 : r;
            }
            else return (scanHexDigit() << 12) | (scanHexDigit() << 8) | (scanHexDigit() << 4) | scanHexDigit();
        }

        private function scanHexDigit():uint {
            var r:uint = SourceCharacter.hexDigitMV(_source[0]);

            if (r == -1) throw _script.collect(new Problem('syntaxErrors.expectingBefore', 'syntaxError', getCharacterLocation(), { what: 'hexadecimal digit', before: getCharacterAsProblemArgument() }));

            return _source.shift(), r;
        }

        private function _scanXMLTag():void {
            beginToken(), _source.beginSlice();
            var cv:uint = _source[0];

            if (cv == 0x20) _source.shift(), scanXMLWhitespace();

            else if (SourceCharacter.isXMLNameStart(cv)) {
                do _source.shift(); while (SourceCharacter.isXMLNamePart(_source[0]));

                endToken(Token.XML_NAME), token.string = _source.endSlice();
            }

            else if (cv == 0x22 || cv == 0x27) scanXMLAttributeValue(cv);

            else if (cv == 0x2f && _source[1] == 0x3e) endDeviatedToken(Token.XML_SLASH_GT, 2);

            else if (cv == 0x3e) endDeviatedToken(Token.GT, 1);

            else if (cv == 0x3d) endDeviatedToken(Token.ASSIGN, 1);

            else if (cv == 0x7b) endDeviatedToken(Token.LBRACE, 1);

            else if (cv == 0x0a || cv == 0x09 || cv == 0x0d) scanXMLWhitespace();

            else throw reportUnexpectedCharacter();
        }

        private function scanXMLWhitespace():void {
            while (1) {
                var cv:uint = _source[0];

                if (cv == 0x20 || cv == 0x09) _source.shift();

                else if (cv == 0x0a || cv == 0x0d) scanLineTerminator(cv);

                else break;
            }

            endToken(Token.XML_WHITESPACE);
        }

        private function scanXMLAttributeValue(delim:uint):void {
            _source.shift(), _source.beginSlice();

            while (1) {
                var cv:uint = _source[0];

                if (cv == delim) break;

                else if (_source.hasRemaining) { if (!scanLineTerminator(cv)) _source.shift() }

                else throw reportUnexpectedCharacter();
            }

            var str:String = _source.endSlice();
            _source.shift(), endToken(Token.XML_ATTRIBUTE_VALUE), token.string = str.replace(/\r\n/g, '\n');
        }

        private function _scanXMLContent():void {
            beginToken();
            var cv:uint = _source[0];

            if (cv == 0x3c) { _source.shift(); if (!scanXMLMarkup()) endToken(Token.LT); }

            else if (cv == 0x7b) endDeviatedToken(Token.LBRACE, 1);

            else if (!_source.hasRemaining) throw reportUnexpectedCharacter();

            else {
                _source.beginSlice();

                if (!scanLineTerminator(cv)) _source.shift();

                while (1) {
                    cv = _source[0];

                    if (cv == 0x3c || !_source.hasRemaining) break;

                    else if (!scanLineTerminator(cv)) _source.shift();
                }

                var text:String = _source.endSlice();
                endToken(Token.XML_TEXT), token.string = text.replace(/\r\n/g, '\n');
            }
        }

        public function scanXMLMarkup():Boolean {
            var sp:String = _source.slice(0, 8);

            if (sp == '![CDATA[') return scanXMLCDATA(), true;

            if (sp.slice(0, 3) == '!--') return scanXMLComment(), true;

            if (sp.charAt(0) == '?') return scanXMLPI(), true;

            return false;
        }

        private function scanXMLCDATA():void {
            _source.position += 8, _source.beginSlice();

            while (1) {
                var cv:uint = _source[0];

                if (cv == 0x5d && _source[1] == 0x5d && _source[2] == 0x3e) { _source.position += 3; break }

                else if (!scanLineTerminator(cv)) {
                    if (!_source.hasRemaining) throw reportUnexpectedCharacter();

                    _source.shift();
                }
            }

            endToken(Token.XML_MARKUP), token.string = '<![CDATA[' + _source.endSlice().replace(/\r\n/g, '\n');
        }

        private function scanXMLComment():void {
            _source.position += 3, _source.beginSlice();

            while (1) {
                var cv:uint = _source[0];

                if (cv == 0x2d && _source[1] == 0x2d && _source[2] == 0x3e) { _source.position += 3; break }

                else if (!scanLineTerminator(cv)) {
                    if (!_source.hasRemaining) throw reportUnexpectedCharacter();

                    _source.shift();
                }
            }

            endToken(Token.XML_MARKUP), token.string = '<!--' + _source.endSlice().replace(/\r\n/g, '\n');
        }

        private function scanXMLPI():void {
            _source.shift(), _source.beginSlice();

            while (1) {
                var cv:uint = _source[0];

                if (cv == 0x3f && _source[1] == 0x3e) { _source.position += 2; break }

                else if (!scanLineTerminator(cv)) {
                    if (!_source.hasRemaining) throw reportUnexpectedCharacter();

                    _source.shift();
                }
            }

            endToken(Token.XML_MARKUP), token.string = '<?' + _source.endSlice().replace(/\r\n/g, '\n');
        }
    }
}