package dsc.docGenerator.tags {
    import dsc.semantics.Symbol;

    public final class ThrowsTag extends Tag {
        public var type:Symbol;
        public var description:String;

        public function ThrowsTag(type:Symbol, description:String) {
            this.type = type;
            this.description = description;
        }
    }
}