package dsc.parsing {

    import dsc.semantics.*;

    public final class Token {

        public static const EOF:Token = new Token(0x0);

        public static const IDENTIFIER:Token = new Token(0x1);

        public static const STRING_LITERAL:Token = new Token(0x2);

        public static const BOOLEAN_LITERAL:Token = new Token(0x3);

        public static const NUMERIC_LITERAL:Token = new Token(0x4);

        public static const NULL_LITERAL:Token = new Token(0x5);

        public static const THIS_LITERAL:Token = new Token(0x6);

        public static const REG_EXP_LITERAL:Token = new Token(0x7);

        public static const XML_WHITESPACE:Token = new Token(0x8);

        public static const XML_ATTRIBUTE_VALUE:Token = new Token(0x9);

        public static const XML_MARKUP:Token = new Token(0xA);

        public static const XML_TEXT:Token = new Token(0xB);

        public static const XML_NAME:Token = new Token(0xC);

        public static const XML_LT_SLASH:Token = new Token(0xD);

        public static const XML_SLASH_GT:Token = new Token(0xE);


        public static const DOT:Token = new Token(0x40);

        public static const DESCENDANTS:Token = new Token(0x41);

        public static const ELLIPSIS:Token = new Token(0x42);

        public static const COMMA:Token = new Token(0x43);

        public static const SEMICOLON:Token = new Token(0x44);

        public static const COLON:Token = new Token(0x45);

        public static const COLON_COLON:Token = new Token(0x46);

        public static const LPAREN:Token = new Token(0x47);

        public static const RPAREN:Token = new Token(0x48);

        public static const LBRACKET:Token = new Token(0x49);

        public static const RBRACKET:Token = new Token(0x4A);

        public static const LBRACE:Token = new Token(0x4B);

        public static const RBRACE:Token = new Token(0x4C);

        public static const ATTRIBUTE:Token = new Token(0x4D);

        public static const QUESTION_MARK:Token = new Token(0x4E);

        public static const EXCLAMATION_MARK:Token = new Token(0x4F);

        public static const INCREMENT:Token = new Token(0x50);

        public static const DECREMENT:Token = new Token(0x51);

        public static const PLUS:Token = new Token(0x52);

        public static const MINUS:Token = new Token(0x53);

        public static const TIMES:Token = new Token(0x54);

        public static const SLASH:Token = new Token(0x55);

        public static const REMAINDER:Token = new Token(0x56);

        public static const BIT_AND:Token = new Token(0x57);

        public static const BIT_XOR:Token = new Token(0x58);

        public static const BIT_OR:Token = new Token(0x59);

        public static const BIT_NOT:Token = new Token(0x5A);

        public static const LEFT_SHIFT:Token = new Token(0x5B);

        public static const RIGHT_SHIFT:Token = new Token(0x5C);

        public static const UNSIGNED_RIGHT_SHIFT:Token = new Token(0x5D);

        public static const LT:Token = new Token(0x5E);

        public static const GT:Token = new Token(0x5F);

        public static const LE:Token = new Token(0x60);

        public static const GE:Token = new Token(0x61);

        public static const EQUALS:Token = new Token(0x62);

        public static const NOT_EQUALS:Token = new Token(0x63);

        public static const LOGICAL_AND:Token = new Token(0x64);

        public static const LOGICAL_OR:Token = new Token(0x65);

        public static const STRICT_EQUALS:Token = new Token(0x66);

        public static const STRICT_NOT_EQUALS:Token = new Token(0x67);


        public static const AS:Token = new Token(0x80);

        public static const DO:Token = new Token(0x81);

        public static const IF:Token = new Token(0x82);

        public static const IN:Token = new Token(0x83);

        public static const IS:Token = new Token(0x84);

        public static const FOR:Token = new Token(0x85);

        public static const NEW:Token = new Token(0x86);

        public static const TRY:Token = new Token(0x87);

        public static const USE:Token = new Token(0x88);

        public static const VAR:Token = new Token(0x89);

        public static const CASE:Token = new Token(0x8A);

        public static const ELSE:Token = new Token(0x8B);

        public static const VOID:Token = new Token(0x8C);

        public static const WITH:Token = new Token(0x8D);

        public static const BREAK:Token = new Token(0x8E);

        public static const CATCH:Token = new Token(0x8F);

        public static const CLASS:Token = new Token(0x90);

        public static const CONST:Token = new Token(0x91);

        public static const SUPER:Token = new Token(0x92);

        public static const THROW:Token = new Token(0x93);

        public static const WHILE:Token = new Token(0x94);

        public static const DELETE:Token = new Token(0x95);

        public static const IMPORT:Token = new Token(0x96);

        public static const PUBLIC:Token = new Token(0x97);

        public static const RETURN:Token = new Token(0x98);

        public static const SWITCH:Token = new Token(0x99);

        public static const TYPEOF:Token = new Token(0x9A);

        public static const DEFAULT:Token = new Token(0x9B);

        public static const FINALLY:Token = new Token(0x9C);

        public static const PACKAGE:Token = new Token(0x9D);

        public static const PRIVATE:Token = new Token(0x9E);

        public static const CONTINUE:Token = new Token(0x9F);

        public static const FUNCTION:Token = new Token(0xA0);

        public static const INTERNAL:Token = new Token(0xA1);

        public static const INTERFACE:Token = new Token(0xA2);

        public static const PROTECTED:Token = new Token(0xA3);

        public static const INSTANCEOF:Token = new Token(0xA4);

        public static const YIELD:Token = new Token(0xA5);

        public static const AWAIT:Token = new Token(0xA6);


        public static const ASSIGN:Token = new Token(0x100);

        public static const ADD_ASSIGN:Token = new Token(0x101);

        public static const SUBTRACT_ASSIGN:Token = new Token(0x102);

        public static const MULTIPLY_ASSIGN:Token = new Token(0x103);

        public static const DIVIDE_ASSIGN:Token = new Token(0x104);

        public static const REMAINDER_ASSIGN:Token = new Token(0x105);

        public static const BIT_AND_ASSIGN:Token = new Token(0x106);

        public static const BIT_XOR_ASSIGN:Token = new Token(0x107);

        public static const BIT_OR_ASSIGN:Token = new Token(0x108);

        public static const LOGICAL_AND_ASSIGN:Token = new Token(0x109);

        public static const LOGICAL_XOR_ASSIGN:Token = new Token(0x10A);

        public static const LOGICAL_OR_ASSIGN:Token = new Token(0x10B);

        public static const LSHIFT_ASSIGN:Token = new Token(0x10C);

        public static const RSHIFT_ASSIGN:Token = new Token(0x10D);

        public static const UNSIGNED_RSHIFT_ASSIGN:Token = new Token(0x10E);


        private var _value:uint;

        /**
         * @private
         */
        public function Token(value:uint) {
            _value = value;
        }

        public function get isDefaultToken():Boolean { return !(_value >> 6) }

        public function get isPunctuator():Boolean { return !!(_value >> 6) }

        public function get isKeyword():Boolean { return !!(_value >> 7) }

        public function get isAssignment():Boolean { return !!(_value >> 8) }

        public function getCompoundAssignmentOperator():Operator {
            if (this == ADD_ASSIGN) return Operator.ADD;

            if (this == SUBTRACT_ASSIGN) return Operator.SUBTRACT;

            if (this == MULTIPLY_ASSIGN) return Operator.MULTIPLY;

            if (this == DIVIDE_ASSIGN) return Operator.DIVIDE;

            if (this == REMAINDER_ASSIGN) return Operator.REMAINDER;

            if (this == BIT_AND_ASSIGN) return Operator.BITWISE_AND;

            if (this == BIT_XOR_ASSIGN) return Operator.BITWISE_XOR;

            if (this == BIT_OR_ASSIGN) return Operator.BITWISE_OR;

            if (this == LSHIFT_ASSIGN) return Operator.LEFT_SHIFT;

            if (this == RSHIFT_ASSIGN) return Operator.RIGHT_SHIFT;

            if (this == UNSIGNED_RSHIFT_ASSIGN) return Operator.UNSIGNED_RIGHT_SHIFT;

            if (this == LOGICAL_AND_ASSIGN) return Operator.LOGICAL_AND;

            if (this == LOGICAL_XOR_ASSIGN) return Operator.LOGICAL_XOR;

            if (this == LOGICAL_OR_ASSIGN) return Operator.LOGICAL_OR;

            return null;
        }

        public function valueOf():uint { return _value }

        public function toString():String {

            if (isDefaultToken)

            switch (this) {

            case EOF: return 'end of program';

            case IDENTIFIER: return 'identifier';

            case STRING_LITERAL: return 'string literal';

            case BOOLEAN_LITERAL: return 'boolean literal';

            case NUMERIC_LITERAL: return 'numeric literal';

            case NULL_LITERAL: return 'null literal';

            case THIS_LITERAL: return 'this literal';

            case REG_EXP_LITERAL: return 'regular expression';

            case XML_WHITESPACE: return 'whitespace';

            case XML_ATTRIBUTE_VALUE: return 'attribute value';

            case XML_MARKUP: return 'markup';

            case XML_TEXT: return 'text';

            case XML_NAME: return 'name';

            case XML_LT_SLASH: return '</';

            case XML_SLASH_GT: return '/>';

            }

            if (isPunctuator)

            switch (this) {

            case DOT: return 'dot';

            case DESCENDANTS: return '..';

            case ELLIPSIS: return '...';

            case COMMA: return 'comma';

            case SEMICOLON: return 'semicolon';

            case COLON: return 'colon';

            case COLON_COLON: return '::';

            case LPAREN: return '(';

            case RPAREN: return ')';

            case LBRACKET: return '[';

            case RBRACKET: return ']';

            case LBRACE: return '{';

            case RBRACE: return '}';

            case ATTRIBUTE: return '@';

            case QUESTION_MARK: return '?';

            case EXCLAMATION_MARK: return '!';

            case INCREMENT: return '++';

            case DECREMENT: return '--';

            case PLUS: return '+';

            case MINUS: return '-';

            case TIMES: return '*';

            case SLASH: return '/';

            case REMAINDER: return '%';

            case BIT_AND: return '&';

            case BIT_XOR: return '^';

            case BIT_OR: return '|';

            case BIT_NOT: return '~';

            case LEFT_SHIFT: return '<<';

            case RIGHT_SHIFT: return '>>';

            case UNSIGNED_RIGHT_SHIFT: return '>>>';

            case LT: return '<';

            case GT: return '>';

            case LE: return '<=';

            case GE: return '>=';

            case EQUALS: return '==';

            case NOT_EQUALS: return '!=';

            case STRICT_EQUALS: return '===';

            case STRICT_NOT_EQUALS: return '!==';

            case LOGICAL_AND: return '&&';

            case LOGICAL_OR: return '||';

            }

            if (isKeyword)

            switch (this) {

            case AS: return 'as';

            case DO: return 'do';

            case IF: return 'if';

            case IN: return 'in';

            case IS: return 'is';

            case FOR: return 'for';

            case NEW: return 'new';

            case TRY: return 'try';

            case USE: return 'use';

            case VAR: return 'var';

            case CASE: return 'case';

            case ELSE: return 'else';

            case VOID: return 'void';

            case WITH: return 'with';

            case BREAK: return 'break';

            case CATCH: return 'catch';

            case CLASS: return 'class';

            case CONST: return 'const';

            case SUPER: return 'super';

            case THROW: return 'throw';

            case WHILE: return 'while';

            case DELETE: return 'delete';

            case IMPORT: return 'import';

            case PUBLIC: return 'public';

            case RETURN: return 'return';

            case SWITCH: return 'switch';

            case TYPEOF: return 'typeof';

            case DEFAULT: return 'default';

            case FINALLY: return 'finally';

            case PACKAGE: return 'package';

            case PRIVATE: return 'private';

            case CONTINUE: return 'continue';

            case FUNCTION: return 'function';

            case INTERNAL: return 'internal';

            case INTERFACE: return 'interface';

            case PROTECTED: return 'protected';

            case INSTANCEOF: return 'instanceof';

            case YIELD: return 'yield';

            case AWAIT: return 'await';

            }

            if (isAssignment) {

            switch (this) {

            case ASSIGN: return '=';

            case ADD_ASSIGN: return '+=';

            case SUBTRACT_ASSIGN: return '-=';

            case MULTIPLY_ASSIGN: return '*=';

            case DIVIDE_ASSIGN: return '/=';

            case REMAINDER_ASSIGN: return '%=';

            case BIT_AND_ASSIGN: return '&=';

            case BIT_XOR_ASSIGN: return '^=';

            case BIT_OR_ASSIGN: return '|=';

            case LSHIFT_ASSIGN: return '<<=';

            case RSHIFT_ASSIGN: return '>>=';

            case UNSIGNED_RSHIFT_ASSIGN: return '>>>=';

            case LOGICAL_AND_ASSIGN: return '&&=';

            case LOGICAL_XOR_ASSIGN: return '^^=';

            case LOGICAL_OR_ASSIGN: return '||=';

            }

            }

            return '';
        }
    }
}