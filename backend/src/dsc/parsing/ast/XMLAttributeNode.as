package dsc.parsing.ast {
    import dsc.semantics.*;

    public final class XMLAttributeNode extends XMLNode {
        public var name:String;

        public var value:Object;

        public function XMLAttributeNode(name:String, value:Object) {
            super();
            this.name = name;
            this.value = value;
        }
    }
}