package dsc.semantics {
    import dsc.semantics.types.*;

    /**
     * @internal In DoveScript, MethodSignature could be a primitive class.
     */
    public final class MethodSignature {
        /**
         * @private
         */
        internal var _params:Array;

        /**
         * @private
         */
        internal var _optParams:Array;

        private var _hasRest:Boolean;
        private var _result:Symbol;

        public function MethodSignature(params:Array = null, optParams:Array = null, hasRest:Boolean = false, result:Symbol = null) {
            _params = params ? params.slice() : null;
            _optParams = optParams ? optParams.slice() : null;
            _hasRest = hasRest;
            _result = result;
        }

        public function equals(argument:MethodSignature):Boolean {
            var i:uint, l:uint;

            // Required parameters
            if (this._params) {
                l = this._params.length;
                if (!argument._params || argument._params.length != l)
                    return false;
                for (i = 0; i != l; ++i)
                    if (this._params[i] != argument._params[i])
                        return false;
            }
            else if (argument._params)
                return false;

            // Optional parameters
            if (this._optParams) {
                l = this._optParams.length;
                if (!argument._optParams || argument._optParams.length != l)
                    return false;
                for (i = 0; i != l; ++i)
                    if (this._optParams[i] != argument._optParams[i])
                        return false;
            }
            else if (argument._optParams)
                return false;

            if (this._hasRest ? !argument._hasRest : argument._hasRest)
                return false;

            return _result == argument._result;
        }

        public function get params():Array {
            return _params ? _params.slice() : null;
        }

        public function get optParams():Array {
            return _optParams ? _optParams.slice() : null;
        }

        public function get hasRest():Boolean {
            return _hasRest;
        }

        public function get result():Symbol {
            return _result;
        }

        /**
         * Verifies argument values for errors.
         * @return Collection of errors, where each one is either:
         * <ul>
         * <li>dsc.semantics.accessErrors.WrongNumberOfArguments</li>
         * <li>dsc.semantics.accessErrors.IncompatibleArgumentType</li>
         * </ul>
         */
        public function verifyArguments(context:Context, arguments:Array):Array {
            var errors:Array;
            var i:uint;
            var reqParamsNumber:uint = _params ? _params.length : 0;
            var optParamsNumber:uint = _optParams ? _optParams.length : 0;
            var maxNumber:Number = hasRest ? Infinity : reqParamsNumber + optParamsNumber;

            if (Number(arguments.length) < reqParamsNumber)
                errors ||= [],
                errors.push(context.factory.wrongNumberOfArguments(reqParamsNumber));

            if (Number(arguments.length) > maxNumber)
                errors ||= [],
                errors.push(context.factory.wrongNumberOfArguments(maxNumber));

            if (_params) {
                for (i = 0; i != reqParamsNumber; ++i) {
                    if (i >= arguments.length) break;
                    if (_params[i] != arguments[i].valueType)
                        errors ||= [],
                        errors.push(context.factory.incompatibleArgumentType(i, _params[i], arguments[i].valueType));
                }
            }

            if (_optParams) {
                var l:uint = reqParamsNumber + optParamsNumber;
                for (i = i; i != l; ++i) {
                    if (i >= arguments.length) break;
                    if (_optParams[i - reqParamsNumber] != arguments[i].valueType)
                        errors ||= [],
                        errors.push(context.factory.incompatibleArgumentType(i, _optParams[i - reqParamsNumber], arguments[i].valueType));
                }
            }
            return errors;
        }

        public function overridableBy(argument:MethodSignature):Boolean {
            var i:uint, l:uint;

            // required parameters
            if (this._params) {
                l = this._params.length;
                if (!argument._params || argument._params.length != l)
                    return false;
                for (i = 0; i != l; ++i)
                    if (this._params[i] != argument._params[i])
                        return false;
            }
            else if (argument._params)
                return false;

            // optional parameters
            if (this._optParams) {
                l = this._optParams.length;
                if (!argument._optParams || argument._optParams.length < l)
                    return false;
                for (i = 0; i != l; ++i)
                    if (this._optParams[i] != argument._optParams[i])
                        return false;
                // cannot introduce extra optional parameters when the super
                // method has a rest parameter
                if (argument._optParams.length > l && this._hasRest)
                    return false;
            }
            else if (argument._optParams && this._hasRest)
                return false;

            if (this._hasRest && !argument._hasRest)
                return false;

            // overrider result type can be subtype of the super method result type
            return this._result == argument._result || this._result is AnyType || argument._result.isSubtypeOf(this._result);
        }

        public function isApplyProxy(context:Context):Boolean {
            return !!(_params && _params.length == 1 && _params[0] == context.statics.arrayType && !_optParams && !hasRest);
        }

        public function toString():String {
            var p:Array = [], type:Symbol;
            if (_params)
                for each (type in _params) p.push(type.toString());
            if (_optParams)
                for each (type in _optParams) p.push(type.toString() + '=');
            if (hasRest) p.push('...');
            return 'function(' + p.join(', ') + ')' + ':' + result.toString();
        }
    }
}