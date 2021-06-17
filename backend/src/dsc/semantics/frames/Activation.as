package dsc.semantics.frames {

    import dsc.semantics.*;

    import dsc.semantics.constants.*;

    import dsc.semantics.types.*;

    import dsc.semantics.values.*;

    import flash.utils.Dictionary;

    public final class Activation extends Frame {
        private var _thisValue:Symbol;

        private var _scopeExtendedProperties:Dictionary;

        /**
         * @private
         */
        public function Activation(thisValue:Symbol) {
            _thisValue = thisValue;
        }

        override public function get thisValue():Symbol {
            return _thisValue;
        }

        override public function resolveName(name:Symbol):Symbol {
            var s:Symbol = names.resolveName(name);
            if (s)
                return ownerContext.factory.referenceValue(this, s);
            s = thisValue.resolveName(name);
            if (s && !(s is DynamicReferenceValue || s is PropertyProxyReferenceValue))
                return s;
            if (s = super.resolveName(name))
                return s;
            return parentFrame ? parentFrame.resolveName(name) : null;
        }

        override public function resolveMultiName(nss:NamespaceSet, name:String):Symbol {
            var s:Symbol = names.resolveMultiName(nss, name);
            if (s)
                return ownerContext.factory.referenceValue(this, s);
            s = thisValue.resolveMultiName(nss, name);
            if (s && !(s is DynamicReferenceValue || s is PropertyProxyReferenceValue))
                return s;
            if (s = super.resolveMultiName(nss, name))
                return s;
            return parentFrame ? parentFrame.resolveMultiName(nss, name) : null;
        }

        override public function setScopeExtendedProperty(property:Symbol):void { _scopeExtendedProperties ||= new Dictionary, _scopeExtendedProperties[property] = true }

        override public function hasScopeExtendedProperty(property:Symbol):Boolean { return _scopeExtendedProperties ? !!_scopeExtendedProperties[property] : false }

        override public function toString():String {
            return '[object Activation]';
        }
    }
}