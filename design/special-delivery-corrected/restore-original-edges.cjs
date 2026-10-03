const fs=require('fs'),path=require('path');
const sharp=require('/home/parsa/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const dir=__dirname;
(async()=>{
 const original=await sharp(path.join(dir,'../mobile-brand-premium/02-special-delivery/master.png')).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 const edited=await sharp(path.join(dir,'master.png')).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 const {width,height}=original.info;
 if(width!==edited.info.width||height!==edited.info.height)throw Error('Source dimensions must match.');
 // Original pixels everywhere except the local wing repair. Preserve original alpha.
 const roi={left:0,top:196,right:490,bottom:690,feather:24};
 const out=Buffer.from(original.data);
 let untouched=0,changed=0;
 for(let y=0;y<height;y++)for(let x=0;x<width;x++){
  const d=Math.min(x-roi.left,roi.right-x,y-roi.top,roi.bottom-y);
  const t=Math.max(0,Math.min(1,d/roi.feather));
  const w=t*t*(3-2*t),i=(y*width+x)*4;
  if(w===0){untouched++;continue;}
  for(let c=0;c<3;c++)out[i+c]=Math.round(original.data[i+c]*(1-w)+edited.data[i+c]*w);
  changed++;
 }
 for(let i=3;i<out.length;i+=4)if(out[i]!==original.data[i])throw Error('Original alpha was changed.');
 const master=path.join(dir,'master-edge-restored.png');
 await sharp(out,{raw:{width,height,channels:4}}).png().toFile(master);
 const store=path.join(dir,'play-store-512-edge-restored.png');
 await sharp(master).resize(512,512).flatten({background:'#155DAF'}).ensureAlpha().toColourspace('srgb').png().toFile(store);
 for(const size of [64,48,32])await sharp(store).resize(size,size).png().toFile(path.join(dir,`icon-${size}-edge-restored.png`));
 const meta=await sharp(store).metadata(),stats=await sharp(store).stats();
 if(meta.width!==512||meta.height!==512||meta.channels!==4||stats.channels[3].min!==255||fs.statSync(store).size>1024*1024)throw Error('Invalid store export');
 const report={method:'Direct pixel compositing, as requested; no regeneration.',base:'../mobile-brand-premium/02-special-delivery/master.png',wing_patch:'master.png',output:'master-edge-restored.png',width,height,roi,original_pixels_preserved:untouched,patch_pixels:changed,alpha:'Original alpha preserved at every pixel.',store:'play-store-512-edge-restored.png'};
 fs.writeFileSync(path.join(dir,'edge-restoration.json'),JSON.stringify(report,null,2)+'\n');
 console.log(JSON.stringify(report));
})();
