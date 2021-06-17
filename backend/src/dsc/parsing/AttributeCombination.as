package dsc.parsing {

    import dsc.parsing.ast.*;

    /**
     * @private
     */
    internal final class AttributeCombination {

        public var metaData:Array;

        public var accessModifier:ExpressionNode;

        public var staticModifier:Boolean;

        public var overrideModifier:Boolean;

        public var finalModifier:Boolean;

        public var nativeModifier:Boolean;

        public var dynamicModifier:Boolean;

        public function get isEmpty():Boolean { return !accessModifier && !hasModifiers }

        public function get hasModifiers():Boolean { return !!(accessModifier || staticModifier || overrideModifier || finalModifier || nativeModifier || dynamicModifier) }
    }
}