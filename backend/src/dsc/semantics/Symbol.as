package dsc.semantics {
    import dsc.*;
    import dsc.semantics.accessErrors.*;
    import dsc.semantics.constants.*;
    import dsc.semantics.frames.*;
    import dsc.semantics.types.*;
    import dsc.semantics.values.*;
    import dsc.util.AnyRangeNumber;

    import com.hurlant.math.BigInteger;

    import flash.utils.Dictionary;
    import flash.utils.Proxy;
    import flash.utils.flash_proxy;

    public class Symbol extends Proxy {

        /**
         * @private
         */
        internal var _context:Context;

        public function get ownerContext():Context {
            return _context;
        }

        public function get readOnly():Boolean {
            return true;
        }

        public function set readOnly(value:Boolean):void {
        }

        public function get writeOnly():Boolean {
            return false;
        }

        public function get publicNs():Symbol {
            return null;
        }

        public function set publicNs(value:Symbol):void {
        }

        public function get privateNs():Symbol {
            return null;
        }

        public function set privateNs(value:Symbol):void {
        }

        public function get protectedNs():Symbol {
            return null;
        }

        public function set protectedNs(value:Symbol):void {
        }

        public function get internalNs():Symbol {
            return null;
        }

        public function set internalNs(value:Symbol):void {
        }

        /**
         * For a reserved namespace constant, returns either
         * <code>public</code>, <code>private</code>, <code>protected</code> or <code>internal</code>.
         */
        public function get namespaceType():String {
            return '';
        }

        /**
         * If the symbol is an instantiation of a parameterized type,
         * returns the parameterized type.
         */
        public function get originalDefinition():Symbol {
            return null;
        }

        public function get withFrame():Symbol {
            return null;
        }

        public function set withFrame(frame:Symbol):void {
        }

		public function get name():Symbol {
			return null;
		}

        public function get prefix():String {
            return null;
        }

        public function get uri():String {
            return null;
        }

        public function get fullyQualifiedName():String {
        	var p:Symbol = definedIn;
            return (p && p.fullyQualifiedName ? p.fullyQualifiedName + '.' : '') + (name ? name.toString() : '');
        }

		/**
		 * Indicates the package, type, frame or delegate object in which the symbol is defined.
		 */
        public function get definedIn():Symbol {
            return null;
        }

        public function set definedIn(object:Symbol):void {
        }

        public function get target():Symbol {
            return null;
        }

        public function get value():Symbol {
            return null;
        }

        public function set value(value:Symbol):void {
        }

		/**
		 * Property definitions.
		 */
        public function get names():Names {
            return null;
        }

        /**
         * For a VariableSlot, indicates a (String, AnyRangeNumber) association as an enum constant.
         */
        public function get enumPairAssociation():Array { return undefined }

        public function set enumPairAssociation(array:Array):void {}

        public function resolveName(name:Symbol):Symbol {
            return null;
        }

        public function resolveMultiName(nss:NamespaceSet, name:String):Symbol {
            return null;
        }

		/**
		 * Returns the unique containing symbol if any.
		 */
		public function get symbol():Symbol {
			return null;
		}

		public function get stringValue():String {
			return null;
		}

		public function valueOf():* {
			return undefined;
		}

		public function get valueType():Symbol {
			return null;
		}

        public function set valueType(type:Symbol):void {
        }

        public function get isObservableVariable():Boolean {
            return false;
        }

        /**
         * Applicable to a name: this property results into the namespace.
         */
        public function get qualifier():Symbol {
            return null;
        }

        /**
         * When accessed in a name, this property results into the unqualified name.
         */
        public function get localName():String {
            return null;
        }

        public function get foreignName():String {
            return null;
        }

        public function set foreignName(name:String):void {
        }

        public function get activation():Symbol {
            return null;
        }

        public function set activation(activation:Symbol):void {
        }

        public function toString():String {
            return '';
        }

        public function get propertyProxy():PropertyProxy {
            return null;
        }

        public function set propertyProxy(proxy:PropertyProxy):void {
        }

        public function get attributeProxy():PropertyProxy {
            return null;
        }

        public function set attributeProxy(proxy:PropertyProxy):void {
        }

        public function get applyProxy():Symbol {
            return null;
        }

        public function set applyProxy(proxy:Symbol):void {
        }

        public function get descendantsProxy():Symbol {
            return null;
        }

        public function set descendantsProxy(proxy:Symbol):void {}

        public function setScopeExtendedProperty(property:Symbol):void {
        }

        public function hasScopeExtendedProperty(property:Symbol):Boolean {
            return false;
        }

        public function get actionScriptNumericDataType():Class {
            return this == ownerContext.statics.numberType ? Number : this == ownerContext.statics.bigIntType ? BigInteger : this == ownerContext.statics.charType ? uint : undefined;
        }

        // NamespaceSet methods

		/**
		 * For a namespace set, this property returns an equivalent ascending-order array.
		 */
        public function get namespaces():Array {
            return [];
        }

        public function get length():Number {
            return 0;
        }

        /**
         * Adds item to a namespace set.
         */
		public function addItem(item:Symbol):void {}

        /**
         * Removes the last item of a namespace set.
         */
		public function popItem():Symbol {
			return null;
		}

        /**
         * Removes a number of last items of a namespace set.
         */
        public function popItems(length:uint):Array {
            return [];
        }

        // Constants

        public function enumContains(argument:Symbol):Boolean {
            if (!(this is EnumConstant && argument is EnumConstant))
                return false;
            return !!(this.valueOf().valueOf() & argument.valueOf().valueOf());
        }

        // Delegate

        public function get inheritsDelegate():Delegate {
            return null;
        }

        public function set inheritsDelegate(value:Delegate):void {}

        public function get operators():Dictionary {
            return null;
        }

        public function set operators(value:Dictionary):void {}

        public function get namesTree():NamesTree {
            return null;
        }

        public function resolveNameAtReservedNamespace(nsType:String, name:String):Symbol {
            return null;
        }

        public function findPropertyProxyInTree():PropertyProxy {
            return null;
        }

        public function findAttributeProxyInTree():PropertyProxy {
            return null;
        }

        public function findOperatorInTree(operator:Operator):Symbol {
            return null;
        }

        // Types

        public function defineEnumSpecialMethods(lexicalPublicNs:Symbol):void {
        }

        public function get enumSpecialMethods():EnumSpecialMethods {
            return null;
        }

        public function get tupleElements():Array {
            return null;
        }

        public function get typeParams():Array {
            return null;
        }

        public function set typeParams(array:Array):void {}

        public function get arguments():Array {
            return null;
        }

        public function isSubtypeOf(type:Symbol):Boolean {
            return false;
        }

        public function get defaultValue():Symbol {
            return null;
        }

        public function get containsUndefined():Boolean {
            return false;
        }

        public function get containsNull():Boolean {
            return false;
        }

        public function get wrapsType():Symbol {
            return null;
        }

        public function set wrapsType(type:Symbol):void {
        }

        public function get superType():Symbol {
            return null;
        }

        public function get delegate():Delegate {
            return null;
        }

        public function set delegate(delegate:Delegate):void {}

        public function get classFlags():uint {
            return 0;
        }

        public function set classFlags(flags:uint):void {}

        public function get enumFlags():uint {
            return 0;
        }

        public function set enumFlags(flags:uint):void {}

        public function escapeType():Symbol {
            if (this is NullableType) return this.wrapsType;

            return this;
        }

        public function equalsOrInstantiationOf(argument:Symbol):Boolean {
            return this == argument || this.originalDefinition == argument;
        }

        public function get implementsInterfaces():Array {
            return null;
        }

        public function get subclass():Symbol {
            return null;
        }

        public function get subclasses():Array {
            return null;
        }

        public function get implementors():Array {
            return null;
        }

        public function get superInterfaces():Array {
            return null;
        }

        public function get subInterfaces():Array {
            return null;
        }

        public function get constructorMethod():Symbol {
            return null;
        }

        public function set constructorMethod(method:Symbol):void {
        }

        /**
         * @return Collection of errors, where each is one of:
         * <ul>
         * <li>dsc.semantics.accessErrors.DuplicateDefinition</li>
         * </ul>
         */
        public function extendType(type:Symbol):Array {
            return null;
        }

        public function implementType(type:Symbol):void {
        }

        /**
         * @param onUndefined Function of signature <code>function(methodType:String, name:Symbol, signature:MethodSignature)</code>, where methodType is either <code>default</code>, <code>getter</code> or <code>setter</code>.
         * @param onWrong Function of signature <code>function(slotType:String, name:Symbol)</code>, where slotType is either <code>method</code> or <code>virtualProperty</code>.
         */
        public function verifyInterfaceImplementations(onUndefined:Function, onWrong:Function):void {
        }

        public function getAscendingSuperClasses():Array {
            var r:Array = [];
            for (var st:Symbol = this; st = st.superType; st = st)
                r.unshift(st);
            return r;
        }

        public function get enumConstants():* {
            return null;
        }

        public function getEnumConstant(name:String):Symbol {
            return null;
        }

        public function setEnumConstant(name:String, value:AnyRangeNumber):void {}

        // Packages

        public function addSubpackage(subpackage:Symbol):void {}

        public function findSubpackage(id:String):Symbol {
            return null;
        }

        public function toRecursiveNamespaceSet(prefix:String = undefined):Symbol { return undefined }

        // Frames

        public function get thisValue():Symbol {
            return null;
        }

        public function get openNamespaceList():NamespaceSet {
            return null;
        }

        public function get parentFrame():Symbol {
            return null;
        }

        public function set parentFrame(value:Symbol):void {}

        public function getLexicalReservedNamespace(type:String):Symbol {
            return null;
        }

        public function get importsPackages():Array {
            return null;
        }

        public function importPackage(symbol:Symbol, openPublic:Boolean = true):void {}

        public function get defaultNamespace():Symbol {
            return null;
        }

        public function set defaultNamespace(symbol:Symbol):void {}

        public function get importNameList():Array {
            return null;
        }

        // Value

        public function convertExplicit(toType:Symbol):Symbol {
            return null;
        }

        public function convertImplicit(toType:Symbol):Symbol {
            return null;
        }

        public function convertConstant(toType:Symbol):Symbol {
            return null;
        }

        public function get object():Symbol {
            return null;
        }

        public function get property():Symbol {
            return null;
        }

        public function get ofMethodSlot():Symbol {
            return null;
        }

        public function testDescendantsSupport():Symbol {
            return null;
        }

        public function get isDeletable():Boolean {
            return false;
        }

        /**
         * Tuple element index.
         */
        public function get index():Number {
            return 0;
        }

        // ConversionValue

        public function get conversionBase():Symbol {
            return null;
        }

        public function get conversionType():Conversion {
            return null;
        }

        public function get byAsOperator():Boolean {
            return false;
        }

        public function set byAsOperator(value:Boolean):void {
        }

        // VariableSlot

        public function get initialValue():Symbol {
            return null;
        }

        public function set initialValue(value:Symbol):void {
        }

        // VirtualSlot

        public function get getter():Symbol {
            return null;
        }

        public function set getter(method:Symbol):void {}

        public function get setter():Symbol {
            return null;
        }

        public function set setter(method:Symbol):void {}

        // MethodSlot

        public function get methodOptimizations():Array {
            return null;
        }

        public function set methodOptimizations(list:Array):void {
        }

        public function get methodSignature():MethodSignature {
            return null;
        }

        public function set methodSignature(signature:MethodSignature):void {}

        public function get methodFlags():uint {
            return 0;
        }

        public function set methodFlags(flags:uint):void {}

        public function get ofVirtualSlot():Symbol {
            return undefined;
        }

        public function set ofVirtualSlot(slot:Symbol):void {
        }

        public function get overriders():Dictionary {
            return undefined;
        }

        /**
         * Overrides method in one of the inherited delegates.
         *
         * @return <code>null</code>, dsc.semantics.accessErrors.IncompatibleOverrideSignature,
         * dsc.semantics.accessErrors.MustOverrideAMethod or dsc.semantics.accessErrors.OverridingFinal.
         */
        public function override(delegate:Symbol):Symbol {
            return undefined;
        }

        // AccessError

        /**
         * If an ambiguous reference is between packages, returns the possible qualifier packages.
         */
        public function get betweenPackages():Array {
            return null;
        }

        public function get expectedArgumentsNumber():Number {
            return 0;
        }

        public function get argumentIndex():uint {
            return 0;
        }

        public function get expectedArgumentType():Symbol {
            return null;
        }

        public function get gotArgumentType():Symbol {
            return null;
        }

        public function get duplicateDefinition():Symbol {
            return null;
        }

        public function get expectedMethodSignature():MethodSignature {
            return undefined;
        }
    }
}