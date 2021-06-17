package dsc.parsing.ast {

    import dsc.semantics.*;

    public final class NamespaceDefinitionNode extends DefinitionNode {

        public var name:String;

        public var expression:ExpressionNode;

        public function NamespaceDefinitionNode(name:String, expression:ExpressionNode) {
            super();
            this.name = name;
            this.expression = expression;
        }
    }
}