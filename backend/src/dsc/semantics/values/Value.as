package dsc.semantics.values {
	import dsc.semantics.*;
	import dsc.semantics.constants.*;
	import dsc.semantics.types.*;
	import dsc.util.AnyRangeNumber;
	import com.hurlant.math.BigInteger;

    public class Value extends Symbol {
    	private var _type:Symbol;

		override public function get valueType():Symbol {
			return _type;
		}

		override public function set valueType(type:Symbol):void {
			_type = type;
		}

        override public function get readOnly():Boolean {
            return true;
        }

        override public function get writeOnly():Boolean {
            return false;
        }

		override public function resolveName(name:Symbol):Symbol {
			var d:Delegate = _type.delegate;
			var s:Symbol = d ? d.resolveName(name) : null;
			if (s)
				return ownerContext.factory.referenceValue(this, s);
			return ((_type is ClassType && (_type.classFlags & ClassFlags.DYNAMIC)) || _type is AnyType)
				? ownerContext.factory.dynamicReferenceValue(this) : null;
		}

		override public function resolveMultiName(nss:NamespaceSet, name:String):Symbol {
			var d:Delegate = _type.delegate;
			var s:Symbol = d ? d.resolveMultiName(nss, name) : null;
			if (s)
				return ownerContext.factory.referenceValue(this, s);

			var proxy:PropertyProxy = d ? d.findPropertyProxyInTree() : null;
			if (proxy && ownerContext.isNameType(proxy.keyType))
				return ownerContext.factory.propertyProxyReferenceValue(this, proxy);
			return ((_type is ClassType && (_type.classFlags & ClassFlags.DYNAMIC)) || _type is AnyType)
				? ownerContext.factory.dynamicReferenceValue(this) : null;
		}

        override public function convertExplicit(toType:Symbol):Symbol {
			var subconversion:Symbol = convertImplicit(toType);
			if (subconversion)
				return subconversion;
			var ctx:Context = ownerContext;
			var fromType:Symbol = this.valueType;

			// Subclass
			if (fromType is ClassType && toType.isSubtypeOf(fromType))
				return ctx.factory.conversionValue(this, Conversion.SUBCLASS, toType, false);
			// Sub-interface or implementor
			else if (fromType is InterfaceType) {
				if (toType is ClassType && toType.isSubtypeOf(fromType))
					return ctx.factory.conversionValue(this, Conversion.IMPLEMENTOR, toType, false);
				if (toType is InterfaceType && toType.isSubtypeOf(fromType))
					return ctx.factory.conversionValue(this, Conversion.SUB_INTERFACE, toType, false);
			}
			// String-to-enum
			else if (fromType == ctx.statics.stringType && toType is EnumType)
				return ctx.factory.conversionValue(this, Conversion.FROM_STRING, toType, false);
			// Non-nullable from nullable
			else if (fromType is NullableType && (!toType.containsNull || !toType.containsUndefined)) {
				subconversion = this._convertExplicitByMutating(fromType.wrapsType, toType);
				if (subconversion)
					return ctx.factory.conversionValue(subconversion, Conversion.FROM_NULLABLE, toType, false);
			}
			// Array-to-enum
			else if (fromType == ctx.statics.arrayType && toType is EnumType && toType.enumFlags & EnumFlags.FLAGS)
				return ctx.factory.conversionValue(this, Conversion.ARRAY_TO_FLAGS, toType, false);

			// String
			if (toType == ctx.statics.stringType)
				return ctx.factory.conversionValue(this, Conversion.STRING, toType, false);
			// Nullable
			else if (toType is NullableType) {
				subconversion = this.convertExplicit(toType.wrapsType);
				if (subconversion)
					return ctx.factory.conversionValue(subconversion, Conversion.NULLABLE, toType, false);
			}

            return null;
        }

        override public function convertImplicit(toType:Symbol):Symbol {
			var ctx:Context = ownerContext;
			var fromType:Symbol = this.valueType;
			var subconversion:Symbol;
			if (toType == fromType)
				return this;
			// Any
			else if (toType == ctx.statics.anyType)
				return ctx.factory.conversionValue(this, Conversion.ANY, toType, false);
			// Numeric
			else if (ctx.isNumericType(fromType) && ctx.isNumericType(toType))
				return ctx.factory.conversionValue(this, Conversion.NUMERIC, toType, false);
			// Super class
			else if (fromType is ClassType && fromType.isSubtypeOf(toType))
				return ctx.factory.conversionValue(this, Conversion.SUPER_CLASS, toType, false);
			// Implemented interface or super interface
			else if (toType is InterfaceType && fromType.isSubtypeOf(toType)) {
				if (fromType is InterfaceType)
					return ctx.factory.conversionValue(this, Conversion.SUPER_INTERFACE, toType, false);
				else return ctx.factory.conversionValue(this, Conversion.IMPLEMENTED_INTERFACE, toType, false);
			}
			else if ((this is NullConstant || fromType is NullType) && toType.containsNull)
				return ctx.factory.nullConstant(toType);
			else if ((this is UndefinedConstant || fromType is VoidType) && toType.containsUndefined)
				return ctx.factory.undefinedConstant(toType);
			// Nullable
			else if (toType is NullableType) {
				subconversion = this.convertImplicit(toType.wrapsType);
				if (subconversion)
					return ctx.factory.conversionValue(subconversion, Conversion.NULLABLE, toType, false);
			}
			// Non-nullable from nullable
			else if (fromType is NullableType && (!toType.containsNull || !toType.containsUndefined)) {
				subconversion = this._convertImplicitByMutating(fromType.wrapsType, toType);
				if (subconversion)
					return ctx.factory.conversionValue(subconversion, Conversion.FROM_NULLABLE, toType, false);
			}

			// From *
			if (fromType == ctx.statics.anyType)
				return ctx.factory.conversionValue(this, Conversion.FROM_ANY, toType, false);
			// String from Char
			else if (fromType == ctx.statics.charType && toType == ctx.statics.stringType)
				return ctx.factory.conversionValue(this, Conversion.STRING, toType, false);

            return this.convertConstant(toType);
        }

        override public function convertConstant(toType:Symbol):Symbol {
			var fromType:Symbol = this.valueType;
			if (fromType == toType) return this;

			if (this is NumberConstant) {
				if (toType == ownerContext.statics.anyType || toType.escapeType() == ownerContext.statics.objectType)
					return ownerContext.factory.numberConstant(this.valueOf(), toType);
				if (ownerContext.isNumericType(toType.escapeType())) {
					switch (toType.escapeType()) {
						case ownerContext.statics.numberType: return ownerContext.factory.numberConstant(this.valueOf(), toType);
						case ownerContext.statics.charType: return ownerContext.factory.charConstant(this.valueOf(), toType);
						case ownerContext.statics.bigIntType: return ownerContext.factory.bigIntConstant(this.valueOf(), toType);
					}
				}
			}
			else if (this is CharConstant) {
				if (toType == ownerContext.statics.anyType || toType.escapeType() == ownerContext.statics.objectType)
					return ownerContext.factory.charConstant(this.valueOf(), toType);
				if (ownerContext.isNumericType(toType.escapeType())) {
					switch (toType.escapeType()) {
						case ownerContext.statics.numberType: return ownerContext.factory.numberConstant(this.valueOf(), toType);
						case ownerContext.statics.charType: return ownerContext.factory.charConstant(this.valueOf(), toType);
						case ownerContext.statics.bigIntType: return ownerContext.factory.bigIntConstant(new BigInteger(this.valueOf()), toType);
					}
				}
			}
			else if (this is BigIntConstant) {
				if (toType == ownerContext.statics.anyType || toType.escapeType() == ownerContext.statics.objectType)
					return ownerContext.factory.bigIntConstant(this.valueOf(), toType);
				if (ownerContext.isNumericType(toType.escapeType())) {
					switch (toType.escapeType()) {
						case ownerContext.statics.numberType: return ownerContext.factory.numberConstant(this.valueOf().valueOf(), toType);
						case ownerContext.statics.charType: return ownerContext.factory.charConstant(this.valueOf().valueOf() >= 0 && this.valueOf().valueOf() <= 0x10ffff ? this.valueOf().valueOf() : this.valueOf().valueOf() < 0 ? 0 : 0x10ffff, toType);
						case ownerContext.statics.bigIntType: return ownerContext.factory.bigIntConstant(this.valueOf(), toType);
					}
				}
			}
			else if (this is StringConstant) {
				if (toType.escapeType() == ownerContext.statics.charType)
					return ownerContext.factory.charConstant(this.valueOf().charCodeAt(0), toType);
				if (toType == ownerContext.statics.anyType || toType.escapeType() == ownerContext.statics.objectType)
					return ownerContext.factory.stringConstant(this.valueOf(), toType);
			}
			else if (this is BooleanConstant && (toType == ownerContext.statics.anyType || toType.escapeType() == ownerContext.statics.objectType))
				return ownerContext.factory.booleanConstant(this.valueOf(), toType);
			else if (this is UndefinedConstant) {
				var defaultValue:Symbol = toType.defaultValue;
				if (defaultValue) return defaultValue;
			}
			else if (this is NullConstant && toType.containsNull)
				return ownerContext.factory.nullConstant(toType);
            return null;
        }

		private function _convertExplicitByMutating(fromType:Symbol, toType:Symbol):Symbol {
			return this._convertByMutating(fromType, toType, true);
		}

		private function _convertImplicitByMutating(fromType:Symbol, toType:Symbol):Symbol {
			return this._convertByMutating(fromType, toType, false);
		}

		private function _convertByMutating(fromType:Symbol, toType:Symbol, explicit:Boolean):Symbol {
			var k:Symbol = this.valueType;
			this.valueType = fromType;
			var conv:Symbol = explicit ? this.convertExplicit(toType) : this.convertImplicit(toType);
			if (conv && conv is ConversionValue) {
				var list:Array = [];
				while (conv is ConversionValue)
					list.push(conv),
					conv = conv.conversionBase;
				conv = this;
				for each (var conv2:Symbol in list)
					conv = ownerContext.factory.conversionValue(conv, conv2.conversionType, conv2.valueType, false);
			}
			this.valueType = k;
			return conv;
		}

        override public function testDescendantsSupport():Symbol {
            if (_type == ownerContext.statics.anyType)
                return ownerContext.factory.descendants(this, null);
            var proxy:Symbol = _type.delegate ? _type.delegate.resolveName(ownerContext.statics.proxyGetDescendants) : null;
            return proxy && ownerContext.validateGetDescendantsProxy(proxy) ? ownerContext.factory.descendants(this, proxy) : null;
        }

        override public function toString():String {
            return '[object Value]';
        }
    }
}