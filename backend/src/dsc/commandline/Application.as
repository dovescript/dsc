package dsc.commandline {
    import flash.display.Sprite;
    import flash.desktop.NativeApplication;
    import flash.events.InvokeEvent;
    import flash.filesystem.File;
    import flash.filesystem.FileStream;
    import flash.utils.ByteArray;

    import com.siteblade.intl.*;
    import com.siteblade.util.CharArray;

    import dsc.*;
    import dsc.semantics.*;
    import dsc.parsing.*;
    import dsc.parsing.ast.*;
    import dsc.verification.*;
    // import dsc.targets.js.*;
    // import dsdoc.*;

    public class Application extends Sprite {
        public function Application() {
            NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, onInvoke);
        }

        private function onInvoke(e:InvokeEvent):void {
            var currentDirectory:File = e.currentDirectory;

            var options:* = JSON.parse(e.arguments[0] || '{}');
            var compiler:Compiler = new Compiler(options, currentDirectory);

            compiler.traceProblems()
                .done(function(problems:Array) {
                    if (compiler.valid) {
                        // if (options.doc)
                        //    new DocGenerator(compiler, currentDirectory, options);
                    }
                    flash.desktop.NativeApplication.nativeApplication.exit();
                });
        }
    }
}