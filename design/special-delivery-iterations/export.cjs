const fs=require('fs'),path=require('path');
const sharp=require('/home/parsa/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const root=__dirname;
(async()=>{
 for(const d of ['01-original','02-express-swoop','03-happy-arrival']){
  const src=path.join(root,d,'master.png');
  const out=path.join(root,d,'play-store-512.png');
  // Mechanical export sizing; generated master is preserved unchanged.
  if(d!=='01-original')await sharp(src).resize(512,512,{fit:'cover'}).flatten({background:'#155DAF'}).ensureAlpha().toColourspace('srgb').png().toFile(out);
  for(const size of [64,48,32])await sharp(out).resize(size,size).png().toFile(path.join(root,d,`icon-${size}.png`));
  const m=await sharp(out).metadata(),s=await sharp(out).stats();
  if(m.width!==512||m.height!==512||m.space!=='srgb'||!m.hasAlpha||s.channels[3].min!==255||fs.statSync(out).size>1024*1024)throw Error('Invalid export '+d);
  console.log(d+': 512 px opaque RGBA export verified');
 }
})();
