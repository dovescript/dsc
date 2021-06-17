#!/usr/bin/env node

import commanderNS from 'commander';
import chalkNS from 'chalk';
import * as childprocessNS from 'child_process';
import * as filesystemNS from 'fs';
import * as pathNS from 'path';
import * as urlNS from 'url';

const { Command } = commanderNS;

const containingDirectory = pathNS.resolve(urlNS.fileURLToPath(import.meta.url), '..');

const program = new Command('dsc')
    .option('--includeSources <path>', '', (value, previous) => previous.concat([value]), [])
    .option('--excludeSources <path>', '', (value, previous) => previous.concat([value]), [])
    .option('--includeLibrarySources <path>', '', (value, previous) => previous.concat([value]), [])
    .option('--excludeLibrarySources <path>', '', (value, previous) => previous.concat([value]), [])
    .option('-c, --config <path>')
    .option('-o, --output <path>')

    .action(cmdObj => {
        var jsonArguments = JSON.stringify({
            includeSources: cmdObj.includeSources,
            excludeSources: cmdObj.excludeSources,
            includeLibrarySources: cmdObj.includeLibrarySources,
            excludeLibrarySources: cmdObj.excludeLibrarySources,
            config: cmdObj.config,
            output: cmdObj.output,
        });

        var airApplicationPath = pathNS.resolve(containingDirectory, '../../backend/build');
        var subprocess = childprocessNS.spawn('adl', [pathNS.resolve(airApplicationPath, 'app.xml'), '--', jsonArguments], { cwd: process.cwd() });

        subprocess.stdout.on('data', data => {
            var s = data.toString();
            s = s.endsWith('\n') ? s.slice(0, s.length - 1) : s;
            console.log(s);
        });

        subprocess.stderr.on('data', data => {
            var s = data.toString();
            s = s.endsWith('\n') ? s.slice(0, s.length - 1) : s;
            console.log(s);
        });

        subprocess.on('exit', () => {
            // Report problems

            /*
            var output = JSON.parse(filesystemNS.readFileSync(pathNS.resolve('ds.out.log'), 'utf8'));

            filesystemNS.unlinkSync(pathNS.resolve('ds.out.log'));

            for (var problem of output.problems)
                console.error(),
                console.error(problem.errorType + ': ' + problem.message),
                console.error('  at ' + problem.url + ':' + problem.line + ':' + problem.column);
                // console.error(chalkNS.gray(problem.codeQuote));

            process.exit(output.valid ? 0 : 1);
            */

            process.exit(0);
        });
    });

program.parse();