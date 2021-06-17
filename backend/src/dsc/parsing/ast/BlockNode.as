package dsc.parsing.ast {

    import dsc.semantics.*;

    public final class BlockNode extends StatementNode {

        public var directives:Array;

        public function BlockNode(directives:Array) {
            super();
            this.directives = directives;
        }
    }
}