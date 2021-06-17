package dsc.outputTargets.wasm {
    import dsc.semantics.*;
    import dsc.semantics.constants.*;
    import dsc.semantics.frames.*;
    import dsc.semantics.types.*;
    import dsc.semantics.values.*;
    import dsc.parsing.ast.*;
    import dsc.verification.*;
    import dsc.util.*;

    import com.recoyxgroup.compilerTargets.wasm.*;
    import com.recoyxgroup.compilerTargets.wasm.enum.*;

    import flash.utils.Dictionary;

    public final class WasmExporterShared {
        public const output:WasmOutput = new WasmOutput;
        public const functionSignatureIndexes:Dictionary = new Dictionary;
        public var semanticContext:Context;
        public var programs:Array;
        public var verifier:Verifier;

        public function WasmExporterShared(semanticContext:Context, programs:Array, verifier:Verifier) {
            super();
            this.semanticContext = semanticContext;
            this.programs = programs;
            this.verifier = verifier;
            addFunctionSignatures();
        }

        private function addFunctionSignatures():void {
            for each (var s:MethodSignature in semanticContext.allMethodSignatures()) {
                ;
            }
        }
    }
}