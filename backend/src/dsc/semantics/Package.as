package dsc.semantics {
    import dsc.semantics.constants.*;
    import dsc.semantics.values.*;

    public final class Package extends ObjectValue {
        private var _name:String;

        /**
         * @private
         */
        internal var _subpackages:Array;

        /**
         * @private
         */
        internal var _publicNs:Symbol;

        /**
         * @private
         */
        internal var _internalNs:Symbol;

		/**
		 * @private
		 */
        public function Package(name:String) {
        	super(null);
            _name = name;
        }

        override public function get fullyQualifiedName():String {
            return _name;
        }

        override public function get publicNs():Symbol {
            return _publicNs;
        }

        override public function get internalNs():Symbol {
            return _internalNs;
        }

        override public function addSubpackage(subpackage:Symbol):void {
            _subpackages ||= [];
            _subpackages.push(subpackage);
        }

        override public function findSubpackage(id:String):Symbol {
            if (!_subpackages)
                return null;
            for each (var p1:Package in _subpackages) {
                if (p1._name == id)
                    return p1;
                var p2:Symbol = p1.findSubpackage(id);
                if (p2) return p2;
            }
            return null;
        }

        override public function toRecursiveNamespaceSet(prefix:String = undefined):Symbol {
            var nss:Symbol = ownerContext.factory.namespaceSet(prefix);

            nss.addItem(this.publicNs), recurse(this);

            function recurse(p:Symbol):void {
                for each (var sP:Package in _subpackages) {
                    nss.addItem(sP.publicNs);

                    if (sP._subpackages) recurse(sP);
                }
            }

            return nss;
        }

        override public function resolveName(name:Symbol):Symbol {
            var r:Symbol = names.resolveName(name);
            return r ? ownerContext.factory.referenceValue(this, r) : null;
        }

        override public function resolveMultiName(nss:NamespaceSet, name:String):Symbol {
            var r:Symbol = names.resolveMultiName(nss, name);
            return r ? ownerContext.factory.referenceValue(this, r) : null;
        }

        override public function toString():String {
            return '[object Package]';
        }
    }
}