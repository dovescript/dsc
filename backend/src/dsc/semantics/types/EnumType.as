package dsc.semantics.types {
    import dsc.semantics.*;
    import dsc.semantics.constants.*;
    import dsc.semantics.frames.*;
    import dsc.semantics.values.*;
    import dsc.util.AnyRangeNumber;

    public final class EnumType extends Type {
        private var _name:Symbol;
        private var _wrapsType:Symbol;
        private var _flags:uint;
        private const _constants:* = {};
        private const _specialMethods:EnumSpecialMethods = new EnumSpecialMethods;
        private var _foreignName:String;

        /**
         * @private
         */
        public var _privateNs:Symbol;

        /**
         * @private
         */
        public function EnumType(name:Symbol, wrapsType:Symbol, flags:uint) {
            _name = name;
            _wrapsType = wrapsType;
            _flags = flags;
        }

        override public function get enumSpecialMethods():EnumSpecialMethods {
            return _specialMethods;
        }

        override public function get name():Symbol {
            return _name;
        }

        override public function get wrapsType():Symbol {
            return _wrapsType;
        }

        override public function set wrapsType(type:Symbol):void { _wrapsType = type }

        override public function get enumFlags():uint {
            return _flags;
        }

        override public function get privateNs():Symbol {
            return _privateNs;
        }

        override public function getEnumConstant(name:String):Symbol {
            return _constants[name];
        }

        override public function setEnumConstant(name:String, value:AnyRangeNumber):void {
            _constants[name] = ownerContext.factory.enumConstant(value, this);
        }

        override public function get enumConstants():* {
            var r:* = {};
            for (var name:String in _constants)
                r[name] = _constants[name].valueOf();
            return r;
        }

        override public function get defaultValue():Symbol {
            return _flags & EnumFlags.FLAGS ? ownerContext.factory.enumConstant(new AnyRangeNumber(0), this) : null;
        }

        override public function get containsUndefined():Boolean {
            return false;
        }

        override public function get containsNull():Boolean {
            return false;
        }

        override public function get foreignName():String {
            return _foreignName;
        }

        override public function set foreignName(name:String):void {
            _foreignName = name;
        }

        override public function defineEnumSpecialMethods(lexicalPublicNs:Symbol):void {
            var ctx:Context = ownerContext;

            // E.valueOf()
            var valueOfMethod:Symbol = ctx.factory.methodSlot(ctx.factory.name(lexicalPublicNs, 'valueOf'), ctx.factory.methodSignature(null, null, false, this.wrapsType));
            valueOfMethod.methodFlags |= MethodFlags.NATIVE;
            this.delegate.names.defineName(valueOfMethod.name, valueOfMethod);
            _specialMethods.valueOfMethod = valueOfMethod;

            // E.defaultConversion()
            var dfConv:Symbol = ctx.factory.methodSlot(ctx.factory.name(lexicalPublicNs, 'defaultConversion'), ctx.factory.methodSignature([ctx.statics.anyType], null, false, this));
            dfConv.methodFlags |= MethodFlags.NATIVE;
            this.names.defineName(dfConv.name, dfConv);
            _specialMethods.defaultConversionMethod = dfConv;

            if (!(_flags & EnumFlags.FLAGS))
                return;

            // E.proxy::hasProperty()
            var hasProxy:Symbol = ctx.factory.methodSlot(ctx.statics.proxyHasProperty, ctx.factory.methodSignature([this], null, false, ctx.statics.booleanType));
            hasProxy.methodFlags |= MethodFlags.NATIVE;
            this.delegate.names.defineName(hasProxy.name, hasProxy);
            _specialMethods.hasProxy = hasProxy;

            var filterMethod:Symbol = ctx.factory.methodSlot(ctx.factory.name(lexicalPublicNs, 'filter'), ctx.factory.methodSignature([this], null, false, this));
            filterMethod.methodFlags |= MethodFlags.NATIVE;
            this.delegate.names.defineName(filterMethod.name, filterMethod);
            _specialMethods.filterMethod = filterMethod;

            var includeMethod:Symbol = ctx.factory.methodSlot(ctx.factory.name(lexicalPublicNs, 'include'), ctx.factory.methodSignature([this], null, false, this));
            includeMethod.methodFlags |= MethodFlags.NATIVE;
            this.delegate.names.defineName(includeMethod.name, includeMethod);
            _specialMethods.includeMethod = includeMethod;

            var excludeMethod:Symbol = ctx.factory.methodSlot(ctx.factory.name(lexicalPublicNs, 'exclude'), ctx.factory.methodSignature([this], null, false, this));
            excludeMethod.methodFlags |= MethodFlags.NATIVE;
            this.delegate.names.defineName(excludeMethod.name, excludeMethod);
            _specialMethods.excludeMethod = excludeMethod;

            var toggleMethod:Symbol = ctx.factory.methodSlot(ctx.factory.name(lexicalPublicNs, 'toggle'), ctx.factory.methodSignature([this], null, false, this));
            toggleMethod.methodFlags |= MethodFlags.NATIVE;
            this.delegate.names.defineName(toggleMethod.name, toggleMethod);
            _specialMethods.toggleMethod = toggleMethod;
        }

        override public function toString():String {
            return fullyQualifiedName;
        }
    }
}