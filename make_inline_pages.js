
const outputPath = process.argv[2];

if (outputPath === undefined) {
    console.log('Missing output path parameter');
    process.exit(1);
}

const fs = require('fs');
const path = require('path');

const pagesBasePath = 'pages';

let firstAppend = true;

const appendPages = function (file, options) {
    if (fs.statSync(file).isDirectory()) {
        const files = fs.readdirSync(file);

        files.forEach(p => appendPages(path.join(file, p), options));
    } else {
        const route = path.basename(file, '.md');
        const content = fs
            .readFileSync(file, 'utf8')
            .replace(/"/g, '\\"')
            .replace(/\n/g, '\\n');

        if (firstAppend) {
            firstAppend = false;
        } else {
            fs.appendFileSync(outputPath, ',\n', options);
        }

        const output = '    [ "' + route + '", "' + content + '" ]';

        fs.appendFileSync(outputPath, output, options);
    }
};

const options = { mode: 0o644, encoding: 'utf8' };

fs.writeFileSync(outputPath, 'var pages = [\n', options);
appendPages(pagesBasePath, options);
fs.appendFileSync(outputPath, '\n];\n', options);

console.log('Successfully generated', outputPath);
