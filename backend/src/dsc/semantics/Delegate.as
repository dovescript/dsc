package dsc.semantics {
    import dsc.semantics.values.*;
    import flash.utils.Dictionary;

    public final class Delegate extends ObjectValue {
        private var _inheritsDelegate:Delegate;
        private var _propertyProxy:PropertyProxy;
        private var _attributeProxy:PropertyProxy;
        private var _operators:Dictionary;

        /**
         * @private
         */
        public function Delegate(definedIn:Symbol) {
            super();
            this.definedIn = definedIn;
        }

        override public function get inheritsDelegate():Delegate {
            return _inheritsDelegate;
        }

        override public function set inheritsDelegate(value:Delegate):void {
            _inheritsDelegate = value;
        }

        override public function get propertyProxy():PropertyProxy {
            return _propertyProxy;
        }

        override public function set propertyProxy(proxy:PropertyProxy):void {
            _propertyProxy = proxy;
        }

        override public function get attributeProxy():PropertyProxy {
            return _attributeProxy;
        }

        override public function set attributeProxy(proxy:PropertyProxy):void {
            _attributeProxy = proxy;
        }

        override public function get operators():Dictionary {
            return _operators;
        }

        override public function set operators(value:Dictionary):void {
            _operators = value;
        }

        override public function get namesTree():NamesTree {
            return new NamesTree(this);
        }

        override public function resolveName(name:Symbol):Symbol {
            var r:Symbol = names.resolveName(name);
            return r || (inheritsDelegate ? inheritsDelegate.resolveName(name) : null);
        }

        override public function resolveMultiName(nss:NamespaceSet, name:String):Symbol {
            var r:Symbol = names.resolveMultiName(nss, name);
            return r || (inheritsDelegate ? inheritsDelegate.resolveMultiName(nss, name) : null);
        }

        override public function resolveNameAtReservedNamespace(nsType:String, name:String):Symbol {
            for each (var p:Property in names) {
                if (p.key.qualifier.namespaceType == nsType && p.key.localName == name)
                    return p.value;
                // internal is treated equivalently to public
                if (p.key.qualifier.namespaceType == 'internal' && nsType == 'public' && p.key.localName == name)
                    return p.value;
            }
            return inheritsDelegate ? inheritsDelegate.resolveNameAtReservedNamespace(nsType, localName) : null;
        }

        override public function findPropertyProxyInTree():PropertyProxy {
            return propertyProxy || (inheritsDelegate ? inheritsDelegate.findPropertyProxyInTree() : null);
        }

        override public function findAttributeProxyInTree():PropertyProxy {
            return attributeProxy || (inheritsDelegate ? inheritsDelegate.findAttributeProxyInTree() : null);
        }

        override public function findOperatorInTree(operator:Operator):Symbol {
            var r:Symbol = operators ? operators[operator] : null;
            return r || (inheritsDelegate ? inheritsDelegate.findOperatorInTree(operator) : null);
        }

        override public function toString():String {
            return '[object Delegate]';
        }
    }
}