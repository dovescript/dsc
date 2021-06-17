package dsc.parsing.ast {

    import dsc.Span;

    import dsc.semantics.*;

    public class DefinitionNode extends DirectiveNode {

        public var metaData:Array = null;

        public var accessModifier:ExpressionNode = null;

        public var nameSpan:Span = null;

        public var modifiers:uint = 0;

        public function findMetaData(name:String):MetaData {
        	if (metaData) for each (var metaDataItem:MetaData in metaData) if (metaDataItem.name == name) return metaDataItem;

        	return undefined;
        }

        public function removeMetaData(nameOrObject:*):Boolean {
        	var target:MetaData = nameOrObject is String ? findMetaData(nameOrObject) : MetaData(nameOrObject);

        	if (metaData) for (var i:uint = 0; i != metaData.length; ++i) if (metaData[i] == target) return metaData.removeAt(i), true;

        	return false;
        }
    }
}