package dsc.semantics {
    import dsc.semantics.accessErrors.*;
    import dsc.semantics.constants.*;
    import dsc.semantics.frames.*;
    import dsc.semantics.types.*;
    import dsc.semantics.values.*;
    import dsc.util.AnyRangeNumber;

    import com.hurlant.math.BigInteger;
    import flash.utils.Dictionary;

    public final class SymbolFactory {
        private var _context:Context;
        private const _names:Array = [];
        private const _uriNamespaces:* = {};
        private const _typeInstantiations:Dictionary = new Dictionary;
        private const _tupleTypes:Array = [];
        private const _nullableTypes:Dictionary = new Dictionary;

        /**
         * @private
         */
        public const _methodSignatures:Array = [];

        public function SymbolFactory(context:Context) {
            this._context = context;
        }

        // Uncategorized

        public function objectValue():Symbol {
            var r:Symbol = new ObjectValue;
            r.valueType = _context.statics.anyType;
            return r;
        }

        public function name(qualifier:Symbol, localName:String):Symbol {
            for (var i:uint = _names.length; i < localName.length; ++i)
                _names.push([]);
            var list:Array = _names[localName.length - 1];
            for each (var name:Name in list)
                if (name.localName == localName && name.qualifier == qualifier)
                    return name;
            var r:Name = new Name(qualifier, localName);
            r._context = _context;
            list.push(r);
            return r;
        }

        public function namespaceSet(prefix:String = undefined):NamespaceSet {
            var nss:NamespaceSet = new NamespaceSet(prefix);
            nss._context = _context;
            nss.valueType = _context.statics.namespaceType;
            return nss;
        }

        public function packageSymbol(id:String):Symbol {
            var p1:Symbol = _context.statics.topPackage ? _context.statics.topPackage.findSubpackage(id) : null;
            if (p1) return p1;
            var splitId:Array = id.split('.');
            var growId:String = '';

            p1 = _context.statics.topPackage;
            if (!p1)
                p1 = new Package(growId),
                p1.valueType = _context.factory.anyType(),
                p1._context = _context,
                Package(p1)._publicNs = reservedNamespaceConstant('public', Package(p1)),
                Package(p1)._internalNs = reservedNamespaceConstant('internal', Package(p1));

            for each (var part in splitId) {
                growId += part;
                var p2:Symbol = p1.findSubpackage(growId);
                if (!p2)
                    p2 = new Package(growId),
                    p2.valueType = _context.factory.anyType(),
                    p2._context = _context,
                    Package(p2)._publicNs = reservedNamespaceConstant('public', Package(p2)),
                    Package(p2)._internalNs = reservedNamespaceConstant('internal', Package(p2)),
                    Package(p1)._subpackages  ||= [],
                    Package(p1)._subpackages.push(p2);
                p1 = p2;
                growId += '.';
            }
            return p1;
        }

        public function delegate(definedIn:Symbol):Delegate {
            var d:Delegate = new Delegate(definedIn);
            d._context = _context;
            return d;
        }

        public function targetAndValue(target:Symbol, value:Symbol):TargetAndValue {
            var r:TargetAndValue = new TargetAndValue(target, value);
            return r._context = _context, r;
        }

        public function skipVarDefinition():Symbol {
            var r:SkipVarDefinition = new SkipVarDefinition;
            return r._context = _context, r;
        }

        public function methodSignature(params:Array, optParams:Array, hasRest:Boolean, result:Symbol):MethodSignature {
            var paramsLength:uint = params ? params.length : 0;
            if (paramsLength >= _methodSignatures.length)
                for (var i:uint = _methodSignatures.length; i <= paramsLength; ++i)
                    _methodSignatures.push([]);
            var list:Array = _methodSignatures[paramsLength];
            var r:MethodSignature = new MethodSignature(params, optParams, hasRest, result);
            for each (var iFn:MethodSignature in list)
                if (iFn.equals(r))
                    return iFn;
            list.push(r);
            return r;
        }

        // Frames

        public function frame():Symbol {
            var frame:Frame = new Frame;
            frame._context = _context;
            frame._openNamespaceList = namespaceSet();
            return frame;
        }

        public function objectFrame(obj:Symbol):Symbol {
            var frame:Frame = new ObjectFrame(obj);
            frame._context = _context;
            frame._openNamespaceList = namespaceSet();
            return frame;
        }

        public function classFrame(type:Symbol):Symbol {
            var frame:Frame = new ClassFrame(type);
            frame._context = _context;
            frame._openNamespaceList = namespaceSet();
            for each (var superClass:Symbol in type.getAscendingSuperClasses())
                frame.openNamespaceList.addItem(superClass.protectedNs);
            frame._openNamespaceList.addItem(type.privateNs);
            frame._openNamespaceList.addItem(type.protectedNs);
            return frame;
        }

        public function enumFrame(type:Symbol):Symbol {
            var frame:Frame = new EnumFrame(type);
            frame._context = _context;
            frame._openNamespaceList = namespaceSet();
            frame._openNamespaceList.addItem(type.privateNs);
            return frame;
        }

        public function interfaceFrame(type:Symbol):Symbol {
            var frame:Frame = new InterfaceFrame(type);
            frame._context = _context;
            frame._openNamespaceList = namespaceSet();
            return frame;
        }

        public function packageFrame(symbol:Symbol):Symbol {
            var frame:Frame = new PackageFrame(symbol);
            frame._context = _context;
            frame._openNamespaceList = namespaceSet();
            frame._openNamespaceList.addItem(symbol.publicNs);
            frame._openNamespaceList.addItem(symbol.internalNs);
            return frame;
        }

        public function activation(thisType:Symbol):Symbol {
            var frame:Frame = new Activation(thisValue(thisType));
            frame._context = _context;
            frame._openNamespaceList = namespaceSet();
            This(frame.thisValue)._activation = frame;
            return frame;
        }

        public function withFrame(type:Symbol):Symbol {
            var frame:WithFrame = new WithFrame;
            frame._context = _context;
            frame._openNamespaceList = namespaceSet();
            frame._symbol = referenceValue(frame, variableSlot(null, true, type));
            return frame;
        }

        // Slots

        public function methodSlot(name:Symbol, signature:MethodSignature):Symbol {
            var slot:Symbol = new MethodSlot(name, signature, _context.statics.functionType);
            slot._context = _context;
            return slot;
        }

        public function variableSlot(name:Symbol, readOnly:Boolean, type:Symbol):Symbol {
            var slot:Symbol = new VariableSlot(name, readOnly, type);
            slot._context = _context;
            return slot;
        }

        public function virtualSlot(name:Symbol, type:Symbol):Symbol {
            var slot:Symbol = new VirtualSlot(name, type);
            slot._context = _context;
            return slot;
        }

        // Values

        public function value(type:Symbol):Symbol {
            var value:Symbol = new Value;
            value.valueType = type;
            value._context = _context;
            return value;
        }

        public function conversionValue(conversionBase:Symbol, conversionType:Conversion, toType:Symbol, byAsOperator:Boolean):Symbol {
            var value:Symbol = new ConversionValue(conversionBase, conversionType, toType, byAsOperator);
            value._context = _context;
            return value;
        }

        public function incompatibleOperandsLogic():Symbol {
            var value:Symbol = new IncompatibleOperandsLogic(_context.statics.anyType);
            value._context = _context;
            return value;
        }

        public function functionExpValue(methodSlot:Symbol):Symbol {
            var r:Symbol = new FunctionExpValue(methodSlot);
            r._context = _context;
            r.valueType = _context.statics.functionType;
            return r;
        }

        public function referenceValue(object:Symbol, property:Symbol):Symbol {
            if (!(property is Slot))
                return property;
            var r:Symbol = new ReferenceValue(object, property);
            r.valueType = property.valueType;
            r._context = _context;
            return r;
        }

        public function superClassStaticReferenceValue(subclass:Symbol, superClass:Symbol, property:Symbol):Symbol {
            if (!(property is Slot))
                return property;
            var r:Symbol = new SuperClassStaticReferenceValue(subclass, superClass, property);
            r.valueType = property.valueType;
            r._context = _context;
            return r;
        }

        public function dynamicReferenceValue(object:Symbol):Symbol {
            var r:Symbol = new DynamicReferenceValue(object);
            r.valueType = _context.statics.anyType;
            r._context = _context;
            return r;
        }

        public function propertyProxyReferenceValue(object:Symbol, proxy:PropertyProxy):Symbol {
            var r:Symbol = new PropertyProxyReferenceValue(object, proxy);
            r.valueType = proxy.valueType;
            r._context = _context;
            return r;
        }

        public function attributeProxyReferenceValue(object:Symbol, proxy:PropertyProxy):Symbol {
            var r:Symbol = new AttributeProxyReferenceValue(object, proxy);
            r.valueType = proxy.valueType;
            r._context = _context;
            return r;
        }

        public function applyProxyValue(object:Symbol, proxyMethod:Symbol):Symbol {
            var r:Symbol = new ApplyProxyValue(object, proxyMethod);
            r._context = _context;
            return r;
        }

        public function descendants(object:Symbol, proxyMethod:Symbol):Symbol {
            var r:Symbol = new Descendants(object, proxyMethod);
            r.valueType ||= _context.statics.anyType;
            r._context = _context;
            return r;
        }

        public function tupleElement(object:Symbol, index:Number):Symbol {
            var r:Symbol = new TupleElement(object, index);
            r._context = _context;
            return r;
        }

        public function thisValue(type:Symbol):This {
            var value:This = new This;
            value._context = _context;
            value.valueType = type;
            return value;
        }

        // Constants

        public function undefinedConstant(type:Symbol = null):Symbol {
            var r:Symbol = new UndefinedConstant;
            r.valueType = type || _context.statics.voidType;
            r._context = _context;
            return r;
        }

        public function nullConstant(type:Symbol = null):Symbol {
            var r:Symbol = new NullConstant;
            r.valueType = type || _context.statics.nullType;
            r._context = _context;
            return r;
        }

        public function reservedNamespaceConstant(type:String, definedIn:Package):Symbol {
            var r:Symbol = new ReservedNamespaceConstant(type, definedIn);
            r.valueType = _context.statics.namespaceType;
            r._context = _context;
            return r;
        }

        public function explicitNamespaceConstant(prefix:String, uri:String = null):Symbol {
            var r:Symbol;
            uri ||= null;
            if (uri) {
                r = _uriNamespaces[uri];
                if (r is Symbol) return r;
            }
            r = new ExplicitNamespaceConstant(prefix, uri);
            r.valueType = _context.statics.namespaceType;
            r._context = _context;
            if (uri) _uriNamespaces[uri] = r;
            return r;
        }

        public function booleanConstant(value:Boolean, type:Symbol = null):Symbol {
            var r:Symbol = new BooleanConstant(value);
            r.valueType = type || _context.statics.booleanType;
            r._context = _context;
            return r;
        }

        public function enumConstant(value:AnyRangeNumber, type:Symbol):Symbol {
            var r:Symbol = new EnumConstant(value);
            r.valueType = type;
            r._context = _context;
            return r;
        }

        public function bigIntConstant(value:BigInteger, type:Symbol = null):Symbol {
            var r:Symbol = new BigIntConstant(value);
            r.valueType = type || _context.statics.bigIntType;
            r._context = _context;
            return r;
        }

        public function numberConstant(value:Number, type:Symbol = null):Symbol {
            var r:Symbol = new NumberConstant(value);
            r.valueType = type || _context.statics.numberType;
            r._context = _context;
            return r;
        }

        public function charConstant(value:uint, type:Symbol = null):Symbol {
            var r:Symbol = new CharConstant(value);
            r.valueType = type || _context.statics.charType;
            r._context = _context;
            return r;
        }

        public function stringConstant(value:String, type:Symbol = null):Symbol {
            var r:Symbol = new StringConstant(value);
            r.valueType = type || _context.statics.stringType;
            r._context = _context;
            return r;
        }

        // Types

        public function anyType():Symbol {
            if (!_context.statics.anyType)
                _context.statics.anyType = new AnyType,
                _context.statics.anyType._context = _context,
                _context.statics.anyType.valueType = _context.statics.classType;
            return _context.statics.anyType;
        }

        public function voidType():Symbol {
            if (!_context.statics.voidType)
                _context.statics.voidType = new VoidType,
                _context.statics.voidType._context = _context,
                _context.statics.voidType.valueType = _context.statics.classType;
            return _context.statics.voidType;
        }

        public function nullType():Symbol {
            if (!_context.statics.nullType)
                _context.statics.nullType = new NullType,
                _context.statics.nullType._context = _context,
                _context.statics.nullType.valueType = _context.statics.classType;
            return _context.statics.nullType;
        }

        public function classType(name:Symbol, flags:uint = 0):Symbol {
            var type:ClassType = new ClassType(name, flags);
            type._context = _context;
            type._privateNs = reservedNamespaceConstant('private', null);
            type._protectedNs = reservedNamespaceConstant('protected', null);
            type.delegate = delegate(type);
            type.delegate.inheritsDelegate = _context.statics.objectType ? _context.statics.objectType.delegate : null,
            type.valueType = _context.statics.classType;
            return type;
        }

        public function enumType(name:Symbol, wrapsType:Symbol, flags:uint, lexicalPublicNs:Symbol):Symbol {
            var type:EnumType = new EnumType(name, wrapsType, flags);
            type._context = _context;
            type._privateNs = reservedNamespaceConstant('private', null);
            type.delegate = delegate(type);
            type.delegate.inheritsDelegate = _context.statics.objectType ? _context.statics.objectType.delegate : null;
            type.valueType = _context.statics.classType;
            return type;
        }

        public function interfaceType(name:Symbol):Symbol {
            var type:Symbol = new InterfaceType(name);
            type._context = _context;
            type.delegate = delegate(type);
            type.valueType = _context.statics.classType;
            return type;
        }

        public function instantiatedType(origin:Symbol, arguments:Array):Symbol {
            var type:Symbol;
            var type2:Symbol;
            var params:Array = origin.typeParams;
            var i:uint;
            var equalsOrigin:Boolean;

            for each (type2 in arguments) {
                if (type2 == params[i++]) {
                    equalsOrigin = false;
                    break;
                }
            }

            if (equalsOrigin)
                return origin;

            var l:uint = arguments.length;
            var list:Array = _typeInstantiations[origin] ||= [];

            search:
            for each (type2 in list) {
                var arguments2:Array = type2.arguments;
                for (i = 0; i != l; ++i)
                    if (arguments2[i] != arguments[i])
                        continue search;
                return type2;
            }

            type = new InstantiatedType(origin, arguments.slice());
            type._context = _context;
            type.valueType = _context.statics.classType;
            list.push(type);
            return type;
        }

        public function tupleType(elements:Array):Symbol {
            var type:TupleType;
            var i:uint;
            var l:uint = elements.length;

            for (i = _tupleTypes.length; i < l; ++i)
                _tupleTypes.push([]);

            var list:Array = _tupleTypes[l - 1];

            search:
            for each (var type2:TupleType in list) {
                var elements2:Array = type2.tupleElements;
                for (i = 0; i != l; ++i)
                    if (elements[i] != elements2[i])
                        continue search;
                return type2;
            }

            type = new TupleType(elements.slice());
            type._context = _context;
            type.delegate = _context.statics.objectType ? _context.statics.objectType.delegate : null;
            type.valueType = _context.statics.classType;
            list.push(type);
            return type;
        }

        public function nullableType(wrapsType:Symbol):Symbol {
            if (wrapsType.containsNull && wrapsType.containsUndefined)
                return wrapsType;

            var type:Symbol = _nullableTypes[wrapsType];

            if (type) return type;

            type = new NullableType(wrapsType);
            type._context = _context;
            type.valueType = _context.statics.classType;
            type.delegate = wrapsType.delegate;
            _nullableTypes[wrapsType] = type;
            return type;
        }

        public function typeParameter(name:Symbol, definedIn:Symbol):Symbol {
            var type:Symbol = new TypeParameter(name, definedIn);
            type._context = _context;
            return type;
        }

        // Errors

        public function ambiguousReference(name:String, betweenPackages:Array = null):Symbol {
            var e:Symbol = new AmbiguousReference(name, betweenPackages);
            e._context = _context;
            return e;
        }

        public function incompatibleArgumentType(index:uint, expectedType:Symbol, gotType:Symbol):Symbol {
            var e:Symbol = new IncompatibleArgumentType(index, expectedType, gotType);
            e._context = _context;
            return e;
        }

        public function wrongNumberOfArguments(number:uint):Symbol {
            var e:Symbol = new WrongNumberOfArguments(number);
            e._context = _context;
            return e;
        }

        public function duplicateDefinition(name:Symbol, definition:Symbol):Symbol {
            var e:Symbol = new DuplicateDefinition(name, definition);
            return e._context = _context, e;
        }

        public function incompatibleOverrideSignature(expectedSignature:MethodSignature):Symbol {
            var e:Symbol = new IncompatibleOverrideSignature(expectedSignature);
            return e._context = _context, e;
        }

        public function mustOverrideAMethod():Symbol {
            var e:Symbol = new MustOverrideAMethod;
            return e._context = _context, e;
        }

        public function overridingFinal():Symbol {
            var e:Symbol = new OverridingFinal;
            return e._context = _context, e;
        }
    }
}