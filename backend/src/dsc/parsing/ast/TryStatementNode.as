package dsc.parsing.ast {

    import dsc.semantics.*;

    public final class TryStatementNode extends StatementNode {

        public var mainElement:BlockNode;

        public var catchElements:Array;

        public var finallyElement:BlockNode;

        public function TryStatementNode(mainElement:BlockNode, catchElements:Array, finallyElement:BlockNode) {
            super();
            this.mainElement = mainElement;
            this.catchElements = catchElements;
            this.finallyElement = finallyElement;
        }
    }
}