package dsc {
    import flash.filesystem.*;
    import flash.utils.ByteArray;

    import com.siteblade.intl.*;
    import com.siteblade.util.CharArray;
    import com.siteblade.util.Promise;

    import dsc.*;
    import dsc.semantics.*;
    import dsc.parsing.*;
    import dsc.parsing.ast.*;
    import dsc.verification.*;

    public final class Compiler {
        public var verifier:Verifier;
        public const sourceFiles:Array = [];
        public const scripts:Array = [];
        public const programs:Array = [];
        private var _valid:Boolean = true;

        private var _skipLength:uint;
        private var _globalObjectProgramsLength:uint;

        public function Compiler(options:*, currentDirectory:File) {
            verifier = new Verifier(options.config ? _loadConfigFile(currentDirectory.resolvePath(options.config)) : null);

            compileGlobalObjects();

            var sourcePath:String;

            // Library sources
            for each (sourcePath in options.includeLibrarySources) addSources(currentDirectory.resolvePath(sourcePath));
            for each (sourcePath in options.excludeLibrarySources) excludeSources(currentDirectory.resolvePath(sourcePath));

            parse();
            if (valid) verify();
            skipProgramsLength(latestIncludedPrograms.length);

            if (valid) {
                for each (sourcePath in options.includeSources) addSources(currentDirectory.resolvePath(sourcePath));
                for each (sourcePath in options.excludeSources) excludeSources(currentDirectory.resolvePath(sourcePath));

                parse();
                if (valid) verify();
            }
        }

        public function addSources(file:File):void {
            _addSources(file, sourceFiles);
        }

        public function excludeSources(file:File):void {
            _excludeSources(file, sourceFiles);
        }

        public function compileGlobalObjects():void {
            var k:CompilerOptions = verifier.compilerOptions;
            verifier.compilerOptions = _loadConfigFile(File.applicationDirectory.resolvePath('res/globalobjects/dovescript.json'));
            addSources(File.applicationDirectory.resolvePath('res/globalobjects'));
            parse();
            if (valid)
                verify();
            _globalObjectProgramsLength = latestIncludedPrograms.length;
            skipProgramsLength(latestIncludedPrograms.length);
            verifier.compilerOptions = k;
        }

        public function parse():void {
            for each (var file:File in sourceFiles.slice(_skipLength)) {
                var ba:ByteArray = new ByteArray,
                    fileStream:FileStream = new FileStream;
                fileStream.open(file, 'read');
                fileStream.readBytes(ba);
                ba.position = 0;

                var script:Script = new Script(file.url, new CharArray(ba));
                scripts.push(script);

                var program:ProgramNode = new Parser(script).parseProgram();
                if (program) programs.push(program);
                if (!script.isValid) _valid = false;
            }
        }

        public function verify():void {
            var subPrograms:Array = programs.slice(_skipLength);
            verifier.verifyPrograms(subPrograms);
            _valid = !verifier.invalidated;
            verifier.arrangeProblems(subPrograms);
        }

        public function skipProgramsLength(length:uint):void {
            _skipLength += length;
        }

        public function get valid():Boolean {
            return _valid;
        }

        public function get onlyGlobalObjectsIncluded():Boolean {
            return programs.length == _globalObjectProgramsLength;
        }

        public function get globalObjectPrograms():Array {
            return programs.slice(0, _globalObjectProgramsLength);
        }

        public function get latestIncludedPrograms():Array {
            return programs.slice(_skipLength);
        }

        public function traceProblems():Promise {
            return new Promise(function(resolve, reject) {
                var translator:Translator = new Translator({
                    assets: {
                        path: File.applicationDirectory.resolvePath('res/lang').nativePath,
                        roots: ['syntaxErrors', 'verifyErrors', 'warnings'],
                        loaderType: 'fileSystem'
                    }
                });

                translator.setLanguage(Language.EN_US)
                    .done(function() {
                        var problemFormatter:ProblemFormatter = new ProblemFormatter(translator),
                            problemTraces:Array = [];

                        for each (var script:Script in scripts)
                            (function collectScriptProblems(script:Script) {
                                for each (var problem:Problem in script.problems)
                                    problemTraces.push({
                                        errorType: problem.isWarning ? 'Warning' : problem.isSyntaxError ? 'SyntaxError' : 'VerifyError',
                                        message: problemFormatter.format(problem),
                                        url: problem.location.script.url,
                                        line: problem.location.span.firstLine,
                                        column: problem.location.span.start - problem.location.script.getLineStart(problem.location.span.firstLine) + 1
                                    });
                                for each (var includedScript:Script in script.includesScripts)
                                    collectScriptProblems(includedScript);
                            })(script);

                        resolve(problemTraces);

                        for each (var problem:* in problemTraces)
                            trace(problem.errorType + ': ' + problem.message),
                            trace('      at ' + problem.url + ':' + problem.line + ':' + problem.column),
                            trace('');

                        /*
                        var outputStream:FileStream = new FileStream;
                        outputStream.open(currentDirectory.resolvePath('ds.out.log'), 'write');
                        outputStream.writeUTFBytes(JSON.stringify({
                            problems: problemTraces
                        }));
                        */
                    })
                    .fail(function(error) { reject(error) });
            });
        }

        private function _addSources(file:File, result:Array):void {
            if (file.isDirectory) for each (var subfile:File in file.getDirectoryListing()) _addSources(subfile, result);

            else if (file.extension == 'es' || file.extension == 'ds' || file.extension == 'dovescript') result.push(file);
        }

        private function _excludeSources(file:File, result:Array):void {
            var targetURL:String = file.url + (file.isDirectory ? '/' : '');

            for (var i:int = 0; i != result.length; ++i) if (result[i].url.slice(0, targetURL) == targetURL) result.removeAt(i--);
        }

        private function _loadConfigFile(configFile:File):CompilerOptions {
            var fileStream:FileStream = new FileStream;
            fileStream.open(configFile, 'read');
            var json:String = fileStream.readUTFBytes(fileStream.bytesAvailable);
            return new CompilerOptions(JSON.parse(json));
        }

        private function quoteCode(location:SourceLocation):String {
            var line1Index:uint = location.script.getLineStart(location.span.firstLine),
                str1:String,
                str2:String,
                str3:String,
                str4:String;

            str1 = '         ';
            str2 = location.span.firstLine.toString();
            str1 = str1.slice(0, str1.length - str2.length) + str2;

            var j3:int = -1;

            for (location.script.text.position = line1Index; location.script.text.hasRemaining; location.script.text.shift()) {
                var cv:uint = location.script.text[0];
                if (cv == 0x0a || cv == 0x0d) {
                    j3 = location.script.text.position;
                    break;
                }
            }

            location.script.text.position = 0;

            str2 = location.script.text.slice(line1Index, j3 == -1 ? line1Index : j3);

            var i:uint = location.span.start - line1Index,
                j:uint = location.span.end - line1Index;

            j = j > str2.length ? str2.length : j;

            str3 = str2.slice(i, j);
            str4 = str2.slice(j);
            str2 = str2.slice(0, i);

            var line:String = str1 + ' | ' + str2 + str3 + str4;
            var carret:String;

            j = str1.length + 3 + str2.length;

            for (i = 0; i != str3.length; ++i)
                carret += '^';
            carret = i == 0 ? carret + '^' : carret;
            return line + '\n' + carret;
        }
    }
}