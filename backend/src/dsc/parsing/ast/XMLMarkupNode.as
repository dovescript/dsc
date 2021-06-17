package dsc.parsing.ast {

    import dsc.semantics.*;

    public final class XMLMarkupNode extends XMLNode {

        public var content:String;

        public function XMLMarkupNode(content:String) {
            super();
            this.content = content;
        }
    }
}