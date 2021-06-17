package dsc.targets.js.sourcemap {
    import flash.filesystem.File;

    public final class SourceMapGenerator {
        private var _file:String = null;
        private var _sourceRoot:String = null;
        private var _skipValidation:Boolean = false;
        private var _sources:ArraySet = new ArraySet;
        private var _names:ArraySet = new ArraySet;
        private var _mappings:MappingList = new MappingList;
        private var _sourcesContent:* = null;

        public function SourceMapGenerator(aArgs:* = undefined) {
            aArgs ||= {};
            _file = Util.getArg(aArgs, 'file', null);
            _sourceRoot = Util.getArg(aArgs, 'file', null);
            _skipValidation = Util.getArg(aArgs, 'skipValidation', false);
        }

        public function addMapping(aArgs:*):void {
            const generated:* = Util.getArg(aArgs, 'generated');
            const original:* = Util.getArg(aArgs, 'original', null);
            var source:String = Util.getArg(aArgs, 'source', null);
            var name:String = Util.getArg(aArgs, 'name', null);

            if (!this._skipValidation)
                this._validateMapping(generated, original, source, name);

            if (source != null && !this._sources.has(source))
                this._sources.add(source);

            if (name != null && !this._names.has(name))
                this._names.add(name);

            this._mappings.add({
                generatedLine: generated.line,
                generatedColumn: generated.column,
                originalLine: original && original.line,
                originalColumn: original && original.column,
                source: source,
                name: name,
            });
        }

        public function setSourceContent(aSourceFile:String, sourceContent:String):void {
            ...
        }
    }
}