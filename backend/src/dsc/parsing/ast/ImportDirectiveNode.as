package dsc.parsing.ast {

    import dsc.*;

    import dsc.semantics.*;

    public final class ImportDirectiveNode extends DirectiveNode {

        public var alias:String;

        public var aliasSpan:Span;

        public var importName:String;

        public var importNameSpan:Span;

        public var wildcard:Boolean;

        public function ImportDirectiveNode(alias:String, importName:String, wildcard:Boolean) {
            super();
            this.alias = alias;
            this.importName = importName;
            this.wildcard = wildcard;
        }
    }
}