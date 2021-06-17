package dsc.semantics.values {
	import dsc.semantics.*;

    public final class This extends Value {
        /**
         * @private
         */
        public var _activation:Symbol;

		/**
		 * @private
		 */
		public function This() {}

        override public function get activation():Symbol {
            return _activation;
        }

        override public function toString():String {
            return '[object This]';
        }
    }
}