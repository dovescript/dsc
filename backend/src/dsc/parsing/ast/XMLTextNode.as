package dsc.parsing.ast {

    import dsc.semantics.*;

    public final class XMLTextNode extends XMLNode {

        public var content:Object;

        public function XMLTextNode(content:Object) {
            super();
            this.content = content;
        }
    }
}