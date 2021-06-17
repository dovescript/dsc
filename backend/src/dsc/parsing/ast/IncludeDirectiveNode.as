package dsc.parsing.ast {

    import dsc.*;

    import dsc.semantics.*;

    public final class IncludeDirectiveNode extends DirectiveNode {

        public var src:String;

        public var subscript:Script;

        public var subpackages:Array;

        public var subdirectives:Array;

        public function IncludeDirectiveNode(src:String) {
            super();
            this.src = src;
        }
    }
}