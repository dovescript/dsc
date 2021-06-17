package dsc.parsing.ast {

    import dsc.*;

    import dsc.semantics.*;

    public final class ProgramNode extends Node {

        public var packages:Array;

        public var directives:Array;

        public var script:Script;

        public function ProgramNode(packages:Array, directives:Array) {
            super();
            this.packages = packages;
            this.directives = directives;
        }
    }
}