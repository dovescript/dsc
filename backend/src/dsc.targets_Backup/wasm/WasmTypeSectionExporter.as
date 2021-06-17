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

    public final class WasmTypeSectionExporter {
        private var semanticContext:Context;
        private var verifier:Verifier;
        private var shared:WasmExporterShared;

        public function WasmTypeSectionExporter(shared:WasmExporterShared) {
            this.shared = shared;
            this.semanticContext = shared.semanticContext;
            this.verifier = shared.verifier;
            addFunctionSignatures();
        }

        private function addFunctionSignatures():void {
            for each (var s:MethodSignature in semanticContext.allMethodSignatures()) {
                ;
            }
        }
    }
}