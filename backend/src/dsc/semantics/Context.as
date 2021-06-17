package dsc.semantics {
    public final class Context {
        public const statics:ContextStatics = new ContextStatics;

        private var _factory:SymbolFactory;

        public function Context() {
            _factory = new SymbolFactory(this);
            statics._init(this);
        }

        public function get factory():SymbolFactory {
            return _factory;
        }

        public function isNameType(type:Symbol):Boolean {
            return statics.nameTypes.indexOf(type) != -1;
        }

        public function isNumericType(type:Symbol):Boolean {
            return statics.numericTypes.indexOf(type) != -1;
        }

        public function isIntegerType(type:Symbol):Boolean {
            return statics.integerTypes.indexOf(type) != -1;
        }

        public function isArrayType(type:Symbol):Boolean {
            return type == statics.arrayType;
        }

        public function validateHasPropertyProxy(method:Symbol):Symbol {
            if (!(method && method is MethodSlot))
                return null;
            var s:MethodSignature = method.methodSignature;
            if (!s._params || s._params.length != 1 || s._optParams || s.hasRest || s.result != statics.booleanType)
                return null;
            return method;
        }

        public function validateGetDescendantsProxy(method:Symbol):Symbol {
            if (!(method && method is MethodSlot))
                return null;
            var s:MethodSignature = method.methodSignature;
            if (!s._params || s._params.length != 1 || s._optParams || s.hasRest || !isNameType(s._params[0]))
                return null;
            return method;
        }

        public function validateNextNameIndexProxy(method:Symbol):Symbol {
            if (!(method && method is MethodSlot))
                return null;
            var s:MethodSignature = method.methodSignature;
            if (!s._params || s._params.length != 1 || s._optParams || s.hasRest || !isNumericType(s._params[0]) || s.result != s._params[0])
                return null;
            return method;
        }

        public function validateNextNameOrValueProxy(method:Symbol):Symbol {
            if (!(method && method is MethodSlot))
                return null;
            var s:MethodSignature = method.methodSignature;
            if (!s._params || s._params.length != 1 || s._optParams || s.hasRest || !isNumericType(s._params[0]))
                return null;
            return method;
        }

        public function allMethodSignatures():Array {
            return statics.allMethodSignatures();
        }
    }
}