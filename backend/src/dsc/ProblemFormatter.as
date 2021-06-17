package dsc {
    import com.siteblade.intl.Translator;
    import dsc.semantics.Symbol;

    public class ProblemFormatter {
        private var _translator:Translator;

        public function ProblemFormatter(translator:Translator) {
            _translator = translator;
        }

        public function format(problem:Problem):String {
            var variables:* = undefined;

            // format vars
            if (problem.variables) {
                variables = {};

                for (var name:String in problem.variables) {
                    var variable:* = problem.variables[name];
                    variables[name] = variable is ProblemWord ? _translator.t(ProblemWord(variable).id) : formatVariable(variable);
                }
            }

            var msg:String = _translator.t(problem.messageId, variables);
            return msg.slice(0, 1).toUpperCase() + msg.slice(1);
        }

        public function formatVariable(variable:*):String {
            return variable.toString();
        }
    }
}