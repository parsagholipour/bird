from pathlib import Path
import sys, json
sys.path.insert(0,str(Path(__file__).resolve().parent.parent))
from logo_tools import lettering, svg
D=Path(__file__).resolve().parent
ink='#203B45'; cream='#FFF9ED'; coral='#F47D64'
# A broad feather has a soft tip and asymmetric, sculpted shoulders.
mark='''<path fill="#203B45" d="M 598 147 C 591 134 576 138 566 150 C 462 241 405 332 423 424 C 439 508 512 553 598 541 C 691 530 771 472 769 390 C 767 316 701 275 648 227 C 625 207 610 176 598 147 Z"/>
<path fill="#FFF9ED" d="M 489 409 C 485 371 507 340 546 334 C 564 330 580 333 595 341 C 605 306 615 276 634 253 C 645 240 653 242 654 257 L 655 329 C 656 343 668 353 681 361 C 700 373 709 393 706 414 C 702 449 674 470 638 472 C 609 474 588 465 573 450 C 548 468 520 477 485 475 C 505 460 514 447 517 436 C 499 433 490 423 489 409 Z"/>
<path fill="#F47D64" d="M 695 376 L 723 392 Q 728 396 722 400 L 702 408 Z"/>
<circle cx="670" cy="382" r="7" fill="#203B45"/>
<path fill="#203B45" d="M 630 444 Q 650 458 670 441 Q 658 466 638 459 Z"/>
<path d="M 599 514 Q 573 551 549 575" fill="none" stroke="#203B45" stroke-width="20" stroke-linecap="round"/>
<circle cx="764" cy="277" r="14" fill="#F47D64"/>'''
body=mark+lettering('Push-Up Bird',600,692,74,fill=ink,family='Nunito',weight=800,tracking=2)
(D/'logo.svg').write_text(svg(body))
# Match the standalone icon to the same geometry without linked artwork.
(D/'mark.svg').write_text(svg('<g transform="translate(-350,-110)">'+mark+'</g>',width=500,height=500))
(D/'concept.json').write_text(json.dumps({'id':17,'name':'Negative-Space Feather','rationale':'A soft ink feather reveals a cheerful little bird raising one wing in its cream cutout, pairing a memorable stamp silhouette with a quietly playful coral accent.','theme':'Friendly negative-space emblem','palette':[ink,cream,coral]},indent=2)+'\n')
if __name__=='__main__':
 import xml.etree.ElementTree as ET
 ET.parse(D/'logo.svg'); ET.parse(D/'mark.svg')
