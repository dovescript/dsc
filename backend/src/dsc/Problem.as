package dsc {
    /**
     * Represents a source problem.
     */
    public final class Problem {
        private var _messageId:String;
        private var _errorType:String;
        private var _variables:*;
        private var _location:SourceLocation;

        /**
         * @param errorType <code>verifyError</code>, <code>syntaxError</code> or <code>warning</code>.
         */
        public function Problem(messageId:String, errorType:String, location:SourceLocation, variables:* = undefined) {
            _messageId = messageId;
            _errorType = errorType;
            _location = location;
            _variables = variables;
        }

        public function get messageId():String {
            return _messageId;
        }

        public function get location():SourceLocation {
            return _location;
        }

        public function get isError():Boolean {
            return !isWarning;
        }

        public function get isVerifyError():Boolean {
            return _errorType == "verifyError";
        }

        public function get isSyntaxError():Boolean {
            return _errorType == "syntaxError";
        }

        public function get isWarning():Boolean {
            return _errorType == "warning";
        }

        public function get variables():* {
            return _variables;
        }
    }
}