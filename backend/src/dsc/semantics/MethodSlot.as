package dsc.semantics {
    import dsc.semantics.constants.*;

    import flash.utils.Dictionary;

    public final class MethodSlot extends Slot {
        private var _name:Symbol;
        private var _signature:MethodSignature;
        private var _type:Symbol;
        private var _flags:uint;
        private var _activation:Symbol;
        private var _definedIn:Symbol;
        private var _ofVirtualSlot:Symbol;
        private var _overriders:Dictionary;
        private var _optimizations:Array;
        private var _foreignName:String;

        /**
         * @private
         */
        public function MethodSlot(name:Symbol, signature:MethodSignature, type:Symbol) {
            this._name = name;
            this._signature = signature;
            this._type = type;
        }

        override public function get name():Symbol {
            return _name;
        }

        override public function get methodSignature():MethodSignature {
            return _signature;
        }

        override public function set methodSignature(signature:MethodSignature):void {
            _signature = signature;
        }

        override public function get methodFlags():uint {
            return _flags;
        }

        override public function set methodFlags(flags:uint):void {
            _flags = flags;
        }

        override public function get readOnly():Boolean {
            return true;
        }

        override public function get writeOnly():Boolean {
            return false;
        }

        override public function get valueType():Symbol {
            return _type;
        }

        override public function get activation():Symbol {
            return _activation;
        }

        override public function set activation(activation:Symbol):void {
            _activation = activation;
        }

        override public function get definedIn():Symbol {
            return _definedIn;
        }

        override public function set definedIn(object:Symbol):void {
            _definedIn = object;
        }

        override public function get ofVirtualSlot():Symbol {
            return _ofVirtualSlot;
        }

        override public function set ofVirtualSlot(slot:Symbol):void {
            _ofVirtualSlot = slot;
        }

        override public function get methodOptimizations():Array {
            return _optimizations;
        }

        override public function set methodOptimizations(list:Array):void {
            _optimizations = list;
        }

        /**
         * Mappings of type to method, indicating methods that override this method.
         */
        override public function get overriders():Dictionary {
            return _overriders;
        }

        override public function get foreignName():String {
            return _foreignName;
        }

        override public function set foreignName(name:String):void {
            _foreignName = name;
        }

        override public function override(delegate:Symbol):Symbol {
            var name:Symbol = this.name;

            var superFunction:Symbol,
                virtualSlot:Symbol = ofVirtualSlot,
                superProperty:Symbol,
                superMethodSlot:Symbol;

            if (name.qualifier is ExplicitNamespaceConstant)
                superProperty = delegate.inheritsDelegate ? delegate.inheritsDelegate.resolveName(name) : undefined;
            else if (name.qualifier.namespaceType != 'private')
                // find overriding method in one of { public, protected, internal } namespaces
                superProperty = delegate.inheritsDelegate ? (delegate.inheritsDelegate.resolveNameAtReservedNamespace('public', name.localName) || delegate.inheritsDelegate.resolveNameAtReservedNamespace('protected', name.localName) || delegate.inheritsDelegate.resolveNameAtReservedNamespace('internal', name.localName)) : undefined;

            if (superProperty && virtualSlot)
                superProperty = superProperty is VirtualSlot ? superProperty : undefined;
            else if (superProperty)
                superProperty = superProperty is MethodSlot ? superProperty : undefined;

            if (virtualSlot) {
                var isGetter:Boolean = this == virtualSlot.getter;
                if (!superProperty || (isGetter ? !superProperty.getter : !superProperty.setter))
                    return ownerContext.factory.mustOverrideAMethod();
                superMethodSlot = isGetter ? superProperty.getter : superProperty.setter;
                if (superProperty.valueType != virtualSlot.valueType)
                    return ownerContext.factory.incompatibleOverrideSignature(superMethodSlot.methodSignature);
                if (superMethodSlot.methodFlags & MethodFlags.FINAL)
                    return ownerContext.factory.overridingFinal();
            }
            else {
                if (!superProperty)
                    return ownerContext.factory.mustOverrideAMethod();
                if (!superProperty.methodSignature.overridableBy(methodSignature))
                    return ownerContext.factory.incompatibleOverrideSignature(superProperty.methodSignature);
                superMethodSlot = superProperty;
                if (superMethodSlot.methodFlags & MethodFlags.FINAL)
                    return ownerContext.factory.overridingFinal();
            }

            MethodSlot(superMethodSlot)._overriders ||= new Dictionary;
            MethodSlot(superMethodSlot)._overriders[delegate.definedIn] = this;
            methodFlags |= MethodFlags.OVERRIDE;

            return undefined;
        }

        override public function toString():String {
            return '[object MethodSlot]';
        }
    }
}