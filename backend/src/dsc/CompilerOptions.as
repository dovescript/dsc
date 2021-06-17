package dsc {
    public final class CompilerOptions {
        private static const _supportedWarnings:* = {
            noTypeDeclaration: true
        };

        public var defaultNullability:Boolean;
        public var allowDuplicates:Boolean;
        public var warnings:* = {};
        public var foreign:* = {};

        public static function supportsWarning(name:String):Boolean {
            return !!_supportedWarnings[name];
        }

        public function CompilerOptions(options:* = undefined) {
            options ||= {};
            this.defaultNullability = !!options.defaultNullability;
            this.allowDuplicates = !!options.allowDuplicates;
            this.warnings = options.warnings || {};
            this.foreign = options.foreign || {};

            var name:String;

            for (name in _supportedWarnings)
                this.warnings[name] = _supportedWarnings[name];
            for (name in options.warnings)
                this.warnings[name] = options.warnings[name];
            for (name in this.warnings)
                if (!supportsWarning(name))
                    throw new ArgumentError('Unsupported warning: ' + name);
        }
    }
}