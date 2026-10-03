const fs=require('fs'),path=require('path');
const sharp=require('/home/parsa/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const root=__dirname;
const dirs=['01-skybreak','02-special-delivery','03-trouble-flock'];
(async()=>{
 for(const d of dirs){
  const src=path.join(root,d,'master.png');if(!fs.existsSync(src))continue;
  // Export sizing and opaque store canvas only; the authored image remains in master.png.
  const bg=d==='02-special-delivery'?'#155DAF':d==='03-trouble-flock'?'#EC765E':'#10282F';
  await sharp(src).resize(512,512,{fit:'cover'}).flatten({background:bg}).ensureAlpha().toColourspace('srgb').png().toFile(path.join(root,d,'play-store-512.png'));
  for(const size of [64,48,32])await sharp(path.join(root,d,'play-store-512.png')).resize(size,size).png().toFile(path.join(root,d,`icon-${size}.png`));
  const m=await sharp(path.join(root,d,'play-store-512.png')).metadata();
  if(m.width!==512||m.height!==512||m.space!=='srgb'||!m.hasAlpha||fs.statSync(path.join(root,d,'play-store-512.png')).size>1024*1024)throw Error('Invalid store export '+d);
 }
 const fontRoot=path.join(root,'fonts');fs.mkdirSync(fontRoot,{recursive:true});
 for(const name of ['Fredoka.ttf','Nunito.ttf','Fredoka-LICENSE.txt','Nunito-LICENSE.txt'])fs.copyFileSync(path.join(root,'../../assets/fonts',name),path.join(fontRoot,name));
 const html=path.join(root,'index.html');fs.writeFileSync(html,fs.readFileSync(html,'utf8').replaceAll('../mobile-brand-exploration/fonts/','fonts/'));
 console.log('Store exports and small-size previews validated.');
})();
