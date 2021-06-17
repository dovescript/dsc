package dsc.docGenerator {
    import dsc.*;
    import dsc.docGenerator.tags.*;
    import dsc.parsing.*;
    import dsc.parsing.ast.*;
    import dsc.semantics.*;
    import dsc.semantics.constants.*;
    import dsc.semantics.types.*;
    import dsc.util.StringHelpers;
    import dsc.verification.*;

    import flash.utils.Dictionary;

    /**
     * @private
     */
    internal final class DocTagParser {
        private var verifier:Verifier;
        private var verifyResult:VerificationResult;
        private var semanticContext:Context;
        private const symbolToTagsMappings:Dictionary = new Dictionary;
        private var commentsStack:Array = [];
        private var tagParsers:*;
        private var
            apiPackages:Array,
            apiProperties:Array,
            apiClasses:Array,
            apiEnums:Array,
            apiInterfaces:Array,
            apiFunctions:Array,
            apiFunctionCommons:Dictionary;

        /**
         * A collection of (<i>tagName</i>, <i>script</i>) pairs.
         */
        private const unrecognisedTags:Array = [];

        private static const tagsWithDescription:Array = [
            'description', 'param', 'return', 'returns', 'throws',
            'example',
        ];

        private static const repeatableTags:Array = ['param', 'throws'];

        public function DocTagParser(verifier:Verifier, apiPackages:Array, apiProperties:Array, apiFunctions:Array, apiFunctionCommons:Dictionary, apiClasses:Array, apiEnums:Array, apiInterfaces:Array) {
            this.verifier = verifier;
            verifyResult = verifier.result;
            semanticContext = verifier.semanticContext;

            tagParsers = {
                copy: function(value) { return new CopyTag(resolveItemRef(value)) },
                description: function(value) { return new DescriptionTag(Showdown.makeHtml(value)) },
                example: function(value) { return new ExampleTag(Showdown.makeHtml(value)) },
                hidden: function(value) { return new HiddenTag },
                param: function(value) {
                    var m = value.match(/([^ ]+) (.*)/) || ['undefined', ''];
                    return new ParamTag(m[1], Showdown.makeHtml(m[2]));
                },
                'return': function(value) { return new ReturnTag(Showdown.makeHtml(value)) },
                throws: function(value) {
                    var m = value.match(/([^ ]+) (.*)/) || ['*', ''];
                    m[2] = StringHelpers.trim(m[2]);
                    m[2] = m[2].charAt(0) == '-' ? m[2].slice(1) : m[2];
                    return new ThrowsTag(resolveTypeExp(m[1]) || semanticContext.statics.anyType, m[2]);
                }
            };

            this.apiPackages = apiPackages;
            this.apiProperties = apiProperties;
            this.apiFunctions = apiFunctions;
            this.apiFunctionCommons = apiFunctionCommons;
            this.apiClasses = apiClasses;
            this.apiEnums = apiEnums;
            this.apiInterfaces = apiInterfaces;
        }

        public function parse(programs:Array):Dictionary {
            var program:ProgramNode,
                pckgDefn:PackageDefinitionNode,
                packageObject:Symbol,
                docTags:*;
            for each (program in programs) {
                for each (pckgDefn in program.packages) {
                    verifier.enterScript(pckgDefn.script);
                    commentsStack.push(pckgDefn.script.comments);

                    packageObject = verifyResult.symbolOf(pckgDefn);
                    docTags = shiftDocComment(pckgDefn);
                    if (docTags && docTags.hidden)
                        continue;
                    if (docTags)
                        symbolToTagsMappings[packageObject] = docTags;

                    if (apiPackages.indexOf(packageObject) == -1)
                        apiPackages.push(packageObject);

                    verifier.scopeChain.enterFrame(verifyResult.symbolOf(pckgDefn.block)),
                    findDirectives(pckgDefn.block.directives),
                    verifier.scopeChain.exitFrame(),
                    commentsStack.pop(),
                    verifier.exitScript();
                }
            }

            if (unrecognisedTags.length > 0) {
                for each (var unrecognisedTag:Array in unrecognisedTags)
                    trace('Error: Source uses unrecognised tag', '@' + unrecognisedTag[0]),
                    trace('   at', Script(unrecognisedTag[1]).url);
                return null;
            }
            return symbolToTagsMappings;
        }

        private function get comments():Array { return commentsStack[commentsStack.length - 1] }

        private function resolveItemRef(source:String):Symbol {
            var m:* = source.match(/(.*)#(.+)/);
            if (m) {
                var base:Symbol = m[1] ? resolveExp(m[1]) : verifier.scopeChain.currentFrame.symbol is Type ? verifier.scopeChain.currentFrame.symbol : null;
                return base is Type && base.delegate ? base.delegate.resolveMultiName(null, m[2]) : null;
            }
            else return resolveExp(source);
        }

        private function resolveExp(source:String):Symbol {
            var parser:Parser = new Parser(source);
            var exp:ExpressionNode = parser.parseExpression(true, OperatorPrecedence.LIST_OPERATOR);
            var r:Symbol;
            if (exp)
                verifier.enterScript(parser.script),
                r = verifier.verifyExpression(exp),
                verifier.exitScript();
            return r;
        }

        private function resolveTypeExp(source:String):Symbol {
            var parser:Parser = new Parser(source);
            var exp:ExpressionNode = parser.parseTypeExpression();
            var r:Symbol;
            if (exp)
                verifier.enterScript(parser.script),
                r = verifier.verifyTypeExpression(exp),
                verifier.exitScript();
            return r;
        }

        private function resolveMethodDeclaration(source:String):Array {
            var parser:Parser = new Parser(source + ' 0 as *');
            var exp:FunctionExpressionNode = parser.parseExpression(false, OperatorPrecedence.LIST_OPERATOR) as FunctionExpressionNode;
            var r1:String, r2:Symbol;
            if (exp && exp.name)
                r1 = exp.name,
                verifier.enterScript(parser.script),
                r2 = verifier.verifyExpression(exp),
                r2 = r2 ? r2.ofMethodSlot : null,
                verifier.exitScript();
            return r2 ? [r1, r2] : null;
        }

        private function findDirectives(list:Array):void {
            for each (var drtv:DirectiveNode in list) {
                if (!drtv is DefinitionNode) continue;
                if (drtv is EnumDefinitionNode) findEnum(EnumDefinitionNode(drtv));
                else if (drtv is ClassDefinitionNode) findClass(ClassDefinitionNode(drtv));
                else if (drtv is InterfaceDefinitionNode) findInterface(InterfaceDefinitionNode(drtv));
                else if (drtv is VarDefinitionNode) findVar(VarDefinitionNode(drtv));
                else if (drtv is FunctionDefinitionNode) findFunction(FunctionDefinitionNode(drtv));
                else if (drtv is NamespaceDefinitionNode) findNamespace(NamespaceDefinitionNode(drtv));
                else if (drtv is TypeDefinitionNode) findTypeAlias(TypeDefinitionNode(drtv));
                else if (drtv is IncludeDirectiveNode) findInclude(IncludeDirectiveNode(drtv));
            }
        }

        private function shiftDocComment(untilNode:Node):* {
            while (comments.length != 0) {
                var node:CommentNode = comments.shift();
                if (untilNode && node.span.end >= untilNode.span.start) { comments.unshift(node); break }
                if (node.multiline && node.content.charAt(0) == '*')
                    return parseDocComment(node.content.slice(1));
            }
            return null;
        }

        private function parseDocComment(value:String):* {
            var r:* = {};
            var lines:Array = value.split('\n');
            var rawResults:* = {};
            var ct:String = 'description',
                tagIsRepeatable:Boolean;
            rawResults.description = '';

            for (var i:uint = 0; i < lines.length; ++i) {
                var line:String = StringHelpers.trim(lines[i]);
                line = line.charAt(0) == '*' ? line.slice(1) : line;
                line = line.charAt(0) == ' ' ? line.slice(1) : line;

                var split:* = line.match(/@([a-zA-Z0-9]+)(.*)/);
                if (!split) {
                    if (tagIsRepeatable)
                        rawResults[ct][rawResults[ct].length - 1] += '\n' + line;
                    else rawResults[ct] += '\n' + line;
                    continue;
                }

                ct = split[1];
                tagIsRepeatable = repeatableTags.indexOf(ct) != -1;
                if (tagIsRepeatable)
                    (rawResults[ct] ||= []).push(split[2]);
                else rawResults[ct] = split[2];
                var ctHasDesc:Boolean = tagsWithDescription.indexOf(ct) != -1;
                if (!ctHasDesc)
                    ct = 'description',
                    tagIsRepeatable = false;
            }

            for (var tagName:String in rawResults) {
                var rawV:* = rawResults[tagName];
                var tagParser:Function = tagParsers[tagName] is Function ? tagParsers[tagName] : null;
                if (!tagParser) {
                    // Error
                    unrecognisedTags.push([tagName, verifier.currentScript]);
                    continue;
                }
                tagIsRepeatable = repeatableTags.indexOf(tagName) != -1;
                if (rawV is Array) {
                    r[tagName] = [];
                    for each (var subRawV:String in rawV)
                        r[tagName].push(tagParser(subRawV));
                }
                else r[tagName] = tagParser(rawV);
            }

            return r;
        }

        private function isAPISymbolHidden(name:Symbol, constraints:* = null):Boolean {
            return (constraints && constraints.hidden) || (name ? (name.qualifier is ReservedNamespaceConstant && (name.qualifier.namespaceType == 'private' || name.qualifier.namespaceType == 'internal')) : false) || (name ? name.qualifier == semanticContext.statics.proxyNamespace : false);
        }

        private function addAPISymbol(symbol:Symbol, constraints:* = null, name:Symbol = null):void {
            if (!isAPISymbolHidden(name || symbol.name, constraints)) {
                if (symbol is MethodSlot) apiFunctions.push(symbol);
                else if (symbol is VariableSlot || symbol is VirtualSlot || symbol is NamespaceConstant) apiProperties.push(symbol);
                else if (symbol is ClassType) apiClasses.push(symbol);
                else if (symbol is EnumType) apiEnums.push(symbol);
                else if (symbol is InterfaceType) apiInterfaces.push(symbol);
            }
        }

        private function findInclude(directive:IncludeDirectiveNode):void {
            verifier.enterScript(directive.subscript);
            commentsStack.push(directive.subscript.comments);
            findDirectives(directive.subdirectives);
            commentsStack.pop();
            verifier.exitScript();
        }

        private function findEnum(definition:EnumDefinitionNode):void {
            var type:Symbol = verifyResult.symbolOf(definition);
            var docComment:* = shiftDocComment(definition);
            if (docComment)
                symbolToTagsMappings[type] = docComment;
            addAPISymbol(type, docComment);

            verifier.scopeChain.enterFrame(verifyResult.symbolOf(definition.block));
            findDirectives(definition.block.directives);
            verifier.scopeChain.exitFrame();
        }

        private function findClass(definition:ClassDefinitionNode):void {
            var type:Symbol = verifyResult.symbolOf(definition);
            var docComment:* = shiftDocComment(definition);
            if (docComment)
                symbolToTagsMappings[type] = docComment;
            addAPISymbol(type, docComment);

            verifier.scopeChain.enterFrame(verifyResult.symbolOf(definition.block));
            findDirectives(definition.block.directives);
            verifier.scopeChain.exitFrame();
        }

        private function findInterface(definition:InterfaceDefinitionNode):void {
            var type:Symbol = verifyResult.symbolOf(definition);
            var docComment:* = shiftDocComment(definition);
            if (docComment)
                symbolToTagsMappings[type] = docComment;
            addAPISymbol(type, docComment);

            verifier.scopeChain.enterFrame(verifyResult.symbolOf(definition.block));
            findDirectives(definition.block.directives);
            verifier.scopeChain.exitFrame();
        }

        private function findVar(definition:VarDefinitionNode):void {
            var docComment:* = shiftDocComment(definition);
            var variable:Symbol;
            for each (var binding:VarBindingNode in definition.bindings)
                if (binding.pattern is TypedIdNode)
                    variable = verifyResult.symbolOf(binding.pattern).target,
                    docComment ? symbolToTagsMappings[variable] = docComment : null,
                    addAPISymbol(variable, docComment);
        }

        private function findFunction(definition:FunctionDefinitionNode):void {
            var fn:Symbol = verifyResult.symbolOf(definition);
            var docComment:* = shiftDocComment(definition);
            if (!(docComment && docComment.hidden)) {
                if (docComment) symbolToTagsMappings[fn] = docComment;
                apiFunctionCommons[fn] = definition.common;
                if (!(definition.common.flags & FunctionFlags.CONSTRUCTOR))
                    addAPISymbol(fn, docComment);
            }
        }

        private function findNamespace(definition:NamespaceDefinitionNode):void {
            var constant:Symbol = verifyResult.symbolOf(definition);
            var docComment:* = shiftDocComment(definition);
            if  (docComment)
                symbolToTagsMappings[constant] = docComment;
        }

        private function findTypeAlias(definition:TypeDefinitionNode):void {
            // incomplete
        }
    }
}