package dsc.semantics.types {
    import dsc.semantics.*;
    import dsc.semantics.constants.*;
    import dsc.semantics.frames.*;
    import dsc.semantics.values.*;

    public final class InstantiatedType extends Type {
        private var _originalDefinition:Symbol;

        private var _arguments:Array;

        /**
         * @private
         */
        public function InstantiatedType(originalDefinition:Symbol, arguments:Array) {
            _originalDefinition = originalDefinition;
            _arguments = arguments;
            this.delegate = originalDefinition.delegate;
        }

        override public function get originalDefinition():Symbol {
            return _originalDefinition;
        }

        override public function get arguments():Array {
            return _arguments;
        }

        override public function get name():Symbol {
            return _originalDefinition.name;
        }

        override public function get classFlags():uint {
            return _originalDefinition.classFlags;
        }

        override public function get superType():Symbol {
            return _originalDefinition.superType;
        }

        override public function get definedIn():Symbol {
            return _originalDefinition.definedIn;
        }

        override public function get fullyQualifiedName():String {
            return _originalDefinition.fullyQualifiedName;
        }

        override public function get constructorMethod():Symbol {
            return _originalDefinition.constructorMethod;
        }

        override public function get defaultValue():Symbol {
            return null;
        }

        override public function get containsUndefined():Boolean {
            return false;
        }

        override public function get containsNull():Boolean {
            return false;
        }

        override public function resolveName(name:Symbol):Symbol {
            var r:Symbol = this.originalDefinition.names.resolveName(name);
            return r ? ownerContext.factory.referenceValue(this, r) : null;
        }

        override public function resolveMultiName(nss:NamespaceSet, name:String):Symbol {
            var r:Symbol = this.originalDefinition.names.resolveMultiName(nss, name);
            return r ? ownerContext.factory.referenceValue(this, r) : null;
        }

        override public function toString():String {
            // arguments.join(', ')
            var s:Array = [];
            for each (var argument:Symbol in _arguments)
                s.push(argument.toString());
            return fullyQualifiedName + '.<' + s.join(', ') + '>';
        }
    }
}