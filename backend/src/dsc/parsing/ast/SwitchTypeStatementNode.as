package dsc.parsing.ast {

    import dsc.semantics.*;

    public final class SwitchTypeStatementNode extends StatementNode {

        public var discriminant:ExpressionNode;

        public var caseNodes:Array;

        public function SwitchTypeStatementNode(discriminant:ExpressionNode, caseNodes:Array) {
            super();
            this.discriminant = discriminant;
            this.caseNodes = caseNodes;
        }
    }
}