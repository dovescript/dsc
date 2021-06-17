package dsc.parsing.ast {

    import dsc.semantics.*;

    public final class BreakNode extends StatementNode {

        public var label:String;

        public var targetStatement:Node = null;

        public function BreakNode(label:String) {
            super();
            this.label = label;
        }
    }
}