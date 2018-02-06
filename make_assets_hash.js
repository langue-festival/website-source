
const outputPath = process.argv[2];

if (outputPath === undefined) {
    console.log('Missing output path parameter');
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
    .sort((a, b) => a.fst > b.fst)
    .map(rec => rec.snd)
    .reduce((acc, hash) => md5(acc + hash));

const options = { mode: 0o644, encoding: 'utf8' };

fs.writeFileSync(outputPath, 'var assetsHash = "', options);
fs.appendFileSync(outputPath, assetsHash, options);
fs.appendFileSync(outputPath, '";\n', options);

console.log('Successfully generated', outputPath);
