package dsc.semantics {
    public final class Conversion {
        static public const NUMERIC:Conversion = new Conversion('numeric');
        static public const ANY:Conversion = new Conversion('any');
        static public const FROM_ANY:Conversion = new Conversion('fromAny');

        /**
         * Conversion from String. It can be one of the following cases:
         * <ul>
         * <li>String-to-<code>enum</code></li>
         * </ul>
         */
        static public const FROM_STRING:Conversion = new Conversion('fromString');

        static public const STRING:Conversion = new Conversion('string');
        static public const ARRAY_TO_FLAGS:Conversion = new Conversion('arrayToFlags');
        static public const IMPLEMENTED_INTERFACE:Conversion = new Conversion('implementedInterface');

        /**
         * Conversion to super class. It can be one of the following cases:
         * <ul>
         * <li>Subclass to super class</li>
         * <li>Subenum to super class</li>
         * </ul>
         */
        static public const SUPER_CLASS:Conversion = new Conversion('superClass');

        /**
         * Conversion to subclass. It can be one of the following cases:
         * <ul>
         * <li>Base class to subclass</li>
         * <li>Base class to subenum</li>
         * </ul>
         */
        static public const SUBCLASS:Conversion = new Conversion('subclass');

        static public const SUPER_INTERFACE:Conversion = new Conversion('superInterface');
        static public const SUB_INTERFACE:Conversion = new Conversion('subInterface');
        static public const FROM_NULLABLE:Conversion = new Conversion('fromNullable');
        static public const NULLABLE:Conversion = new Conversion('nullable');
        static public const IMPLEMENTOR:Conversion = new Conversion('implementor');

        private var _name:String;

        /**
         * @private
         */
        public function Conversion(name:String) {
            _name = name;
        }

        public function toString():String {
            return _name;
        }
    }
}