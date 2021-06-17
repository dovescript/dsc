package dsc.parsing.ast {

    import dsc.semantics.*;

    public final class SuperStatementNode extends StatementNode {

        public var arguments:Array;

        public function SuperStatementNode(arguments:Array) {
            super();
            this.arguments = arguments;
        }
    }
}