const fs=require('fs'),path=require('path');
const sharp=require('/home/parsa/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
(async()=>{const out=path.join(__dirname,'play-store-512.png');
await sharp(path.join(__dirname,'master.png')).resize(512,512,{fit:'cover'}).flatten({background:'#155DAF'}).ensureAlpha().toColourspace('srgb').png().toFile(out);
for(const size of [64,48,32])await sharp(out).resize(size,size).png().toFile(path.join(__dirname,`icon-${size}.png`));
const m=await sharp(out).metadata(),s=await sharp(out).stats();
if(m.width!==512||m.height!==512||m.space!=='srgb'||!m.hasAlpha||s.channels[3].min!==255||fs.statSync(out).size>1024*1024)throw Error('Invalid store export');
console.log('512 px opaque RGBA export verified; previews created.');})();
