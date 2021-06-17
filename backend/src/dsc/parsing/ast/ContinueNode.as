package dsc.parsing.ast {

    import dsc.semantics.*;

    public final class ContinueNode extends StatementNode {

        public var label:String;

        public var targetStatement:Node;

        public function ContinueNode(label:String) {
            super();
            this.label = label;
        }
    }
}