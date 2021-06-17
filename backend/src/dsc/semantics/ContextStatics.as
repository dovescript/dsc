package dsc.semantics {
    import flash.utils.Dictionary;

    public final class ContextStatics {
        private var _context:Context;
        private var _factory:SymbolFactory;

        public var topPackage:Symbol;
        public var dsGlobalPackage:Symbol;
        public var dsOctetPackage:Symbol;
        public var proxyNamespace:Symbol;
        public var anyType:Symbol;
        public var voidType:Symbol;
        public var nullType:Symbol;
        public var objectType:Symbol;
        public var classType:Symbol;
        public var arrayType:Symbol;
        public var namespaceType:Symbol;
        public var qnameType:Symbol;
        public var stringType:Symbol;
        public var rangeType:Symbol;
        public var bigIntType:Symbol;
        public var charType:Symbol;
        public var numberType:Symbol;
        public var numericTypes:Array;
        public var integerTypes:Array;
        public var nameTypes:Array;
        public var booleanType:Symbol;
        public var functionType:Symbol;
        public var mapType:Symbol;
        public var regExpType:Symbol;
        public var xmlType:Symbol;
        public var xmlListType:Symbol;
        public var octetArrayType:Symbol;
        public var generatorType:Symbol;
        public var promiseType:Symbol;
        public var promiseAnyType:Symbol;
        public var observableType:Symbol;
        public var observableAnyType:Symbol;

        public var proxyApply:Symbol;
        public var proxyGetProperty:Symbol;
        public var proxySetProperty:Symbol;
        public var proxyDeleteProperty:Symbol;
        public var proxyHasProperty:Symbol;
        public var proxyGetAttribute:Symbol;
        public var proxySetAttribute:Symbol;
        public var proxyDeleteAttribute:Symbol;
        public var proxyGetDescendants:Symbol;
        public var proxyFilter:Symbol;
        public var proxyCompare:Symbol;
        public var proxyCompareDesc:Symbol;
        public var proxyNextNameIndex:Symbol;
        public var proxyNextName:Symbol;
        public var proxyNextValue:Symbol;
        public var proxyNegate:Symbol;
        public var proxyEquals:Symbol;
        public var proxyNotEquals:Symbol;
        public var proxyLessThan:Symbol;
        public var proxyGreaterThan:Symbol;
        public var proxyLessThanOrEquals:Symbol
        public var proxyGreaterThanOrEquals:Symbol;
        public var proxyAdd:Symbol;
        public var proxySubtract:Symbol;
        public var proxyMultiply:Symbol;
        public var proxyDivide:Symbol;
        public var proxyRemainder:Symbol;

        public function ContextStatics() {
        }

        public function allMethodSignatures():Array {
            var r:Array = [];
            for each (var list:Array in _factory._methodSignatures)
                for each (var s:MethodSignature in list)
                    r.push(s);
            return r;
        }

        /**
         * @private
         */
        internal function _init(context:Context):void {
            this._context = context;
            this._factory = context.factory;

            topPackage = _factory.packageSymbol('');
            dsGlobalPackage = _factory.packageSymbol('ds.global');
            dsOctetPackage = _factory.packageSymbol('ds.octet');
            proxyNamespace = _factory.explicitNamespaceConstant('Proxy', 'http://dovescript.org/globalobjects/ds/global/Proxy');

            anyType = _factory.anyType();
            voidType = _factory.voidType();
            nullType = _factory.nullType();
            objectType = _defineClass(dsGlobalPackage, 'Object', ClassFlags.DYNAMIC);
            classType = _defineClass(dsGlobalPackage, 'Class', ClassFlags.FINAL | ClassFlags.DYNAMIC);
            anyType.valueType =
            voidType.valueType =
            nullType.valueType =
            objectType.valueType =
            classType.valueType = classType;

            arrayType = _defineClass(dsGlobalPackage, 'Array');
            namespaceType = _defineClass(dsGlobalPackage, 'Namespace', ClassFlags.FINAL);
            qnameType = _defineClass(dsGlobalPackage, 'QName', ClassFlags.PRIMITIVE);
            stringType = _defineClass(dsGlobalPackage, 'String', ClassFlags.PRIMITIVE);
            booleanType = _defineClass(dsGlobalPackage, 'Boolean', ClassFlags.PRIMITIVE);
            rangeType = _defineClass(dsGlobalPackage, 'Range', ClassFlags.PRIMITIVE);
            functionType = _defineClass(dsGlobalPackage, 'Function', ClassFlags.FINAL);
            bigIntType = _defineClass(dsGlobalPackage, 'BigInt', ClassFlags.PRIMITIVE);
            numberType = _defineClass(dsGlobalPackage, 'Number', ClassFlags.PRIMITIVE);
            charType = _defineClass(dsGlobalPackage, 'Char', ClassFlags.PRIMITIVE);
            numericTypes = [bigIntType, numberType, charType];
            integerTypes = [bigIntType, charType];
            mapType = _defineClass(dsGlobalPackage, 'Map');
            regExpType = _defineClass(dsGlobalPackage, 'RegExp', ClassFlags.FINAL);
            xmlType = _defineClass(dsGlobalPackage, 'XML', ClassFlags.FINAL);
            xmlListType = _defineClass(dsGlobalPackage, 'XMLList', ClassFlags.FINAL);
            octetArrayType = _defineClass(dsOctetPackage, 'OctetArray', ClassFlags.FINAL);
            generatorType = _defineClass(dsGlobalPackage, 'Generator', ClassFlags.FINAL);

            observableType = _defineClass(dsGlobalPackage, 'Observable', ClassFlags.FINAL);
            observableType.typeParams = [ _factory.typeParameter(_factory.name(observableType.privateNs, 'T'), observableType) ];
            observableAnyType = _factory.instantiatedType(observableType, [anyType]);

            promiseType = _defineClass(dsGlobalPackage, 'Promise');
            promiseType.typeParams = [ _factory.typeParameter(_factory.name(promiseType.privateNs, 'T'), promiseType) ];
            promiseAnyType = _factory.instantiatedType(promiseType, [anyType]);

            nameTypes = [stringType, anyType, objectType, qnameType];

            proxyApply = _factory.name(proxyNamespace, 'apply');
            proxyGetProperty = _factory.name(proxyNamespace, 'getProperty');
            proxySetProperty = _factory.name(proxyNamespace, 'setProperty');
            proxyDeleteProperty = _factory.name(proxyNamespace, 'deleteProperty');
            proxyHasProperty = _factory.name(proxyNamespace, 'hasProperty');
            proxyGetAttribute = _factory.name(proxyNamespace, 'getAttribute');
            proxySetAttribute = _factory.name(proxyNamespace, 'setAttribute');
            proxyDeleteAttribute = _factory.name(proxyNamespace, 'deleteAttribute');
            proxyGetDescendants = _factory.name(proxyNamespace, 'getDescendants');
            proxyFilter = _factory.name(proxyNamespace, 'filter');
            proxyCompare = _factory.name(proxyNamespace, 'compare');
            proxyCompareDesc = _factory.name(proxyNamespace, 'compareDesc');
            proxyNextNameIndex = _factory.name(proxyNamespace, 'nextNameIndex');
            proxyNextName = _factory.name(proxyNamespace, 'nextName');
            proxyNextValue = _factory.name(proxyNamespace, 'nextValue');
            proxyNegate = _factory.name(proxyNamespace, 'negate');
            proxyEquals = _factory.name(proxyNamespace, 'equals');
            proxyNotEquals = _factory.name(proxyNamespace, 'notEquals');
            proxyLessThan = _factory.name(proxyNamespace, 'lessThan');
            proxyGreaterThan = _factory.name(proxyNamespace, 'greaterThan');
            proxyLessThanOrEquals = _factory.name(proxyNamespace, 'lessOrEquals');
            proxyGreaterThanOrEquals = _factory.name(proxyNamespace, 'greaterOrEquals');
            proxyAdd = _factory.name(proxyNamespace, 'add');
            proxySubtract = _factory.name(proxyNamespace, 'subtract');
            proxyMultiply = _factory.name(proxyNamespace, 'multiply');
            proxyDivide = _factory.name(proxyNamespace, 'divide');
            proxyRemainder = _factory.name(proxyNamespace, 'remainder');

            // "undefined" property
            var undefinedVar:Symbol = _factory.variableSlot(_factory.name(dsGlobalPackage.publicNs, 'undefined'), true, voidType);
            undefinedVar.initialValue = _factory.undefinedConstant();
            dsGlobalPackage.names.defineName(undefinedVar.name, undefinedVar);

            // "NaN" property
            var nanVar:Symbol = _factory.variableSlot(_factory.name(dsGlobalPackage.publicNs, 'NaN'), true, numberType);
            nanVar.initialValue = _factory.numberConstant(NaN);
            dsGlobalPackage.names.defineName(nanVar.name, nanVar);

            // "Infinity" property
            var infVar:Symbol = _factory.variableSlot(_factory.name(dsGlobalPackage.publicNs, 'Infinity'), true, numberType);
            infVar.initialValue = _factory.numberConstant(Infinity);
            dsGlobalPackage.names.defineName(infVar.name, infVar);

            // "Proxy" property
            dsGlobalPackage.names.defineName(_factory.name(dsGlobalPackage.publicNs, 'Proxy'), proxyNamespace);

            topPackage.valueType =
            dsGlobalPackage.valueType =
            dsOctetPackage.valueType = anyType;

            topPackage.publicNs.valueType =
            topPackage.internalNs.valueType =

            dsGlobalPackage.publicNs.valueType =
            dsGlobalPackage.internalNs.valueType =

            dsOctetPackage.publicNs.valueType =
            dsOctetPackage.internalNs.valueType =

            objectType.privateNs.valueType =
            objectType.protectedNs.valueType =

            classType.privateNs.valueType =
            classType.protectedNs.valueType =

            arrayType.privateNs.valueType =
            arrayType.protectedNs.valueType =

            namespaceType.privateNs.valueType =
            namespaceType.protectedNs.valueType =

            proxyNamespace.valueType = namespaceType;
        }

        private function _defineClass(basePackage:Symbol, name:String, flags:uint = 0):Symbol {
            basePackage ||= dsGlobalPackage;
            var qname:Symbol = _context.factory.name(basePackage.publicNs, name);
            var r:Symbol = _context.factory.classType(qname, flags);
            r.definedIn = basePackage;
            basePackage.names.defineName(qname, r);
            return r;
        }
    }
}