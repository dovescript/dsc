package dsc.parsing {
    import flash.utils.ByteArray;
    import dsc.*;
    import dsc.parsing.ast.*;
    import com.siteblade.util.CharArray;

    public final class Parser {
        private var _work:ParserWork;
        private var _lexer:Lexer;

        public function Parser(argument:*) {
            var script:Script;
            if (argument is String || argument is ByteArray) script = new Script('file:///Anonymous.ds', new CharArray(argument));
            else if (argument is Lexer) script = argument.script, _lexer = argument;
            else script = Script(argument);

            _lexer ||= new Lexer(script);
            try { _lexer.shift() } catch (p:Problem) {}
            _work = new ParserWork(_lexer);
        }

        public function get lexer():Lexer { return _lexer }

        public function get script():Script { return _lexer.script }

        public function parseProgram():ProgramNode {
            _work.clear();
            var program:ProgramNode;

            try { program = _work.parseProgram() } catch (p:Problem) {}

            return script.isValid ? program : undefined;
        }

        public function parseExpression(allowIn:Boolean, minPrecedence:OperatorPrecedence):ExpressionNode {
            _work.clear();
            var expression:ExpressionNode;

            try { expression = _work.parseExpression(allowIn, minPrecedence) } catch (p:Problem) {}

            return script.isValid ? expression : undefined;
        }

        public function parseNonAssignmentExpression(allowIn:Boolean):ExpressionNode {
            _work.clear();
            var expression:ExpressionNode;

            try { expression = _work.parseNonAssignmentExpression(allowIn) } catch (p:Problem) {}

            return script.isValid ? expression : undefined;
        }

        public function parseTypeExpression():ExpressionNode {
            _work.clear();
            var expression:ExpressionNode;

            try { expression = _work.parseTypeExpression() } catch (p:Problem) {}

            return script.isValid ? expression : undefined;
        }

        public function parseTypeExpressionList():ExpressionNode {
            _work.clear();
            var expression:ExpressionNode;

            try { expression = _work.parseTypeExpressionList() } catch (p:Problem) {}

            return script.isValid ? expression : undefined;
        }
    }
}