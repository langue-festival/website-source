
const outputJs = process.argv[2];
const outputScss = process.argv[3];

if (outputJs === undefined) {
    console.log('Missing js output path');
    process.exit(1);
} else if (outputScss === undefined) {
    console.log('Missing scss output path');
    process.exit(1);
}

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const assetsBasePath = 'assets';

const pair = function (fst, snd) {
    return { fst: fst, snd: snd };
};

const md5 = function (str) {
    return crypto
        .createHash('md5')
        .update(str)
        .digest('hex');
};

const recHash = function (file, hashs = []) {
    if (fs.statSync(file).isDirectory()) {
        const files = fs.readdirSync(file);

        files.forEach(p => recHash(path.join(file, p), hashs));
    } else {
        const content = fs.readFileSync(file);

        hashs.push(pair(file, md5(content)));
    }

    return hashs;
};

const assetsHash = recHash(assetsBasePath)
    .filter(a => ! a.fst.endsWith('.scss'))
    .filter(a => ! a.fst.endsWith('.js'))
    .sort((a, b) => a.fst > b.fst)
    .map(a => a.snd)
    .reduce((acc, hash) => md5(acc + hash));

const options = { mode: 0o644, encoding: 'utf8' };

let output = '';

output = 'var assetsHash = "' + assetsHash + '";\n';
fs.writeFileSync(outputJs, output, options);
console.log('Successfully generated', outputJs);

output = '$assets-hash: "' + assetsHash + '";\n';
fs.writeFileSync(outputScss, output, options);
console.log('Successfully generated', outputScss);
