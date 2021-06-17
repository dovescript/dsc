package dsc.verification {

	import dsc.parsing.ast.*;

	import dsc.semantics.Symbol;

	/**
	 * @private
	 */
	internal final class OpenedFunction {

		public var activation:Symbol;

		public var methodSlot:Symbol;

		public var commonNode:FunctionCommonNode;

		public function OpenedFunction(activation:Symbol, methodSlot:Symbol, commonNode:FunctionCommonNode) {
			this.activation = methodSlot ? methodSlot.activation : activation;
			this.methodSlot = methodSlot;
			this.commonNode = commonNode;
		}
	}
}