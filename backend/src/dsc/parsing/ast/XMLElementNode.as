package dsc.parsing.ast {
    import dsc.semantics.*;

    public final class XMLElementNode extends XMLNode {
        public var openName:Object;

        public var closeName:Object;

        public var attributes:Array;

        public var childNodes:Array;

        public function XMLElementNode(openName:Object, closeName:Object, attributes:Array, childNodes:Array) {
            super();
            this.openName = openName;
            this.closeName = closeName;
            this.attributes = attributes;
            this.childNodes = childNodes;
        }
    }
}