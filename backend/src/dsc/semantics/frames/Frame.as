package dsc.semantics.frames {
    import dsc.semantics.*;
    import dsc.semantics.accessErrors.*;
    import dsc.semantics.constants.*;
    import dsc.semantics.types.*;
    import dsc.semantics.values.*;

    public class Frame extends ObjectValue {
        private var _internalNs:Symbol;
        private var _defaultNamespace:Symbol;
        private var _importsPackages:Array;

        /**
         * @private
         */
        public var _openNamespaceList:NamespaceSet;

        /**
         * @private
         */
        public var _parentFrame:Symbol;

        override public function get parentFrame():Symbol {
            return _parentFrame;
        }

        override public function get activation():Symbol {
            for (var f:Symbol = this; f; f = f.parentFrame)
                if (f is Activation)
                    return f;
            return null;
        }

        override public function get internalNs():Symbol {
            return _internalNs;
        }

        override public function set internalNs(value:Symbol):void {
            _internalNs = value;
        }

        override public function get openNamespaceList():NamespaceSet {
            return _openNamespaceList;
        }

        override public function get defaultNamespace():Symbol {
            return _defaultNamespace;
        }

        override public function set defaultNamespace(symbol:Symbol):void {
            _defaultNamespace = symbol;
        }

        override public function get importsPackages():Array {
            return _importsPackages;
        }

        override public function importPackage(symbol:Symbol, openPublic:Boolean = true):void {
            if (this.symbol == symbol)
                return;
            _importsPackages ||= [];
            if (_importsPackages.indexOf(symbol) == -1)
                _importsPackages.push(symbol);
            if (openPublic)
                _openNamespaceList.addItem(symbol.publicNs);
        }

        override public function getLexicalReservedNamespace(type:String):Symbol {
            var f:Symbol;
            switch (type) {
                case 'public':
                    for (f = this; f; f = f.parentFrame)
                        if (f is PackageFrame)
                            return f.symbol.publicNs;
                    break;
                case 'private':
                    for (f = this; f; f = f.parentFrame)
                        if (f is ClassFrame || f is EnumFrame)
                            return f.symbol.privateNs;
                    break;
                case 'protected':
                    for (f = this; f; f = f.parentFrame)
                        if (f is ClassFrame)
                            return f.symbol.protectedNs;
                    break;
                case 'internal':
                    for (f = this; f; f = f.parentFrame)
                        if (f.internalNs)
                            return f.internalNs;
                    break;
            }
            return null;
        }

        override public function resolveName(name:Symbol):Symbol {
            var s:Symbol;
            var typeOrPackage:Symbol = this.symbol;
            if (typeOrPackage)
                for (typeOrPackage = typeOrPackage; typeOrPackage; typeOrPackage = typeOrPackage.superType)
                    if (s = typeOrPackage.resolveName(name))
                        return s;
            s = names.resolveName(name);
            if (s)
                return ownerContext.factory.referenceValue(this, s);
            if (this._importsPackages) {
                for each (var p:Symbol in this._importsPackages)
                    if (s = p.resolveName(name))
                        return s;
            }
            return parentFrame ? parentFrame.resolveName(name) : null;
        }

        override public function resolveMultiName(nss:NamespaceSet, name:String):Symbol {
            var s1:Symbol,
                s2:Symbol,
                typeOrPackage:Symbol = this.symbol;
            if (typeOrPackage) {
                for (typeOrPackage = typeOrPackage; typeOrPackage; typeOrPackage = typeOrPackage.superType) {
                    if (s2 = typeOrPackage.resolveMultiName(nss, name)) {
                        if (s1)
                            return ownerContext.factory.ambiguousReference(name);
                        else s1 = s2;
                    }
                }
            }
            s2 = names.resolveMultiName(nss, name);
            if (s2) {
                if (s1)
                    return ownerContext.factory.ambiguousReference(name);
                else s1 = ownerContext.factory.referenceValue(this, s2);
            }
            if (_importsPackages) {
                for each (var p:Symbol in _importsPackages) {
                    if (s2 = p.resolveMultiName(nss, name)) {
                        if (s1)
                            return ownerContext.factory.ambiguousReference(name);
                        else s1 = s2;
                    }
                }
            }
            return s1 || (parentFrame ? parentFrame.resolveMultiName(nss, name) : null);
        }

        override public function toString():String {
            return '[object Frame]';
        }
    }
}