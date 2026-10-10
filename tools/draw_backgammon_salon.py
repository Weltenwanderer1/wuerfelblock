"""Original deterministic salon material and brass relief artwork."""
from PIL import Image, ImageDraw, ImageFilter
import math, random
from pathlib import Path
out=Path('assets/images/backgammon'); out.mkdir(parents=True,exist_ok=True)
rng=random.Random(1912)
w,h=600,1000
im=Image.new('RGB',(w,h)); px=im.load()
assert px is not None
for y in range(h):
    for x in range(w):
        grain=math.sin(x*.115+9*math.sin(y*.004)+2*math.sin(y*.017))*5+math.sin(x*.63+y*.008)*2
        glow=14*math.exp(-((x-170)/230)**2)
        noise=rng.uniform(-2,2)
        px[x,y]=(int(83+grain+glow+noise),int(29+grain*.45+glow*.6+noise),int(24+grain*.3+glow*.35+noise))
d=ImageDraw.Draw(im)
for inset in (5,10,18): d.rounded_rectangle((inset,inset,w-inset-1,h-inset-1),radius=20,outline=(190,140,72),width=2 if inset==10 else 1)
for y in (32,h-32):
    for x in range(30,w-30,24): d.polygon([(x,y),(x+7,y-5),(x+14,y),(x+7,y+5)],fill=(151,101,48))
im.save(out/'mahogany.png',optimize=True)
for kind in ('emblem','roll','undo','rules'):
    s=256; a=Image.new('RGBA',(s,s)); d=ImageDraw.Draw(a)
    gold=(223,187,111,255); dark=(104,63,25,255); light=(255,232,166,255)
    def line(points,width=7):
        d.line([(x+2,y+3) for x,y in points],fill=dark,width=width+3,joint='curve')
        d.line(points,fill=gold,width=width,joint='curve')
    if kind=='emblem':
        for r in (116,107,94): d.ellipse((128-r,128-r,128+r,128+r),outline=gold,width=3)
        for angle in range(0,360,30):
            t=math.radians(angle); line([(128+98*math.cos(t),128+98*math.sin(t)),(128+112*math.cos(t),128+112*math.sin(t))],3)
        line([(128,49),(128,183)],10); d.ellipse((111,48,145,82),outline=light,width=6)
        line([(85,112),(171,112)],8)
        d.arc((65,91,191,207),0,180,fill=gold,width=10)
        d.polygon([(65,142),(56,179),(89,170)],fill=gold); d.polygon([(191,142),(200,179),(167,170)],fill=gold)
        line([(84,215),(128,226),(172,215)],4)
    elif kind=='roll':
        d.rounded_rectangle((44,44,212,212),radius=28,outline=gold,width=10)
        for x,y in ((82,82),(174,82),(128,128),(82,174),(174,174)): d.ellipse((x-10,y-10,x+10,y+10),fill=light)
    elif kind=='undo':
        d.arc((54,54,214,214),210,510,fill=gold,width=12)
        line([(96,46),(49,83),(105,104)],12)
    else:
        line([(128,68),(75,47),(38,57),(38,193),(78,184),(128,207),(178,184),(218,193),(218,57),(179,47),(128,68),(128,207)],9)
        for y in (95,124,153):
            line([(57,y),(77,y-3),(108,y+9)],4); line([(148,y+9),(179,y-3),(198,y)],4)
    a.resize((128,128),Image.Resampling.LANCZOS).save(out/f'{kind}.png',optimize=True)
print('Created',[(p.name,p.stat().st_size) for p in out.glob('*.png')])
