package dsc.docGenerator {
    import flash.filesystem.*;
    import flash.utils.Dictionary;

    import dsc.*;
    import dsc.parsing.*;
    import dsc.parsing.ast.*;
    import dsc.semantics.*;
    import dsc.semantics.constants.*;
    import dsc.semantics.types.*;
    import dsc.util.PathHelpers;
    import dsc.util.StringHelpers;
    import dsc.verification.*;
    import dsc.docGenerator.htmlComponents.*;
    import dsc.docGenerator.tags.*;

    public final class DocGenerator {
        private var symbolToTagsMappings:Dictionary;
        private var verifyResult:VerificationResult;
        private const
            apiPackages:Array = [],
            apiProperties:Array = [],
            apiClasses:Array = [],
            apiEnums:Array = [],
            apiInterfaces:Array = [],
            apiFunctions:Array = [],
            apiFunctionCommons:Dictionary = new Dictionary;
        private var
            verifier:Verifier,
            semanticContext:Context;

        public function DocGenerator(compiler:Compiler, currentDirectory:File, options:*) {
            verifier = compiler.verifier;
            semanticContext = verifier.semanticContext;
            verifyResult = verifier.result;
            var programs:Array = compiler.onlyStdLibIncluded ? compiler.stdLibPrograms : compiler.latestIncludedPrograms;

            symbolToTagsMappings = new DocTagParser(verifier, apiPackages, apiProperties, apiFunctions, apiFunctionCommons, apiClasses, apiEnums, apiInterfaces).parse(programs);

            var outputDirectory:File = currentDirectory.resolvePath(options.output);
            outputDirectory.createDirectory();
            outputDirectory.resolvePath('res/img').createDirectory();
            var outputRootFiles:Array = ['bootstrap.min.css', 'bootstrap.min.js', 'jquery-3.5.1.slim.min.js', 'popper.min.js', 'style.css', 'script.js', 'res/img/glass.png', 'res/img/x.png'],
                path:String;
            for each (path in outputRootFiles)
                File.applicationDirectory.resolvePath(PathHelpers.join('res/docTemplate', path)).copyTo(outputDirectory.resolvePath(path), true);

            generateOverviewPage(outputDirectory);
            generatePackageDetailsPages(programs, outputDirectory);
            generateClassDetailsPages(programs, outputDirectory);
        }

        private function generateOverviewPage(outputDirectory:File):void {
            var rows:Array = [];
            for each (var packageObject:Symbol in apiPackages) {
                var docTags:* = symbolToTagsMappings[packageObject];
                rows.push([packageObject.fullyQualifiedName, '<tr><td>' + (packageObject.fullyQualifiedName ? '<span class="summaryTableItemName">' : '') + '<a href="' + linkOfItem(packageObject) + '">' + (packageObject.fullyQualifiedName ? packageObject.fullyQualifiedName : 'Top level') + '</a>' + (packageObject.fullyQualifiedName ? '</span>' : '') + '</td><td>' + (docTags && docTags.description ? firstSentenceOf(docTags.description.value) : '') + '</td></tr>']);
            }
            rows.sortOn('0');
            var table:String = '<table class="summaryTable"><tr><th>Package</th><th>Description</th></tr>' + rows.map(function(el) { return el[1] }).join('') + '</table>';
            var fileStream:FileStream = new FileStream;
            fileStream.open(outputDirectory.resolvePath('index.html'), 'write');
            fileStream.writeUTFBytes(HTMLRoot('', '', table, '.', 'overview', {}));
        }

        private function generatePackageDetailsPages(programs:Array, outputDirectory:File):void {
            var link:String,
                rootPath:String,
                packageObject:Symbol,
                packagePropertySummaries:Dictionary = new Dictionary,
                currentPackagePropertySummaries:Array,
                packageProperties:Dictionary = new Dictionary,
                currentPackageProperties:Array,
                packageFunctionSummaries:Dictionary = new Dictionary,
                currentPackageFunctionSummaries:Array,
                packageFunctions:Dictionary = new Dictionary,
                currentPackageFunctions:Array,
                packageClasses:Dictionary = new Dictionary,
                currentPackageClasses:Array,
                packageEnums:Dictionary = new Dictionary,
                currentPackageEnums:Array,
                packageInterfaces:Dictionary = new Dictionary,
                currentPackageInterfaces:Array;

            for each (var program:ProgramNode in programs) {
                for each (var pckgDefn:PackageDefinitionNode in program.packages) {
                    verifier.enterScript(pckgDefn.script);
                    verifier.scopeChain.enterFrame(verifyResult.symbolOf(pckgDefn.block));

                    packageObject = verifyResult.symbolOf(pckgDefn);
                    var docTags:* = symbolToTagsMappings[packageObject];
                    if (docTags && docTags.hidden) {
                        verifier.scopeChain.exitFrame();
                        verifier.exitScript();
                        continue;
                    }

                    link = linkOfItem(packageObject);
                    rootPath = linkToRootPath(link);

                    function findItems(directives:Array, onlyTypes:Boolean = false):void {
                        var fnDefn:FunctionDefinitionNode,
                            varDefn:VarDefinitionNode,
                            slot:Symbol,
                            type:Symbol,
                            descriptionPrefixes:Array;
                        for each (var drtv:DirectiveNode in directives) {
                            fnDefn = drtv as FunctionDefinitionNode;
                            if (fnDefn && !onlyTypes) {
                                var fn:Symbol = verifyResult.symbolOf(fnDefn);
                                docTags = symbolToTagsMappings[fn];
                                if (isAPISymbolHidden(fn.name, docTags))
                                    continue;
                                if (docTags)
                                    resolveCopyTag(docTags);

                                // Getter or setter
                                if (fn.ofVirtualSlot) {
                                    slot = fn.ofVirtualSlot;
                                    if ((slot.writeOnly && fn != slot.setter) || fn != slot.getter)
                                        continue;

                                    descriptionPrefixes = [];
                                    if (slot.readOnly) descriptionPrefixes.push('[read-only]');
                                    else if (slot.writeOnly) descriptionPrefixes.push('[write-only]');
                                    if (slot.name.qualifier is ReservedNamespaceConstant && slot.name.qualifier.namespaceType == 'protected') descriptionPrefixes.push('[protected]');

                                    currentPackagePropertySummaries ||= [];
                                    currentPackagePropertySummaries.push([fn.name.localName, '<tr><td><span class="summaryTableItemName"><a href="#' + fn.name.toString() + '">' + fn.name.toString() + '</a></span>:' + printTypeExp(slot.valueType, rootPath) + '</td><td>' + descriptionPrefixes.join(' ') + ' ' + (docTags && docTags.description ? firstSentenceOf(DescriptionTag(docTags.description).value) : '') + '</td></tr>']);
                                    currentPackageProperties ||= [];
                                    currentPackageProperties.push([fn.name.localName, StringHelpers.apply('<h3 id="$id">$title</h3>$description$example', {
                                        id: fn.name.toString(),
                                        title: fn.name.toString(),
                                        description: descriptionPrefixes.join(' ') + ' ' + (docTags && docTags.description ? DescriptionTag(docTags.description).value : ''),
                                        example: docTags && docTags.example ? '<h6>Example</h6>' + ExampleTag(docTags.example).description : ''
                                    })]);
                                }
                                else {
                                    descriptionPrefixes = [];
                                    if (fn.name.qualifier is ReservedNamespaceConstant && fn.name.qualifier.namespaceType == 'protected') descriptionPrefixes.push('[protected]');

                                    var params:Array,
                                        throws:Array;

                                    if (docTags && docTags.params) {
                                        params = [];
                                        for each (var paramTag:ParamTag in docTags.params)
                                            params.push('<li><code>' + paramTag.name + '</code> – ' + paramTag.description + '</li>');
                                    }

                                    if (docTags && docTags.throws) {
                                        throws = [];
                                        for each (var throwsTag:ThrowsTag in docTags.throws)
                                            throws.push('<li>' + printTypeExp(throwsTag.type, rootPath) + ' – ' + throwsTag.description + '</li>');
                                    }

                                    currentPackageFunctionSummaries ||= [];
                                    currentPackageFunctionSummaries.push([fn.name.localName, '<tr><td>' + summarizeMethodSignature(fn, rootPath) + '</td><td>' + descriptionPrefixes.join(' ') + ' ' + (docTags && docTags.description ? firstSentenceOf(DescriptionTag(docTags.description).value) : '') + '</td></tr>']);
                                    currentPackageFunctions ||= [];
                                    currentPackageFunctions.push([fn.name.localName, StringHelpers.apply('<h3 id="$id">$title()</h3>$description$params$throws$returnValue$example', {
                                        id: fn.name.toString() + '()',
                                        title: fn.name.toString(),
                                        description: descriptionPrefixes.join(' ') + ' ' + (docTags && docTags.description ? DescriptionTag(docTags.description).value : ''),
                                        params: params ? '<h6>Parameters</h6><ul>' + params.join('') + '</ul>' : '',
                                        throws: throws ? '<h6>Throws</h6><ul>' + throws.join('') + '</ul>' : '',
                                        returnValue: docTags && docTags['return'] ? '<h6>Return</h6>' + ReturnTag(docTags['return']).description : '',
                                        example: docTags && docTags.example ? '<h6>Example</h6>' + ExampleTag(docTags.example).description : ''
                                    })]);
                                }
                            }
                            else if (!onlyTypes && (varDefn = drtv as VarDefinitionNode)) {
                                var firstBinding:VarBindingNode = varDefn.bindings[0];
                                if (!(firstBinding.pattern is TypedIdNode))
                                    continue;
                                slot = verifyResult.symbolOf(firstBinding.pattern).target;
                                docTags = symbolToTagsMappings[slot];

                                if (isAPISymbolHidden(slot.name, docTags)) continue;

                                if (docTags)
                                    resolveCopyTag(docTags);
                                descriptionPrefixes = slot.readOnly ? ['[read-only]'] : [];
                                if (slot.name.qualifier is ReservedNamespaceConstant && slot.name.qualifier.namespaceType == 'protected') descriptionPrefixes.push('[protected]');

                                currentPackagePropertySummaries ||= [];
                                currentPackagePropertySummaries.push([slot.name.localName, '<tr><td><span class="summaryTableItemName"><a href="#' + slot.name.toString() + '">' + slot.name.toString() + '</a></span>:' + printTypeExp(slot.valueType, rootPath) + '</td><td>' + descriptionPrefixes.join(' ') + ' ' + (docTags && docTags.description ? firstSentenceOf(DescriptionTag(docTags.description).value) : '') + '</td></tr>']);
                                currentPackageProperties ||= [];
                                currentPackageProperties.push([slot.name.localName, StringHelpers.apply('<h3 id="$id">$title</h3>$description$example', {
                                    id: slot.name.toString(),
                                    title: slot.name.toString(),
                                    description: descriptionPrefixes.join(' ') + ' ' + (docTags && docTags.description ? DescriptionTag(docTags.description).value : ''),
                                    example: docTags && docTags.example ? '<h6>Example</h6>' + ExampleTag(docTags.example).description : ''
                                })]);
                            }
                            else if (drtv is ClassDefinitionNode) {
                                var classDefn:ClassDefinitionNode = ClassDefinitionNode(drtv);
                                type = verifyResult.symbolOf(classDefn);
                                docTags = symbolToTagsMappings[type];
                                if (isAPISymbolHidden(type.name, docTags)) continue;

                                if (docTags) resolveCopyTag(docTags);

                                currentPackageClasses ||= [];
                                currentPackageClasses.push([nonPackageQualifiedNameOf(type), '<tr><td><span class="summaryTableItemName"><a href="' + PathHelpers.join(rootPath, linkOfItem(type)) + '">' + nonPackageQualifiedNameOf(type) + '</a></span></td><td>' + (docTags && docTags.description ? firstSentenceOf(DescriptionTag(docTags.description).value) : '') + '</td></tr>']);

                                verifier.scopeChain.enterFrame(verifyResult.symbolOf(classDefn.block));
                                findItems(classDefn.block.directives, true);
                                verifier.scopeChain.exitFrame();
                            }
                            else if (drtv is EnumDefinitionNode) {
                                var enumDefn:EnumDefinitionNode = EnumDefinitionNode(drtv);
                                type = verifyResult.symbolOf(enumDefn);
                                docTags = symbolToTagsMappings[type];
                                if (isAPISymbolHidden(type.name, docTags)) continue;

                                if (docTags) resolveCopyTag(docTags);

                                currentPackageEnums ||= [];
                                currentPackageEnums.push([nonPackageQualifiedNameOf(type), '<tr><td><span class="summaryTableItemName"><a href="' + PathHelpers.join(rootPath, linkOfItem(type)) + '">' + nonPackageQualifiedNameOf(type) + '</a></span></td><td>' + (docTags && docTags.description ? firstSentenceOf(DescriptionTag(docTags.description).value) : '') + '</td></tr>']);

                                verifier.scopeChain.enterFrame(verifyResult.symbolOf(enumDefn.block));
                                findItems(enumDefn.block.directives, true);
                                verifier.scopeChain.exitFrame();
                            }
                            else if (drtv is InterfaceDefinitionNode) {
                                var itrfcDefn:InterfaceDefinitionNode = InterfaceDefinitionNode(drtv);
                                type = verifyResult.symbolOf(itrfcDefn);
                                docTags = symbolToTagsMappings[type];
                                if (isAPISymbolHidden(type.name, docTags)) continue;

                                if (docTags) resolveCopyTag(docTags);

                                currentPackageInterfaces ||= [];
                                currentPackageInterfaces.push([nonPackageQualifiedNameOf(type), '<tr><td><span class="summaryTableItemName"><a href="' + PathHelpers.join(rootPath, linkOfItem(type)) + '">' + nonPackageQualifiedNameOf(type) + '</a></span></td><td>' + (docTags && docTags.description ? firstSentenceOf(DescriptionTag(docTags.description).value) : '') + '</td></tr>']);

                                verifier.scopeChain.enterFrame(verifyResult.symbolOf(itrfcDefn.block));
                                findItems(itrfcDefn.block.directives, true);
                                verifier.scopeChain.exitFrame();
                            }
                            else if (drtv is IncludeDirectiveNode && IncludeDirectiveNode(drtv).subdirectives)
                                verifier.enterScript(IncludeDirectiveNode(drtv).subscript),
                                findItems(IncludeDirectiveNode(drtv).subdirectives, onlyTypes),
                                verifier.exitScript();
                        }
                    }

                    findItems(pckgDefn.block.directives);

                    if (currentPackageFunctionSummaries)
                        packageFunctionSummaries[packageObject] = (packageFunctionSummaries[packageObject] || []).concat(currentPackageFunctionSummaries),
                        packageFunctions[packageObject] = (packageFunctions[packageObject] || []).concat(currentPackageFunctions);

                    if (currentPackageProperties)
                        packagePropertySummaries[packageObject] = (packagePropertySummaries[packageObject] || []).concat(currentPackagePropertySummaries),
                        packageProperties[packageObject] = (packageProperties[packageObject] || []).concat(currentPackageProperties);

                    if (currentPackageClasses)
                        packageClasses[packageObject] = (packageClasses[packageObject] || []).concat(currentPackageClasses);

                    if (currentPackageEnums)
                        packageEnums[packageObject] = (packageEnums[packageObject] || []).concat(currentPackageEnums);

                    if (currentPackageInterfaces)
                        packageInterfaces[packageObject] = (packageInterfaces[packageObject] || []).concat(currentPackageInterfaces);

                    verifier.scopeChain.exitFrame();
                    verifier.exitScript();
                }

                for each (packageObject in apiPackages) {
                    var content:Array = [],
                        postContent:Array = [];

                    content.push('<h2>' + (packageObject.fullyQualifiedName ? 'Package ' + packageObject.fullyQualifiedName : 'Top level package') + '</h2>');
                    if (docTags && docTags.description)
                        content.push(docTags.description.value);
                    if (docTags && docTags.example)
                        content.push('<h4>Example</h4>' + ExampleTag(docTags.example).description);
                    content.push('<br>');

                    currentPackageProperties = packageProperties[packageObject];
                    currentPackagePropertySummaries = packagePropertySummaries[packageObject];

                    if (currentPackageProperties && currentPackageProperties.length > 0)
                        content.push('<table class="summaryTable"><caption>Properties</caption><tr><th>Property</th><th>Description</th></tr>'),
                        currentPackageProperties.sortOn('0'),
                        currentPackagePropertySummaries.sortOn('0'),
                        content.push(currentPackagePropertySummaries.map(function(el) { return el[1] }).join('\n')),
                        content.push('</table><br>'),
                        postContent.push(currentPackageProperties.map(function(el) { return el[1] }).join('\n'));

                    currentPackageFunctionSummaries = packageFunctionSummaries[packageObject];
                    currentPackageFunctions = packageFunctions[packageObject];

                    if (currentPackageFunctionSummaries && currentPackageFunctionSummaries.length > 0)
                        content.push('<table class="summaryTable"><caption>Functions</caption><tr><th>Function</th><th>Description</th></tr>'),
                        currentPackageFunctionSummaries.sortOn('0'),
                        currentPackageFunctions.sortOn('0'),
                        content.push(currentPackageFunctionSummaries.map(function(el) { return el[1] }).join('\n')),
                        content.push('</table><br>'),
                        postContent.push(currentPackageFunctions.map(function(el) { return el[1] }).join('\n'));

                    currentPackageClasses = packageClasses[packageObject];
                    currentPackageEnums = packageEnums[packageObject];
                    currentPackageInterfaces = packageInterfaces[packageObject];

                    if (currentPackageClasses && currentPackageClasses.length > 0)
                        content.push('<table class="summaryTable"><caption>Classes</caption><tr><th>Class</th><th>Description</th></tr>'),
                        currentPackageClasses.sortOn('0'),
                        content.push(currentPackageClasses.map(function(el) { return el[1] }).join('\n')),
                        content.push('</table><br>');

                    if (currentPackageEnums && currentPackageEnums.length > 0)
                        content.push('<table class="summaryTable"><caption>Enums</caption><tr><th>Enum</th><th>Description</th></tr>'),
                        currentPackageEnums.sortOn('0'),
                        content.push(currentPackageEnums.map(function(el) { return el[1] }).join('\n')),
                        content.push('</table><br>');

                    if (currentPackageInterfaces && currentPackageInterfaces.length > 0)
                        content.push('<table class="summaryTable"><caption>Interfaces</caption><tr><th>Interface</th><th>Description</th></tr>'),
                        currentPackageInterfaces.sortOn('0'),
                        content.push(currentPackageInterfaces.map(function(el) { return el[1] }).join('\n')),
                        content.push('</table><br>');

                    link = linkOfItem(packageObject);
                    rootPath = linkToRootPath(link);

                    var fileStream:FileStream = new FileStream;
                    fileStream.open(outputDirectory.resolvePath(link), 'write');
                    fileStream.writeUTFBytes(HTMLRoot('', '', content.join('\n') + postContent.join('\n'), rootPath, 'package', { }));
                    fileStream.close();
                }
            }
        }

        private function generateClassDetailsPages(programs:Array, outputDirectory:File):void {
            var packageLink:String,
                rootPath:String;

            var constantSummaries:Array,
                propertySummaries:Array,
                methodSummaries:Array,
                constantContents:Array,
                propertyContents:Array,
                methodContents:Array;

            for each (var program:ProgramNode in programs) {
                for each (var pckgDefn:PackageDefinitionNode in program.packages) {
                    verifier.enterScript(pckgDefn.script);
                    verifier.scopeChain.enterFrame(verifyResult.symbolOf(pckgDefn.block));

                    var packageObject:Symbol = verifyResult.symbolOf(pckgDefn);
                    var docTags:* = symbolToTagsMappings[packageObject];
                    if (docTags && docTags.hidden) {
                        verifier.scopeChain.exitFrame();
                        verifier.exitScript();
                        continue;
                    }

                    packageLink = linkOfItem(packageObject);
                    findClasses(pckgDefn.block.directives);

                    verifier.scopeChain.exitFrame();
                    verifier.exitScript();
                }
            }

            function findClasses(directives:Array):void {
                var classDefn:ClassDefinitionNode,
                    enumDefn:EnumDefinitionNode,
                    itrfcDefn:InterfaceDefinitionNode,
                    content:Array;
                for each (var drtv:DirectiveNode in directives) {
                    if (classDefn = drtv as ClassDefinitionNode) {
                        var type:Symbol = verifyResult.symbolOf(drtv);
                        var docTags:* = symbolToTagsMappings[type];
                        if (isAPISymbolHidden(type.name, docTags))
                            continue;

                        verifier.scopeChain.enterFrame(verifyResult.symbolOf(classDefn.block));

                        propertySummaries = [];
                        methodSummaries = [];
                        propertyContents = [];
                        methodContents = [];

                        var link:String = linkOfItem(type);
                        rootPath = linkToRootPath(link);

                        findClassSubdecl(classDefn.block.directives);

                        if (docTags)
                            resolveCopyTag(docTags);

                        verifier.scopeChain.exitFrame();

                        const classHierarchy:Array = [];
                        var class2:Symbol;
                        for (class2 = type; class2; class2 = class2.superType)
                            classHierarchy.push(printTypeExp(class2, rootPath));

                        const subclasses:Array = [];
                        for each (class2 in type.subclasses)
                            subclasses.push(printTypeExp(class2, rootPath));

                        const implementsInterfaces:Array = [];
                        var implementedInterface:Symbol;
                        for each (implementedInterface in type.implementsInterfaces)
                            implementsInterfaces.push(printTypeExp(implementedInterface, rootPath));

                        content = [
                            '<h2>Class ' + nonPackageQualifiedNameOf(type) + '</h2>' +
                            '<b>Package:</b> ' + hostPackageNameOf(type) +
                            '<br><b>Inheritance:</b> ' + classHierarchy.join(' > ') +
                            (subclasses.length > 0 ? '<br><b>Subclasses:</b> ' + subclasses.join(', ') : '') +
                            (implementsInterfaces.length > 0 ? '<br><b>Implements interfaces:</b> ' + implementsInterfaces.join(', ') : '') +
                            '<br>' +
                            (type.classFlags & ClassFlags.UNION ? '<br>[union]' : type.classFlags & ClassFlags.PRIMITIVE ? '<br>[primitive]' : '') +
                            (docTags && docTags.description ? DescriptionTag(docTags.description).value : type.classFlags & ClassFlags.UNION || type.classFlags & ClassFlags.PRIMITIVE ? '<br>' : '') +
                            '<br>'
                        ];

                        if (propertySummaries.length > 0)
                            content.push('<table class="summaryTable"><caption>Properties</caption><tr><th>Property</th><th>Description</th></tr>'),
                            propertySummaries.sortOn('0'),
                            content.push(propertySummaries.map(function(el) { return el[1] }).join('\n')),
                            content.push('</table><br>');
                        if (methodSummaries.length > 0)
                            content.push('<table class="summaryTable"><caption>Methods</caption><tr><th>Method</th><th>Description</th></tr>'),
                            methodSummaries.sortOn('0'),
                            content.push(methodSummaries.map(function(el) { return el[1] }).join('\n')),
                            content.push('</table><br>');
                        if (propertyContents.length > 0)
                            propertyContents.sortOn('0'),
                            content.push(propertyContents.map(function(el) { return el[1] }).join(''));
                        if (methodContents.length > 0)
                            methodContents.sortOn('0'),
                            content.push(methodContents.map(function(el) { return el[1] }).join(''));

                        var fileStream:FileStream = new FileStream;
                        fileStream.open(outputDirectory.resolvePath(link), 'write');
                        fileStream.writeUTFBytes(HTMLRoot('', '', content.join('\n'), rootPath, 'class', { overview: 'index.html', 'package': packageLink, 'class': link }));
                        fileStream.close();
                    }
                    if (enumDefn = drtv as EnumDefinitionNode) {
                        var type:Symbol = verifyResult.symbolOf(drtv);
                        var docTags:* = symbolToTagsMappings[type];
                        if (isAPISymbolHidden(type.name, docTags))
                            continue;

                        verifier.scopeChain.enterFrame(verifyResult.symbolOf(enumDefn.block));

                        constantSummaries = [];
                        propertySummaries = [];
                        methodSummaries = [];
                        constantContents = [];
                        propertyContents = [];
                        methodContents = [];

                        verifier.scopeChain.exitFrame();
                        var link:String = linkOfItem(type);
                        rootPath = linkToRootPath(link);

                        findClassSubdecl(enumDefn.block.directives);

                        if (docTags)
                            resolveCopyTag(docTags);

                        content = [
                            '<h2>Enum ' + nonPackageQualifiedNameOf(type) + '</h2>' +
                            '<b>Package:</b> ' + hostPackageNameOf(type) +
                            '<br><b>Wraps:</b> ' + printTypeExp(type.wrapsType, rootPath) +
                            ((type.enumFlags & EnumFlags.FLAGS) ? '<br>[flags]' : '') +
                            '<br>' +
                            (docTags && docTags.description ? DescriptionTag(docTags.description).value : '') +
                            '<br>'
                        ];

                        if (constantSummaries.length > 0)
                            content.push('<table class="summaryTable"><caption>Constants</caption><tr><th>Constant</th><th>Description</th></tr>'),
                            constantSummaries.sortOn('0'),
                            content.push(constantSummaries.map(function(el) { return el[1] }).join('\n')),
                            content.push('</table><br>');
                        if (propertySummaries.length > 0)
                            content.push('<table class="summaryTable"><caption>Properties</caption><tr><th>Property</th><th>Description</th></tr>'),
                            propertySummaries.sortOn('0'),
                            content.push(propertySummaries.map(function(el) { return el[1] }).join('\n')),
                            content.push('</table><br>');
                        if (methodSummaries.length > 0)
                            content.push('<table class="summaryTable"><caption>Methods</caption><tr><th>Method</th><th>Description</th></tr>'),
                            methodSummaries.sortOn('0'),
                            content.push(methodSummaries.map(function(el) { return el[1] }).join('\n')),
                            content.push('</table><br>');
                        if (constantContents.length > 0)
                            constantContents.sortOn('0'),
                            content.push(constantContents.map(function(el) { return el[1] }).join(''));
                        if (propertyContents.length > 0)
                            propertyContents.sortOn('0'),
                            content.push(propertyContents.map(function(el) { return el[1] }).join(''));
                        if (methodContents.length > 0)
                            methodContents.sortOn('0'),
                            content.push(methodContents.map(function(el) { return el[1] }).join(''));

                        var fileStream:FileStream = new FileStream;
                        fileStream.open(outputDirectory.resolvePath(link), 'write');
                        fileStream.writeUTFBytes(HTMLRoot('', '', content.join('\n'), rootPath, 'class', { overview: 'index.html', 'package': packageLink, 'class': link }));
                        fileStream.close();
                    }
                    if (itrfcDefn = drtv as InterfaceDefinitionNode) {
                        var type:Symbol = verifyResult.symbolOf(drtv);
                        var docTags:* = symbolToTagsMappings[type];
                        if (isAPISymbolHidden(type.name, docTags))
                            continue;

                        verifier.scopeChain.enterFrame(verifyResult.symbolOf(itrfcDefn.block));

                        var link:String = linkOfItem(type);
                        rootPath = linkToRootPath(link);
                        propertySummaries = [];
                        methodSummaries = [];
                        propertyContents = [];
                        methodContents = [];
                        findClassSubdecl(itrfcDefn.block.directives);

                        verifier.scopeChain.exitFrame();

                        if (docTags)
                            resolveCopyTag(docTags);

                        const extendsInterfaces:Array = []
                            , subInterfaces:Array = []
                            , implementors:Array = [];
                        var itrfc2:Symbol;
                        for each (itrfc2 in type.superInterfaces)
                            extendsInterfaces.push(printTypeExp(itrfc2, rootPath));
                        for each (itrfc2 in type.subInterfaces)
                            subInterfaces.push(printTypeExp(itrfc2, rootPath));
                        for each (var implementor:Symbol in type.implementors)
                            implementors.push(printTypeExp(implementor, rootPath));

                        content = [
                            '<h2>Interface ' + nonPackageQualifiedNameOf(type) + '</h2>' +
                            '<b>Package:</b> ' + hostPackageNameOf(type) +
                            (extendsInterfaces.length > 0 ? '<br><b>Extends:</b> ' + extendsInterfaces.join(', ') : '') +
                            (subInterfaces.length > 0 ? '<br><b>Sub-interfaces:</b> ' + subInterfaces.join(', ') : '') +
                            (implementors.length > 0 ? '<br><b>Implementors:</b> ' + implementors.join(', ') : '') +
                            '<br>' +
                            (docTags && docTags.description ? DescriptionTag(docTags.description).value : '') +
                            '<br>'
                        ];

                        if (propertySummaries.length > 0)
                            content.push('<table class="summaryTable"><caption>Properties</caption><tr><th>Property</th><th>Description</th></tr>'),
                            propertySummaries.sortOn('0'),
                            content.push(propertySummaries.map(function(el) { return el[1] }).join('\n')),
                            content.push('</table><br>');
                        if (methodSummaries.length > 0)
                            content.push('<table class="summaryTable"><caption>Methods</caption><tr><th>Method</th><th>Description</th></tr>'),
                            methodSummaries.sortOn('0'),
                            content.push(methodSummaries.map(function(el) { return el[1] }).join('\n')),
                            content.push('</table><br>');
                        if (propertyContents.length > 0)
                            propertyContents.sortOn('0'),
                            content.push(propertyContents.map(function(el) { return el[1] }).join(''));
                        if (methodContents.length > 0)
                            methodContents.sortOn('0'),
                            content.push(methodContents.map(function(el) { return el[1] }).join(''));

                        var fileStream:FileStream = new FileStream;
                        fileStream.open(outputDirectory.resolvePath(link), 'write');
                        fileStream.writeUTFBytes(HTMLRoot('', '', content.join('\n'), rootPath, 'class', { overview: 'index.html', 'package': packageLink, 'class': link }));
                        fileStream.close();
                    }
                    else if (drtv is IncludeDirectiveNode && IncludeDirectiveNode(drtv).subdirectives)
                        verifier.enterScript(IncludeDirectiveNode(drtv).subscript),
                        findClasses(IncludeDirectiveNode(drtv).subdirectives),
                        verifier.exitScript();
                }
            }

            function findClassSubdecl(directives:Array):void {
                var varDefn:VarDefinitionNode,
                    fnDefn:FunctionDefinitionNode,
                    descriptionPrefixes:Array,
                    slot:Symbol,
                    docTags:*;

                for each (var drtv:DirectiveNode in directives) {
                    if (varDefn = drtv as VarDefinitionNode) {
                        var firstBinding:VarBindingNode = varDefn.bindings[0];
                        if (!(firstBinding.pattern is TypedIdNode))
                            continue;
                        slot = verifyResult.symbolOf(firstBinding.pattern).target;
                        docTags = symbolToTagsMappings[slot];

                        if (isAPISymbolHidden(slot.name, docTags)) continue;

                        if (docTags)
                            resolveCopyTag(docTags);

                        if (slot.enumPairAssociation) {
                            descriptionPrefixes = ['[static]'];
                            constantSummaries.push([slot.name.localName, '<tr><td><span class="summaryTableItemName"><a href="#' + slot.name.toString() + '">' + slot.name.toString() + '</a></span>:' + printTypeExp(slot.valueType, rootPath) + '</td><td>' + descriptionPrefixes.join(' ') + ' ' + (docTags && docTags.description ? firstSentenceOf(DescriptionTag(docTags.description).value) : '') + '</td></tr>']);
                            constantContents.push([slot.name.localName, StringHelpers.apply('<h3 id="$id">$title</h3>$description$example', {
                                id: slot.name.toString(),
                                title: slot.name.toString(),
                                description: descriptionPrefixes.join(' ') + ' ["' + slot.enumPairAssociation[0] + '", ' + slot.enumPairAssociation[1].valueOf().toString() + '] ' + (docTags && docTags.description ? DescriptionTag(docTags.description).value : ''),
                                example: docTags && docTags.example ? '<h6>Example</h6>' + ExampleTag(docTags.example).description : ''
                            })]);
                        }
                        else {
                            descriptionPrefixes = slot.readOnly ? ['[read-only]'] : [];
                            if (slot.name.qualifier is ReservedNamespaceConstant && slot.name.qualifier.namespaceType == 'protected') descriptionPrefixes.push('[protected]');
                            if (varDefn.modifiers & Modifiers.STATIC) descriptionPrefixes.push('[static]');
                            if (varDefn.modifiers & Modifiers.OVERRIDE) descriptionPrefixes.push('[override]');

                            propertySummaries.push([slot.name.localName, '<tr><td><span class="summaryTableItemName"><a href="#' + slot.name.toString() + '">' + slot.name.toString() + '</a></span>:' + printTypeExp(slot.valueType, rootPath) + '</td><td>' + descriptionPrefixes.join(' ') + ' ' + (docTags && docTags.description ? firstSentenceOf(DescriptionTag(docTags.description).value) : '') + '</td></tr>']);
                            propertyContents.push([slot.name.localName, StringHelpers.apply('<h3 id="$id">$title</h3>$description$example', {
                                id: slot.name.toString(),
                                title: slot.name.toString(),
                                description: descriptionPrefixes.join(' ') + ' ' + (docTags && docTags.description ? DescriptionTag(docTags.description).value : ''),
                                example: docTags && docTags.example ? '<h6>Example</h6>' + ExampleTag(docTags.example).description : ''
                            })]);
                        }
                    }
                    else if (fnDefn = drtv as FunctionDefinitionNode) {
                        var fn:Symbol = verifyResult.symbolOf(fnDefn);
                        docTags = symbolToTagsMappings[fn];
                        if (isAPISymbolHidden(fn.name, docTags))
                            continue;
                        if (docTags)
                            resolveCopyTag(docTags);

                        // Getter or setter
                        if (fn.ofVirtualSlot) {
                            slot = fn.ofVirtualSlot;
                            if ((slot.writeOnly && fn != slot.setter) || fn != slot.getter)
                                continue;

                            descriptionPrefixes = [];
                            if (slot.readOnly) descriptionPrefixes.push('[read-only]');
                            else if (slot.writeOnly) descriptionPrefixes.push('[write-only]');
                            if (slot.name.qualifier is ReservedNamespaceConstant && slot.name.qualifier.namespaceType == 'protected') descriptionPrefixes.push('[protected]');
                            if (fnDefn.modifiers & Modifiers.STATIC) descriptionPrefixes.push('[static]');
                            if (fnDefn.modifiers & Modifiers.OVERRIDE) descriptionPrefixes.push('[override]');

                            propertySummaries.push([fn.name.localName, '<tr><td><span class="summaryTableItemName"><a href="#' + fn.name.toString() + '">' + fn.name.toString() + '</a></span>:' + printTypeExp(slot.valueType, rootPath) + '</td><td>' + descriptionPrefixes.join(' ') + ' ' + (docTags && docTags.description ? firstSentenceOf(DescriptionTag(docTags.description).value) : '') + '</td></tr>']);
                            propertyContents.push([fn.name.localName, StringHelpers.apply('<h3 id="$id">$title</h3>$description$example', {
                                id: fn.name.toString(),
                                title: fn.name.toString(),
                                description: descriptionPrefixes.join(' ') + ' ' + (docTags && docTags.description ? DescriptionTag(docTags.description).value : ''),
                                example: docTags && docTags.example ? '<h6>Example</h6>' + ExampleTag(docTags.example).description : ''
                            })]);
                        }
                        else {
                            descriptionPrefixes = [];
                            if (fn.name.qualifier is ReservedNamespaceConstant && fn.name.qualifier.namespaceType == 'protected') descriptionPrefixes.push('[protected]');
                            if (fnDefn.modifiers & Modifiers.STATIC) descriptionPrefixes.push('[static]');
                            if (fnDefn.modifiers & Modifiers.OVERRIDE) descriptionPrefixes.push('[override]');

                            var params:Array,
                                throws:Array;

                            if (docTags && docTags.params) {
                                params = [];
                                for each (var paramTag:ParamTag in docTags.params)
                                    params.push('<li><code>' + paramTag.name + '</code> – ' + paramTag.description + '</li>');
                            }

                            if (docTags && docTags.throws) {
                                throws = [];
                                for each (var throwsTag:ThrowsTag in docTags.throws)
                                    throws.push('<li>' + printTypeExp(throwsTag.type, rootPath) + ' – ' + throwsTag.description + '</li>');
                            }

                            apiFunctionCommons[fn] = fnDefn.common;

                            methodSummaries.push([fn.name.localName, '<tr><td>' + summarizeMethodSignature(fn, rootPath, !!(fnDefn.common.flags & FunctionFlags.CONSTRUCTOR)) + '</td><td>' + descriptionPrefixes.join(' ') + ' ' + (docTags && docTags.description ? firstSentenceOf(DescriptionTag(docTags.description).value) : '') + '</td></tr>']);
                            methodContents.push([fn.name.localName, StringHelpers.apply('<h3 id="$id">$title()</h3>$description$params$throws$returnValue$example', {
                                id: fn.name.toString() + '()',
                                title: fn.name.toString(),
                                description: descriptionPrefixes.join(' ') + ' ' + (docTags && docTags.description ? DescriptionTag(docTags.description).value : ''),
                                params: params ? '<h6>Parameters</h6><ul>' + params.join('') + '</ul>' : '',
                                throws: throws ? '<h6>Throws</h6><ul>' + throws.join('') + '</ul>' : '',
                                returnValue: docTags && docTags['return'] ? '<h6>Return</h6>' + ReturnTag(docTags['return']).description : '',
                                example: docTags && docTags.example ? '<h6>Example</h6>' + ExampleTag(docTags.example).description : ''
                            })]);
                        }
                    }
                    else if (drtv is IncludeDirectiveNode && IncludeDirectiveNode(drtv).subdirectives)
                        verifier.enterScript(IncludeDirectiveNode(drtv).subscript),
                        findClassSubdecl(IncludeDirectiveNode(drtv).subdirectives),
                        verifier.exitScript();
                }
            }
        }

        private function hostPackageNameOf(item:Symbol):String {
            for (var subItem:Symbol = item.definedIn; subItem; subItem = subItem.definedIn)
                if (subItem is Package)
                    return subItem.fullyQualifiedName;
            return '';
        }

        private function nonPackageQualifiedNameOf(item:Symbol):String {
            var r:Array = [item.name.toString()];
            for (var subItem:Symbol = item.definedIn; subItem; subItem = subItem.definedIn) {
                if (subItem is Package)
                    break;
                r.unshift(subItem.name + '.');
            }
            return r.join('');
        }

        private function linkOfItem(item:Symbol):String {
            if (item is Package) {
                if (item.fullyQualifiedName.length == 0)
                    return 'package-details.html';
                return item.fullyQualifiedName.replace(/\./g, '/') + '/package-details.html';
            }
            else if (item is Type) {
                var r:Array = [item.name.toString() + '.html'];
                for (var subItem:Symbol = item.definedIn; subItem; subItem = subItem.definedIn) {
                    if (subItem is Package && subItem.fullyQualifiedName.length > 0) {
                        r.unshift(subItem.fullyQualifiedName.replace(/\./g, '/') + '/');
                        break;
                    }
                    r.unshift(subItem.name + '.');
                }
                return r.join('');
            }
            return '';
        }

        private function linkToRootPath(link:String):String {
            var s:Array = link.split('/');
            s.pop();
            return s.map(function(s) { return '..' }).join('/');
        }

        private function firstSentenceOf(html:String):String {
            var m:* = html.match(/\.( |$|\n*<)/);
            html = m ? html.slice(0, m.index + 1) : html;
            html = html.replace(/^<p>/, '');
            return html;
        }

        private function resolveCopyTag(inputOutput:*):void {
            while (inputOutput.copy) {
                var copyTag:CopyTag = CopyTag(inputOutput.copy);
                delete inputOutput.copy;
                var referred:* = copyTag.item ? symbolToTagsMappings[copyTag.item] : null;
                if (referred)
                    for (var key:String in referred)
                        inputOutput[key] = referred[key];
            }
        }

        private function summarizeMethodSignature(slot:Symbol, rootPath:String, constructor:Boolean = false):String {
            var r:Array = [],
                common:FunctionCommonNode = apiFunctionCommons[slot],
                index:uint,
                binding:VarBindingNode;
            index = 0;
            for each (binding in common.params)
                r.push(summarizePattern(binding.pattern) + ':' + printTypeExp(slot.methodSignature.params[index], rootPath)),
                ++index;
            index = 0;
            for each (binding in common.optParams)
                r.push(summarizePattern(binding.pattern) + ':' + printTypeExp(slot.methodSignature.optParams[index], rootPath) + ' = '
                        + printConstant(binding.pattern is TypedIdNode ? verifyResult.symbolOf(binding.pattern).value : verifyResult.symbolOf(binding.pattern))),
                ++index;
            if (common.rest)
                r.push('...' + common.rest.name);
            var returnSummary:String = !constructor ? ':' + printTypeExp(slot.methodSignature.result, rootPath) : '';
            return StringHelpers.apply('<span class="summaryTableItemName"><a href="#$1()">$1</a></span> ($2)$3', slot.name.toString(), r.join(', '), returnSummary);
        }

        private function summarizePattern(pattern:Node):String {
            var arrayLiteral:ArrayLiteralNode,
                objectLiteral:ObjectLiteralNode,
                args:Array,
                arg:Node;
            if (pattern is TypedIdNode)
                return TypedIdNode(pattern).name;
            else if (pattern is SimpleIdNode)
                return SimpleIdNode(pattern).name;
            else if (arrayLiteral = pattern as ArrayLiteralNode) {
                args = [];
                for each (arg in arrayLiteral.elements) {
                    if (arg is SpreadOperatorNode)
                        args.push('...' + summarizePattern(SpreadOperatorNode(arg).expression));
                    else args.push(summarizePattern(arg));
                }
                return '[' + args.join(', ') +']';
            }
            else if (objectLiteral = pattern as ObjectLiteralNode) {
                args = [];
                for each (var fieldOrSpread:Node in objectLiteral) {
                    if (fieldOrSpread is SpreadOperatorNode) {
                        args.push('...' + summarizePattern(SpreadOperatorNode(fieldOrSpread).expression));
                        continue;
                    }
                    var field:ObjectFieldNode = ObjectFieldNode(fieldOrSpread);
                    if (field.value)
                        args.push(SimpleIdNode(field.key).name + ': ' + summarizePattern(field.value));
                    else args.push(SimpleIdNode(field.key).name);
                }
                return '{' + args.join(', ') + '}';
            }
            return '';
        }

        private function printTypeExp(type:Symbol, rootPath:String):String {
            var arg:Symbol,
                args:Array;
            if (type is AnyType) return '*';
            else if (type is VoidType) return 'void';
            else if (type is ClassType || type is EnumType || type is InterfaceType) {
                var inAPI:Boolean = type is ClassType ? apiClasses.indexOf(type) != -1 :
                    type is EnumType ? apiEnums.indexOf(type) != -1 :
                    type is InterfaceType ? apiInterfaces.indexOf(type) != -1 : false;
                if (inAPI)
                    return '<a href="' + PathHelpers.join(rootPath, linkOfItem(type)) + '">' + type.name.toString() + '</a>';
                else return type.fullyQualifiedName;
            }
            else if (type is InstantiatedType) {
                var origin:String = printTypeExp(type.originalDefinition, rootPath),
                    allWildcard:Boolean = true;
                args = [];
                for each (arg in type.arguments) {
                    if (!(arg is AnyType))
                        allWildcard = false;
                    args.push(printTypeExp(arg, rootPath));
                }
                return allWildcard ? origin : origin + '.<' + args.join(', ') + '>';
            }
            else if (type is NullableType)
                return '+' + printTypeExp(type.wrapsType, rootPath);
            else if (type is TupleType) {
                args = [];
                for each (arg in type.tupleElements)
                    args.push(printTypeExp(arg, rootPath));
                return '[' + args.join(', ') + ']';
            }
            return '';
        }

        private function printConstant(constant:Symbol):String {
            if (constant is BigIntConstant ||
                constant is BooleanConstant ||
                constant is NumberConstant
            )
                return constant.valueOf().toString();
            if (constant is StringConstant)
                return '“' + constant.valueOf().toString().replace(/"/g, '"') + '”';
            if (constant is CharConstant)
                return '“' + String.fromCharCode(constant.valueOf()) + '”';
            if (constant is UndefinedConstant)
                return 'undefined';
            if (constant is NullConstant)
                return 'null';
            if (constant is ReservedNamespaceConstant)
                return constant.namespaceType.toString();
            if (constant is EnumConstant) {
                var enumType:Symbol = constant.valueType.escapeType(),
                    constantName:String;
                var constants = enumType.enumConstants,
                    r:Array = [];
                if (enumType.enumFlags & EnumFlags.FLAGS) {
                    for (constantName in constants)
                        if (constant.enumContains(enumType.getEnumConstant(constants[constantName])))
                            r.push('“' + constantName + '”');
                    return r.length > 1 ? '[' + r.join(', ') + ']' : r.length == 1 ? r[0] : 'undefined';
                }
                else
                    for (constantName in constants)
                        if (constant.valueOf() == constants[constantName])
                            return '“' + constantName + '”';
                return 'undefined';
            }
            return '?';
        }

        private function isAPISymbolHidden(name:Symbol, constraints:* = null):Boolean {
            return (constraints && constraints.hidden) || (name ? (name.qualifier is ReservedNamespaceConstant && (name.qualifier.namespaceType == 'private' || name.qualifier.namespaceType == 'internal')) : false) || (name ? name.qualifier == semanticContext.statics.proxyNamespace : false);
        }
    }
}