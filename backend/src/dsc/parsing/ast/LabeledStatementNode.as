package dsc.parsing.ast {

    import dsc.semantics.*;

    public final class LabeledStatementNode extends StatementNode {

        public var label:String;

        public var substatement:StatementNode;

        public function LabeledStatementNode(label:String, substatement:StatementNode) {
            super();
            this.label = label;
            this.substatement = substatement;
        }
    }
}