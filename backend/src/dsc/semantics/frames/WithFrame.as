package dsc.semantics.frames {
    import dsc.semantics.*;
    import dsc.semantics.constants.*;
    import dsc.semantics.types.*;
    import dsc.semantics.values.*;

    public final class WithFrame extends Frame {
        /**
         * @private
         */
        public var _symbol:Symbol;

        /**
         * @private
         */
        public function WithFrame() {}

        override public function get symbol():Symbol {
            return _symbol;
        }

        override public function resolveName(name:Symbol):Symbol {
            var s:Symbol = names.resolveName(name);
            if (s)
                return ownerContext.factory.referenceValue(this, s);
            s = symbol.resolveName(name);
            if (s && !(s is DynamicReferenceValue || s is PropertyProxyReferenceValue))
                return s;
            return parentFrame ? parentFrame.resolveName(name) : null;
        }

        override public function resolveMultiName(nss:NamespaceSet, name:String):Symbol {
            var s:Symbol = names.resolveMultiName(nss, name);
            if (s)
                return ownerContext.factory.referenceValue(this, s);
            s = symbol.resolveMultiName(nss, name);
            if (s && !(s is DynamicReferenceValue || s is PropertyProxyReferenceValue))
                return s;
            return parentFrame ? parentFrame.resolveMultiName(nss, name) : null;
        }

        override public function toString():String {
            return '[object WithFrame]';
        }
    }
}