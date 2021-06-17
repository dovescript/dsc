package dsc.verification {
    import dsc.*;
    import dsc.parsing.ast.*;
    import dsc.semantics.*;
    import dsc.semantics.accessErrors.*;
    import dsc.semantics.constants.*;
    import dsc.semantics.frames.*;
    import dsc.semantics.types.*;
    import dsc.semantics.values.*;

    import flash.utils.Dictionary;

	public final class VerificationResult {
		private var _currentScript:Script;
		private const _scriptStack:Array = [];
		private const _symbolMappingByScript:Dictionary = new Dictionary;
		private const _verifiedNodeDict:Dictionary = new Dictionary;

		public function enterScript(script:Script):void { _scriptStack.push(_currentScript = script), _symbolMappingByScript[script] ||= new Dictionary, _verifiedNodeDict[script] ||= new Dictionary }
		public function exitScript():void { _scriptStack.pop(), _currentScript = _scriptStack[_scriptStack.length - 1] }
		public function symbolOf(node:Node):Symbol { return !_currentScript ? null : _symbolMappingByScript[_currentScript][node] }
		public function setSymbolOf(node:Node, symbol:Symbol):void { _symbolMappingByScript[_currentScript][node] = symbol, _verifiedNodeDict[_currentScript][node] = true }
        public function unsetSymbolOf(node:Node):void { delete _symbolMappingByScript[_currentScript][node], delete _verifiedNodeDict[_currentScript][node] }

        public function nodeIsAlreadyVerified(node:Node):Boolean {
            var dict:Dictionary = _verifiedNodeDict[_currentScript];
            return dict ? !!dict[node] : false;
        }
	}
}