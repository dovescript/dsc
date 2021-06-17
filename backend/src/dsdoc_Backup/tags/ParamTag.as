package dsc.docGenerator.tags {
    public final class ParamTag extends Tag {
        public var name:String;
        public var description:String;

        public function ParamTag(name:String, description:String) {
            this.name = name;
             this.description = description;
        }
    }
}