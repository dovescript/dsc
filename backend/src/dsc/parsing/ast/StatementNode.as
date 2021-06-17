package dsc.parsing.ast {
    import dsc.semantics.*;

    public class StatementNode extends DirectiveNode {
        public function get isIterationStatement():Boolean {
            return false;
        }
    }
}