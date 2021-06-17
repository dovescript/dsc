package dsc.docGenerator.tags {
    import dsc.semantics.*;

    public final class CopyTag extends Tag {
        public var item:Symbol;

        public function CopyTag(item:Symbol) {
            this.item = item;
        }
    }
}