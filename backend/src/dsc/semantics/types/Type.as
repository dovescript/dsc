package dsc.semantics.types {
    import dsc.semantics.*;
    import dsc.semantics.constants.*;
    import dsc.semantics.frames.*;
    import dsc.semantics.values.*;

    public class Type extends ObjectValue {
        private var _delegate:Delegate;

        override public function get delegate():Delegate {
            return _delegate;
        }
        
        override public function set delegate(delegate:Delegate):void {
            _delegate = delegate;
        }

        override public function get superType():Symbol {
            return delegate && delegate.inheritsDelegate ? delegate.inheritsDelegate.definedIn : null;
        }

        override public function isSubtypeOf(type:Symbol):Boolean {
            if (this == type)
                return true;
            var superType:Symbol = this.superType;
            if (superType && (superType == type || superType.isSubtypeOf(type)))
                return true;
            var itrfcs:Array = this.implementsInterfaces;
            var itrfc:Symbol;
            if (itrfcs && type is InterfaceType)
                for each (itrfc in itrfcs)
                    if (itrfc == type || itrfc.isSubtypeOf(type))
                        return true;
            var superItrfcs:Array = this.superInterfaces;
            if (superItrfcs)
                for each (itrfc in superItrfcs)
                    if (itrfc == type || itrfc.isSubtypeOf(type))
                        return true;
            return false;
        }

        override public function resolveName(name:Symbol):Symbol {
            var r:Symbol = this.names.resolveName(name);
            if (r) return ownerContext.factory.referenceValue(this, r);
            r = superType ? superType.resolveName(name) : null;
            return r is SuperClassStaticReferenceValue ? ownerContext.factory.superClassStaticReferenceValue(this, r.superType, r.property) : r ? ownerContext.factory.superClassStaticReferenceValue(this, superType, r.property) : null;
        }

        override public function resolveMultiName(nss:NamespaceSet, name:String):Symbol {
            var r:Symbol = this.names.resolveMultiName(nss, name);
            if (r) return ownerContext.factory.referenceValue(this, r);
            r = superType ? superType.resolveMultiName(nss, name) : null;
            return r is SuperClassStaticReferenceValue ? ownerContext.factory.superClassStaticReferenceValue(this, r.superType, r.property) : r ? ownerContext.factory.superClassStaticReferenceValue(this, superType, r.property) : null;
        }
    }
}