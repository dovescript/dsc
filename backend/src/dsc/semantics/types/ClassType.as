package dsc.semantics.types {
    import dsc.semantics.*;
    import dsc.semantics.constants.*;
    import dsc.semantics.frames.*;
    import dsc.semantics.values.*;

    import com.hurlant.math.BigInteger;

    public final class ClassType extends Type {
        private var _name:Symbol;
        private var _flags:uint;
        private var _typeParams:Array;
        private var _constructorMethod:Symbol;
        private var _foreignName:String;

        /**
         * @private
         */
        public var _protectedNs:Symbol;

        /**
         * @private
         */
        public var _privateNs:Symbol;

        /**
         * @private
         */
        public var _interfaces:Array;

        /**
         * @private
         */
        public var _subclasses:Array;

        /**
         * @private
         */
        public function ClassType(name:Symbol, flags:uint) {
            _name = name;
            _flags = flags;
            if (_flags & ClassFlags.UNION) _flags |= ClassFlags.PRIMITIVE;
            if (_flags & ClassFlags.PRIMITIVE) _flags |= ClassFlags.FINAL;
        }

        override public function get name():Symbol {
            return _name;
        }

        override public function get classFlags():uint {
            return _flags;
        }

        override public function set classFlags(flags:uint):void {
            _flags = flags;
        }

        override public function get typeParams():Array {
            return _typeParams;
        }

        override public function set typeParams(array:Array):void {
            _typeParams = array;
        }

        /**
         * Equivalent to the type parameters.
         */
        override public function get arguments():Array {
            return _typeParams;
        }

        override public function get subclasses():Array {
            return _subclasses;
        }

        override public function get implementsInterfaces():Array {
            return _interfaces;
        }

        override public function get privateNs():Symbol {
            return _privateNs;
        }

        override public function get protectedNs():Symbol {
            return _protectedNs;
        }

        override public function get constructorMethod():Symbol {
            return _constructorMethod;
        }

        override public function set constructorMethod(method:Symbol):void {
            _constructorMethod = method;
        }

        override public function get foreignName():String {
            return _foreignName;
        }

        override public function set foreignName(name:String):void {
            _foreignName = name;
        }

        override public function get defaultValue():Symbol {
            var ctx:Context = ownerContext;

            switch (this) {
                case ctx.statics.booleanType: return ctx.factory.booleanConstant(false);
                case ctx.statics.numberType: return ctx.factory.numberConstant(0);
                case ctx.statics.bigIntType: return ctx.factory.bigIntConstant(new BigInteger(0));
                case ctx.statics.charType: return ctx.factory.charConstant(0);
                case ctx.statics.stringType: return ctx.factory.stringConstant('undefined');
            }
            return null;
        }

        override public function get containsUndefined():Boolean {
            return false;
        }

        override public function get containsNull():Boolean {
            return false;
        }

        override public function extendType(type:Symbol):Array {
            if (type.isSubtypeOf(this) || !(type is ClassType))
                return [];
            var superClass:Symbol = this.superType;
            if (superClass) {
                var list:Array = superClass.subclasses;
                var i:int = list ? list.indexOf(this) : -1;
                if (i != -1)
                    list.removeAt(i);
                delegate.inheritsDelegate = null;
            }
            delegate.inheritsDelegate = type.delegate;
            ClassType(type)._subclasses ||= [];
            ClassType(type)._subclasses.push(this);
            return [];
        }

        override public function implementType(type:Symbol):void {
            if (!(type is InterfaceType))
                return;
            this._interfaces ||= [];
            if (this._interfaces.indexOf(type) == -1)
                this._interfaces.push(type),
                InterfaceType(type)._implementors.push(this);
        }

        override public function verifyInterfaceImplementations(onundefined:Function, onwrong:Function):void {
            if (!_interfaces)
                return;
            for each (var itrfc:Symbol in _interfaces) {
                for each (var property:Property in itrfc.delegate.namesTree) {
                    var name:Symbol = property.key;
                    var provided:Symbol = property.value;
                    var impl:Symbol = name.qualifier is ExplicitNamespaceConstant
                        ? this.delegate.resolveName(name)
                        : this.delegate.resolveNameAtReservedNamespace('public', name.localName);
                    if (provided is VirtualSlot)
                        _verifyVirtualSlotImpl(name, provided, impl, onundefined, onwrong);
                    else _verifyMethodSlotImpl(name, provided, impl, onundefined, onwrong);
                }
            }
        }

        private function _verifyVirtualSlotImpl(name:Symbol, provided:Symbol, impl:Symbol, onundefined:Function, onwrong:Function):void {
            if (!impl) {
                if (provided.getter && (provided.getter.methodFlags & MethodFlags.NATIVE))
                    onundefined('getter', name, provided.getter.methodSignature);
                if (provided.setter && (provided.setter.methodFlags & MethodFlags.NATIVE))
                    onundefined('setter', name, provided.setter.methodSignature);
            }
            else if (impl is VirtualSlot) {
                // Report when getter is required and it is either undefined or incompatible
                if ((provided.getter && (provided.getter.methodFlags & MethodFlags.NATIVE) && !impl.getter)
                || (provided.getter && impl.getter && !provided.getter.methodSignature.equals(impl.getter.methodSignature)))
                    onundefined('getter', name, provided.getter.methodSignature);

                // Report when setter is required and it is either undefined or incompatible
                if ((provided.setter && (provided.setter.methodFlags & MethodFlags.NATIVE) && !impl.setter)
                || (provided.setter && impl.setter && !provided.setter.methodSignature.equals(impl.setter.methodSignature)))
                    onundefined('setter', name, provided.setter.methodSignature);
            }
            else onwrong('virtualProperty', name);
        }

        private function _verifyMethodSlotImpl(name:Symbol, provided:Symbol, impl:Symbol, onundefined:Function, onwrong:Function):void {
            if (!impl) {
                if (provided.methodFlags & MethodFlags.NATIVE)
                    onundefined('default', name, provided.methodSignature);
            }
            else if (!(impl is MethodSlot))
                onwrong('method', name);
            else if (!impl.methodSignature.equals(provided.methodSignature))
                onundefined('default', name, provided.methodSignature);
        }

        override public function toString():String {
            var p:String = '';
            if (_typeParams) {
                var builder:Array = [];
                for each (var typeParam:Symbol in _typeParams)
                    builder.push(typeParam.toString());
                p = '.<' + builder.join(', ') + '>';
            }
            return fullyQualifiedName + p;
        }
    }
}