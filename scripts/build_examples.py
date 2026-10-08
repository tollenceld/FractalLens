"""Reproducible approximate centerline annotations for the six attributed photographs.
Landmark polylines are selected by inspection in source-image pixels. Fine veins
interpolate observed pinna spacing; they are illustrative annotations, not extraction.
No pixels are generated or modified by this script.
"""
import json, math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
items=[]

def photo(key,title,subtitle,w,h,image,author,file,license,license_url):
    branches=[]
    def add(points,parent=None,depth=0):
        ident=len(branches)
        branches.append(dict(id=ident,parent=parent,depth=depth,points=[dict(x=x/w,y=y/h) for x,y in points]))
        return ident
    def point(points,t):
        lens=[math.dist(a,b) for a,b in zip(points,points[1:])]; target=t*sum(lens)
        for i,d in enumerate(lens):
            if target<=d:
                f=target/d if d else 0;a,b=points[i:i+2];return (a[0]+(b[0]-a[0])*f,a[1]+(b[1]-a[1])*f)
            target-=d
        return points[-1]
    def pinna(points,parent,depth,count,width,veins=False):
        ident=add(points,parent,depth)
        dx=points[-1][0]-points[0][0];dy=points[-1][1]-points[0][1];length=math.hypot(dx,dy);ux,uy=dx/length,dy/length
        for k in range(count):
            t=0.1+0.8*k/max(1,count-1)
            # Measured repeated leaflets, interpolated between traced pinna landmarks.
            envelope=math.sin(math.pi*(0.12+0.82*t))**0.7*(1-0.35*t)
            for sign in [-1,1]:
                a=point(points,min(0.96,t+(0.014 if sign==1 else 0)))
                span=width*envelope
                end=(a[0]+ux*span*0.42-uy*span*sign,a[1]+uy*span*0.42+ux*span*sign)
                mid=(a[0]+(end[0]-a[0])*0.53+ux*span*0.1,a[1]+(end[1]-a[1])*0.53+uy*span*0.1)
                child=add([a,mid,end],ident,depth+1)
                if veins and k%2==0:
                    for f in [0.4,0.7]:
                        start=(a[0]+(end[0]-a[0])*f,a[1]+(end[1]-a[1])*f)
                        for side in [-1,1]:
                            ex=end[0]-a[0];ey=end[1]-a[1]
                            tip=(start[0]+ex*0.16-ey*side*0.13,start[1]+ey*0.16+ex*side*0.13)
                            add([start,tip],child,depth+2)
        return ident
    attr=f'Photograph: {author}. [{file}](https://commons.wikimedia.org/wiki/File:{file.replace(" ","_")}). [{license}]({license_url}). Original photograph retained. Approximate centerline annotation and presentation by Fractal Lens; fine veins are interpolated from visible spacing. '
    if key=='fern-study':attr+='White paper is isolated at display time; the original is available in the bundled assets.'
    item=dict(key=key,title=title,subtitle=subtitle,image=image,attribution=attr,aspectRatio=w/h,branches=branches)
    items.append(item)
    return add,pinna

add,pinna=photo('fern-study','A smaller whole','Fern · nested branching',960,723,'fern-study.jpg','Olegivvit','Fern-leaf-oliv.jpg','CC BY 2.5','https://creativecommons.org/licenses/by/2.5/')
add([(290,637),(351,535),(417,419),(480,328),(552,245),(623,182),(695,143),(756,126),(816,132),(873,165)])
landmarks=[([(353,529),(283,567),(157,593)],7,21), ([(373,497),(497,512),(654,511),(784,533),(868,566)],16,103), ([(392,463),(313,504),(207,537)],8,34), ([(417,418),(550,405),(685,422),(813,453)],15,63), ([(442,382),(345,404),(236,399),(104,423)],13,49), ([(468,345),(576,307),(695,321),(790,365)],12,47), ([(498,308),(378,326),(245,324),(99,293)],15,37), ([(532,267),(607,245),(675,262),(732,301)],10,32), ([(554,244),(443,251),(350,240),(247,205),(192,174)],14,38), ([(592,211),(635,220),(684,241)],6,22), ([(623,182),(562,119),(483,109),(430,124)],8,26), ([(665,151),(714,178),(762,207)],6,23), ([(690,141),(671,88),(654,28)],7,18), ([(715,133),(708,81),(692,35)],6,15), ([(744,128),(758,90),(766,45)],5,15), ([(770,129),(784,100),(797,65)],5,13), ([(797,131),(820,107),(835,83)],4,11), ([(817,139),(846,135),(870,149)],4,10)]
for pts,count,width in landmarks:pinna(pts,0,1,count,width,veins=True)

add,pinna=photo('fern-unfolding','The unfinished rhythm','Young fern · unfolding',500,733,'fern-unfolding.jpg','Leslie Seaton','5b fern (7518606760).jpg','CC BY 2.0','https://creativecommons.org/licenses/by/2.0/')
add([(255,732),(269,591),(248,459),(257,372),(261,298),(264,235),(253,155),(239,108),(212,87),(186,89)])
for pts,count,width in [([(250,685),(167,659),(92,664),(5,692)],9,24), ([(269,589),(346,555),(424,545),(499,555)],9,28), ([(248,459),(176,436),( ninety:=90,435),(40,454),(29,478)],9,17), ([(257,372),(309,344),(377,338),(418,357),(429,378)],8,20), ([(261,298),(216,281),(170,276),(130,289),(107,316)],8,16), ([(264,235),(324,201),(389,180)],7,12), ([(252,155),(298,137),(333,140)],5,10)]:pinna(pts,0,1,count,width)
# Visible curled tips, retained as geometry rather than forced into a recursive template.
for pts in [[(256,193),(219,185),(197,200),(186,225),(189,257),(208,276)],[(239,110),(215,115),(210,135),(218,154),(238,150)],[(212,87),(215,66),(229,51),(220,45),(210,53)],[(209,88),(169,91),(146,108),(127,102),(120,91),(133,74),(154,68)]]:pinna(pts,0,1,5,8)

add,pinna=photo('fern-canopy','Repeating into shade','Fern fragment · layered',2048,1151,'fern-canopy.jpg','gunthercox','Fern Leaves Black Background.JPG','CC0 1.0','https://creativecommons.org/publicdomain/zero/1.0/')
add([(31,650),(320,546),(651,431),(972,361),(1285,304),(1502,294),(1764,322),(2005,390)])
for pts,count,width in [([(320,546),(356,423),(406,338),(472,243)],10,60), ([(473,490),(592,267),(652,141),(720,23)],11,64), ([(651,431),(712,613),(833,749),(887,1109)],13,67), ([(816,394),(880,502),(937,632),(943,853)],11,57), ([(972,361),(1037,574),(1114,804),(1216,1067)],14,66), ([(1135,330),(1283,586),(1435,792)],11,71), ([(1285,304),(1440,497),(1559,690)],11,59), ([(1451,293),(1613,434),(1745,601)],9,49), ([(976,360),(1122,186),(1272,111)],9,54), ([(1285,304),(1391,185),(1496,169)],7,39)]:pinna(pts,0,1,count,width,veins=True)

add,pinna=photo('bare-tree','The space between','Bare tree · divergent',1280,853,'bare-tree.jpg','Johannes Plenio','Bare tree during sunset.jpg','CC0 1.0','https://creativecommons.org/publicdomain/zero/1.0/')
add([(851,568),(848,498),(840,445),(850,406),(854,367),(843,329),(851,290),(840,254),(827,225),(820,185)])
# Visible large boughs and their branchlets are individually anchored in the photograph.
branches=[(0,1,[(843,455),(813,451),(776,459),(735,487),(698,497)]),(0,1,[(839,432),(803,420),(767,424),(728,412),(683,397)]),(0,1,[(850,421),(895,414),(928,406),(957,382),(977,370)]),(0,1,[(849,455),(899,440),(939,453),(978,446),(1019,472)]),(0,1,[(849,403),(819,375),(811,339),(801,312),(783,269)]),(0,1,[(853,366),(880,333),(915,321),(943,290)]),(0,1,[(843,329),(814,315),(785,304),(755,276),(740,240)]),(0,1,[(851,291),(870,267),(886,227)]),(0,1,[(840,254),(811,240),(792,214)])]
for parent,depth,pts in branches:add(pts,parent,depth)
children=[(1,[(776,459),(748,474),(729,476),(710,477)]),(1,[(813,451),(800,481),(780,506)]),(2,[(767,424),(748,406),(733,376),(708,348)]),(2,[(728,412),(705,421),(672,426)]),(2,[(803,420),(782,395),(781,365)]),(3,[(895,414),(902,382),(908,366),(933,358)]),(3,[(957,382),(986,386),(1024,367)]),(4,[(939,453),(966,427),(994,424),(1043,431)]),(4,[(899,440),(917,477),(917,501)]),(5,[(811,339),(779,337),(751,323),(711,330)]),(5,[(801,312),(811,278),(805,244),(813,209)]),(6,[(880,333),(881,306),(906,278),(933,271)]),(6,[(915,321),(951,319),(970,313)]),(7,[(785,304),(770,279),(758,252),(757,218)]),(7,[(755,276),(723,268),(702,252)]),(8,[(870,267),(849,246),(850,218),(864,203)]),(9,[(811,240),(791,253),(771,242),(764,221)])]
for parent,pts in children:
    child=add(pts,parent,2)
    # Terminal twig landmarks relative to visible endpoint directions.
    a,b=pts[-2:];dx=b[0]-a[0];dy=b[1]-a[1]
    for f,side in [(0.35,-1),(0.72,1)]:
        start=(a[0]+dx*f,a[1]+dy*f)
        end=(start[0]+dx*.55-dy*side*.42,start[1]+dy*.55+dx*side*.42)
        add([start,end],child,3)

add,pinna=photo('neem','A vein becomes a branch','Neem · compound leaf',1920,1280,'neem.jpg','Radioactivebanana','Pinnately compound leaf of neem tree.jpg','CC BY-SA 4.0','https://creativecommons.org/licenses/by-sa/4.0/')
add([(1919,1213),(1595,1037),(1248,739),(925,443),(586,151),(358,0)])
for pts,count,width in [([(586,151),(450,318),(264,583),(17,900)],10,71), ([(925,443),(745,673),(491,980),(228,1264)],12,72), ([(1248,739),(1211,907),(1094,1107),(979,1275)],8,72), ([(1595,1037),(1547,1168),(1509,1276)],5,78), ([(925,443),(868,292),(817,135),(751,119)],6,80), ([(1248,739),(1259,592),(1239,492),(1186,390)],8,83), ([(1595,1037),(1614,918),(1598,818),(1512,770)],6,64)]:pinna(pts,0,1,count,width)

add,pinna=photo('ekebergia','One axis, many echoes','Ekebergia · paired leaves',500,667,'ekebergia.jpg','JonRichfield','Simply pinnate leaf of Ekebergia capensis IMG 2422.jpg','CC BY-SA 4.0','https://creativecommons.org/licenses/by-sa/4.0/')
add([(296,7),(283,87),(265,155),(254,203),(245,255),(238,306),(234,351),(220,449),(209,514)])
for pts,count,width in [([(265,155),(269,102),(274,54),(289,29)],6,10), ([(265,155),(227,135),(189,128),(172,125)],5,10), ([(265,155),(294,143),(332,144),(365,151)],5,12), ([(254,203),(199,209),(141,230),(90,252)],7,16), ([(254,203),(307,199),(348,220),(372,251)],6,14), ([(245,255),(188,276),(122,316),(80,340)],7,18), ([(245,255),(298,264),(365,290),(402,326)],7,19), ([(238,306),(199,350),(157,408),(117,470)],9,18), ([(238,306),(286,340),(339,391),(384,412)],8,20), ([(234,351),(269,400),(302,469),(311,493)],7,16)]:pinna(pts,0,1,count,width)

(ROOT/'FractalLens/Resources/examples.json').write_text(json.dumps(items,separators=(',',':')))
print([(i['key'],len(i['branches'])) for i in items])
