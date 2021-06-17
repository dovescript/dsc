package dsc.semantics.values {
	import dsc.semantics.*;

    public final class ConversionValue extends Value {
        private var _conversionBase:Symbol;
        private var _conversionType:Conversion;
        private var _byAsOperator:Boolean;

		/**
		 * @private
		 */
		public function ConversionValue(conversionBase:Symbol, conversionType:Conversion, toType:Symbol, byAsOperator:Boolean) {
            _conversionBase = conversionBase;
            _conversionType = conversionType;
            valueType = toType;
            _byAsOperator = byAsOperator;
        }

        override public function get conversionBase():Symbol {
            return _conversionBase;
        }

        override public function get conversionType():Conversion {
            return _conversionType;
        }

        override public function get byAsOperator():Boolean {
            return _byAsOperator;
        }

        override public function set byAsOperator(value:Boolean):void {
            _byAsOperator = value;
        }

        override public function toString():String {
            return '[object ConversionValue]';
        }
    }
}