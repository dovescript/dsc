package dsc.parsing.ast {
    public class ASTVisitor {
        public function visit(node:Node, argument:* = undefined):* {
            var classDefn:ClassDefinitionNode,
                enumDefn:EnumDefinitionNode,
                functionCommon:FunctionCommonNode,
                functionDefn:FunctionDefinitionNode,
                includeDrtv:IncludeDirectiveNode,
                itrfcDefn:InterfaceDefinitionNode,
                nsDefn:NamespaceDefinitionNode,
                objDefn:ObjectDefinitionNode,
                pckgDefn:PackageDefinitionNode,
                program:ProgramNode,
                simpleVarDecl:SimpleVarDeclarationNode,
                typeDefn:TypeDefinitionNode,
                typedId:TypedIdNode,
                useDefaultDrtv:UseDefaultDirectiveNode,
                useDrtv:UseDirectiveNode,
                varDefn:VarDefinitionNode,
                varBinding:VarBindingNode;

            var defn:DefinitionNode,
                drtv:DirectiveNode,
                expr:ExpressionNode,
                varBinding:VarBindingNode;

            if (defn = node as DefinitionNode) {
                if (defn.accessModifier) this.visit(defn.accessModifier);
            }

            if (typedId = node as TypedIdNode) {
                if (typedId.type) this.visit(typedId.type);
            }
            else if (classDefn = node as ClassDefinitionNode) {
                if (classDefn.extendsElement) this.visit(classDefn.extendsElement);
                if (classDefn.implementsList) for each (expr in classDefn.implementsList) this.visit(expr);
                this.visit(classDefn.block);
            }
            else if (enumDefn = node as EnumDefinitionNode) {
                if (enumDefn.type) this.visit(enumDefn.type);
                this.visit(enumDefn.block);
            }
            else if (functionCommon = node as FunctionCommonNode) {
                if (functionCommon.params) for each (varBinding in functionCommon.params) this.visit(varBinding);
                if (functionCommon.optParams) for each (varBinding in functionCommon.optParams) this.visit(varBinding);
                if (functionCommon.result) this.visit(functionCommon.result);
                if (functionCommon.body) this.visit(functionCommon.body);
            }
            else if (functionDefn = node as FunctionDefinitionNode) this.visit(functionDefn.common);
            else if (includeDrtv = node as IncludeDirectiveNode) {
                if (includeDrtv.subpackages) for each (var subpckg:PackageDefinitionNode in includeDrtv.subpackages) this.visit(subpckg);
                if (includeDrtv.subdirectives) for each (drtv in includeDrtv.subdirectives) this.visit(drtv);
            }
            else if (itrfcDefn = node as InterfaceDefinitionNode) {
                if (itrfcDefn.extendsList) for each (expr in itrfcDefn.extendsList) this.visit(expr);
                this.visit(itrfcDefn.block);
            }
            else if (nsDefn = node as NamespaceDefinitionNode) this.visit(nsDefn.expression);
            else if (objDefn = node as ObjectDefinitionNode) this.visit(objDefn.block);
            else if (pckgDefn = node as PackageDefinitionNode) this.visit(pckgDefn.block);
            else if (program = node as ProgramNode) {
                if (program.packages) for each (pckgDefn in program.packages) this.visit(pckgDefn);
                if (program.directives) for each (drtv in program.directives) this.visit(drtv);
            }
            else if (simpleVarDecl = node as SimpleVarDeclarationNode) for each (varBinding in simpleVarDecl.bindings) this.visit(varBinding);
            else if (typeDefn = node as TypeDefinitionNode) this.visit(typeDefn.type);
            else if (useDefaultDrtv = node as UseDefaultDirectiveNode) this.visit(useDefaultDrtv.expression);
            else if (useDrtv = node as UseDirectiveNode) this.visit(useDrtv.expression);
            else if (varDefn = node as VarDefinitionNode) for each (varBinding in varDefn.bindings) this.visit(varBinding);
            else if (varBinding = node as VarBindingNode) {
                this.visit(varBinding.pattern);
                if (varBinding.initialiser) this.visit(varBinding.initialiser);
            }
        }

        private function _visitExpression(node:Node, argument:* = undefined):* {
            var arrayLtr:ArrayLiteralNode,
                assignment:AssignmentNode,
                attrId:AttributeIdNode,
                binOp:BinaryOperatorNode,
                brackets:BracketsNode,
                call:CallNode,
                desc:DescendantsNode,
                dot:DotNode,
                exprId:ExpressionIdNode,
                fnExpr:FunctionExpressionNode,
                listExpr:ListExpressionNode,
                newOp:NewOperatorNode,
                nullableType:NullableTypeNode,
                objLtr:ObjectLiteralNode,
                parenExpr:ParenExpressionNode,
                simpleId:SimpleIdNode,
                spreadOp:SpreadOperatorNode,
                superNode:SuperNode,
                ternary:TernaryNode,
                typeArgs:TypeArgumentsNode,
                typeOp:TypeOperatorNode,
                unaryOp:UnaryOperatorNode,
                xmlElement:XMLElementNode,
                xmlList:XMLListNode,
                xmlMarkup:XMLMarkupNode,
                xmlText:XMLTextNode;

            var expr:ExpressionNode,
                subnode:Node;

            if (arrayLtr = node as ArrayLiteralNode)
                for each (expr in arrayLtr.elements) this.visit(expr);
            else if (assignment = node as AssignmentNode) this.visit(assignment.left), this.visit(assignment.right);
            else if (attrId = node as AttributeIdNode) this.visit(attrId.id);
            else if (binOp = node as BinaryOperatorNode) this.visit(binOp.left), this.visit(binOp.right);
            else if (brackets = node as BracketsNode) this.visit(brackets.base), this.visit(brackets.key);
            else if (call = node as CallNode) {
                this.visit(call.base);
                for each (expr in call.arguments) this.visit(expr);
            }
            else if (desc = node as DescendantsNode) this.visit(desc.base), this.visit(desc.id);
            else if (dot = node as DotNode) this.visit(dot.base), this.visit(dot.id);
            else if (exprId = node as ExpressionIdNode) {
                if (exprId.qualifier) this.visit(exprId.qualifier);
                this.visit(exprId.key);
            }
            else if (fnExpr = node as FunctionExpressionNode) this.visit(fnExpr.common);
            else if (listExpr = node as ListExpressionNode)
                for each (expr in listExpr.expressions) this.visit(expr);
            else if (newOp = node as NewOperatorNode) {
                this.visit(newOp.base);
                if (newOp.arguments) for each (expr in newOp.arguments) this.visit(expr);
            }
            else if (nullableType = node as NullableTypeNode) this.visit(nullableType.type);
            else if (objLtr = node as ObjectLiteralNode) {
                for each (var field:ObjectFieldNode in objLtr) {
                    this.visit(field.key);
                    if (field.value) this.visit(field.value);
                }
            }
            else if (parenExpr = node as ParenExpressionNode) this.visit(parenExpr.expression);
            else if (simpleId = node as SimpleIdNode) {
                if (simpleId.qualifier) this.visit(simpleId.qualifier);
            }
            else if (spreadOp = node as SpreadOperatorNode) this.visit(spreadOp.expression);
            else if (superNode = node as SuperNode) {
                if (superNode.arguments) for each (expr in superNode.arguments) this.visit(expr);
            }
            else if (ternary = node as TernaryNode)
                this.visit(ternary.expression1),
                this.visit(ternary.expression2),
                this.visit(ternary.expression3);
            else if (typeArgs = node as TypeArgumentsNode) {
                this.visit(typeArgs.base);
                for each (expr in typeArgs.arguments) this.visit(expr);
            }
            else if (typeOp = node as TypeOperatorNode) this.visit(typeOp.left), this.visit(typeOp.right);
            else if (unaryOp = node as UnaryOperatorNode) this.visit(unaryOp.argument);
            else if (xmlElement = node as XMLElementNode) {
                if (xmlElement.openName is ExpressionNode) this.visit(ExpressionNode(xmlElement.openName));
                if (xmlElement.closeName is ExpressionNode) this.visit(ExpressionNode(xmlElement.closeName));
                if (xmlElement.attributes) for each (var xattrib:XMLAttributeNode in xmlElement.attributes) this.visit(xattrib);
                if (xmlElement.childNodes) for each (subnode in xmlElement.childNodes) this.visit(subnode);
            }
            else if (xmlList = node as XMLListNode) for each (subnode in xmlList.nodes) this.visit(subnode);
            else if (xmlText = node as XMLTextNode) {
                if (xmlText.content is ExpressionNode) this.visit(ExpressionNode(xmlText.content));
            }
        }

        private function _visitStatement(node:Node, argument:* = undefined):* {
            var block:BlockNode,
                doStmt:DoStatementNode,
                dxnsStmt:DefaultXMLNamespaceStatementNode,
                exprStmt:ExpressionStatementNode,
                forInStmt:ForInStatementNode,
                forStmt:ForStatementNode,
                ifStmt:IfStatementNode,
                labeledStmt:LabeledStatementNode,
                returnStmt:ReturnNode,
                superStmt:SuperStatementNode,
                switchStmt:SwitchStatementNode,
                switchTypeStmt:SwitchTypeStatementNode,
                throwStmt:ThrowNode,
                tryStmt:TryStatementNode,
                whileStmt:WhileStatementNode,
                withStmt:WithStatementNode;

            var subdrtv:DirectiveNode,
                substmt:StatementNode,
                expr:ExpressionNode;

            if (block = node as BlockNode) for each (subdrtv in block.directives) this.visit(subdrtv);
            else if (doStmt = node as DoStatementNode) this.visit(doStmt.substatement), this.visit(doStmt.expression);
            else if (dxnsStmt = node as DefaultXMLNamespaceStatementNode) this.visit(dxnsStmt.expression);
            else if (exprStmt = node as ExpressionStatementNode) this.visit(exprStmt.expression);
            else if (forInStmt = node as ForInStatementNode) this.visit(forInStmt.left), this.visit(forInStmt.right), this.visit(forInStmt.substatement);
            else if (forStmt = node as ForStatementNode) {
                if (forStmt.expression1) this.visit(forStmt.expression1);
                if (forStmt.expression2) this.visit(forStmt.expression2);
                if (forStmt.expression3) this.visit(forStmt.expression3);
                this.visit(forStmt.substatement);
            }
            else if (ifStmt = node as IfStatementNode) {
                this.visit(ifStmt.expression);
                this.visit(ifStmt.consequent);
                if (ifStmt.alternative) this.visit(ifStmt.alternative);
            }
            else if (labeledStmt = node as LabeledStatementNode) this.visit(labeledStmt.substatement);
            else if (returnStmt = node as ReturnNode) {
                if (returnStmt.expression) this.visit(returnStmt.expression);
            }
            else if (superStmt = node as SuperStatementNode) for each (expr in superStmt.arguments) this.visit(expr);
            else if (switchStmt = node as SwitchStatementNode) {
                this.visit(switchStmt.discriminant);
                for each (var switchCase:SwitchCaseNode in switchStmt.caseNodes) {
                    if (switchCase.expression) this.visit(switchCase.expression);
                    if (switchCase.directives) for each (subdrtv in switchCase.directives) this.visit(subdrtv);
                }
            }
            else if (switchTypeStmt = node as SwitchTypeStatementNode) {
                this.visit(switchTypeStmt.discriminant);
                for each (var stCase:SwitchTypeCaseNode in switchTypeStmt.caseNodes) this.visit(stCase.pattern), this.visit(stCase.block);
            }
            else if (throwStmt = node as ThrowNode) this.visit(throwStmt.expression);
            else if (tryStmt = node as TryStatementNode) {
                this.visit(tryStmt.mainElement);
                if (tryStmt.catchElements) for each (var catchElement:CatchNode in tryStmt.catchElements) this.visit(catchElement.pattern), this.visit(catchElement.block);
                if (tryStmt.finallyElement) this.visit(tryStmt.finallyElement);
            }
            else if (whileStmt = node as WhileStatementNode) this.visit(whileStmt.expression), this.visit(whileStmt.substatement);
            else if (withStmt = node as WithStatementNode) this.visit(withStmt.expression), this.visit(withStmt.substatement);
        }
    }
}