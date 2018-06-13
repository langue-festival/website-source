
const outputJs = process.argv[2];

if (outputJs === undefined) {
  console.log('Missing js output path');
  process.exit(1);
}

const fs = require('fs');
const path = require('path');

const pagesBasePath = 'pages';

let firstAppend = true;

function appendPages (file, options) {
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
      fs.appendFileSync(outputJs, ',\n', options);
    }

    const output = '    [ "' + route + '", "' + content + '" ]';

    fs.appendFileSync(outputJs, output, options);
  }
}

const options = { mode: 0o644, encoding: 'utf8' };

fs.writeFileSync(outputJs, 'var pages = [\n', options);
appendPages(pagesBasePath, options);
fs.appendFileSync(outputJs, '\n];\n', options);

console.log('Successfully generated', outputJs);
