package dsdoc {
    import dsc.*;
    import dsc.parsing.*;
    import dsc.parsing.ast.*;
    import dsc.semantics.*;
    import dsc.semantics.constants.*;
    import dsc.semantics.types.*;
    import dsc.util.PathHelpers;
    import dsc.util.StringHelpers;
    import dsc.verification.*;

    import flash.utils.Dictionary;

    public final class ReferenceGenerator {
        private var verifier:Verifier;
        private var semanticContext:Context;
        private const definitionTags:Dictionary = new Dictionary;

        public function ReferenceGenerator(options:*) {
            var compiler:Compiler = options.compiler;
            verifier = compiler.verifier;
            semanticContext = verifier.semanticContext;
        }

        private function verify(node:Node):Symbol {
            return verifier.result.symbolOf(node);
        }

        private function getTags(definition:Symbol):Array {
            return definitionTags[definition];
        }
    }
}