 package dsc.parsing {
    import dsc.*;
    import dsc.parsing.ast.*;

    public final class ParserContext {
        public var atPackageFrame:Boolean;
        public var atClassFrame:Boolean;
        public var atEnumFrame:Boolean;
        public var atInterfaceFrame:Boolean;
        public var atConstructorBlock:Boolean;
        public var foundSuperStatement:Boolean;
        public var labels:*;
        public var classLocalName:String;
        public var lastBreakableStatement:Node;
        public var lastContinuableStatement:Node;
        public var nextLoopLabel:String;

        public function clone():ParserContext {
            var context:ParserContext = new ParserContext;

            if (labels) {
                var lc:* = {}; for (var name:String in labels) lc[name] = labels[name];
                context.labels = lc;
            }

            context.lastBreakableStatement = lastBreakableStatement;
            context.lastContinuableStatement = lastContinuableStatement;
            return context;
        }
    }
}