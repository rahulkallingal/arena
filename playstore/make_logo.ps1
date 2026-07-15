Add-Type -AssemblyName System.Drawing
$dir="C:\Users\rahul\Desktop\Apps\arena\playstore\logo_combined"
if(-not(Test-Path $dir)){New-Item -ItemType Directory -Path $dir|Out-Null}
$W=512
function SB{param($c)New-Object System.Drawing.SolidBrush $c}
function PEN{param($c,$w)New-Object System.Drawing.Pen($c,$w)}
function RR{param($x,$y,$w,$h,$r)$p=New-Object System.Drawing.Drawing2D.GraphicsPath;$d=$r*2
 $p.AddArc($x,$y,$d,$d,180,90);$p.AddArc($x+$w-$d,$y,$d,$d,270,90);$p.AddArc($x+$w-$d,$y+$h-$d,$d,$d,0,90);$p.AddArc($x,$y+$h-$d,$d,$d,90,90);$p.CloseFigure();return $p}
function NewCanvas{param($c1,$c2)
 $bmp=New-Object System.Drawing.Bitmap $W,$W;$g=[System.Drawing.Graphics]::FromImage($bmp)
 $g.SmoothingMode=[System.Drawing.Drawing2D.SmoothingMode]::HighQuality;$g.CompositingQuality=[System.Drawing.Drawing2D.CompositingQuality]::HighQuality
 $g.TextRenderingHint=[System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
 $r=New-Object System.Drawing.Rectangle 0,0,$W,$W;$g.FillRectangle((New-Object System.Drawing.Drawing2D.LinearGradientBrush($r,$c1,$c2,90)),$r);return @($bmp,$g)}
function Glow{param($g,$cx,$cy,$rad,$col)$p=New-Object System.Drawing.Drawing2D.GraphicsPath;$p.AddEllipse($cx-$rad,$cy-$rad,$rad*2,$rad*2)
 $pg=New-Object System.Drawing.Drawing2D.PathGradientBrush $p;$pg.CenterColor=$col;$pg.SurroundColors=@([System.Drawing.Color]::FromArgb(0,0,0,0));$g.FillPath($pg,$p)}
function Save{param($b,$n)$b[0].Save("$dir\$n",[System.Drawing.Imaging.ImageFormat]::Png);$b[1].Dispose();$b[0].Dispose()}
$navy=[System.Drawing.Color]::FromArgb(19,24,34);$black=[System.Drawing.Color]::FromArgb(5,6,10)

# arena base ring (stadium) - draws behind figures
function ArenaBase{param($g)
 $stone=New-Object System.Drawing.Drawing2D.LinearGradientBrush((New-Object System.Drawing.Rectangle 86,392,340,96),([System.Drawing.Color]::FromArgb(214,186,132)),([System.Drawing.Color]::FromArgb(140,110,64)),90)
 $g.FillEllipse($stone,86,392,340,96)
 $g.FillEllipse((SB ([System.Drawing.Color]::FromArgb(150,120,70))),120,404,272,72)
 $g.FillEllipse((SB $navy),150,416,212,52)
 $g.FillEllipse((SB ([System.Drawing.Color]::FromArgb(120,92,52))),176,426,160,36)}

# one figure-leg of the A: base point, lean angle, colors
function Leg{param($g,$bx,$by,$ang,$hi,$dk,$rim)
 $st=$g.Save();$g.TranslateTransform([single]$bx,[single]$by);$g.RotateTransform([single]$ang)
 $len=250;$wd=58
 $bar=RR (-$wd/2) (-$len) $wd $len ($wd/2)
 $bg=New-Object System.Drawing.Drawing2D.LinearGradientBrush((New-Object System.Drawing.Rectangle ([int](-$wd/2)),(-$len),$wd,$len),$hi,$dk,0)
 $g.FillPath($bg,$bar)
 $hd=78;$hp=New-Object System.Drawing.Drawing2D.GraphicsPath;$hp.AddEllipse(-$hd/2,(-$len-$hd/2+8),$hd,$hd)
 $pg=New-Object System.Drawing.Drawing2D.PathGradientBrush $hp
 $pg.CenterPoint=New-Object System.Drawing.PointF ([single](-$hd*0.16)),([single](-$len-$hd*0.16+8))
 $pg.CenterColor=$hi;$pg.SurroundColors=@($dk);$g.FillPath($pg,$hp)
 $g.DrawEllipse((PEN $rim 3),-$hd/2+2,(-$len-$hd/2+10),$hd-4,$hd-4)
 $g.Restore($st)}

$blueHi=[System.Drawing.Color]::FromArgb(86,150,240);$blueDk=[System.Drawing.Color]::FromArgb(20,54,120);$blueRim=[System.Drawing.Color]::FromArgb(140,120,170,235)
$redHi=[System.Drawing.Color]::FromArgb(240,96,108);$redDk=[System.Drawing.Color]::FromArgb(120,20,28);$redRim=[System.Drawing.Color]::FromArgb(140,235,150,158)
$goldHi=[System.Drawing.Color]::FromArgb(236,206,140);$goldDk=[System.Drawing.Color]::FromArgb(150,112,52);$goldRim=[System.Drawing.Color]::FromArgb(150,255,235,180)

function Crossbar{param($g,$col1,$col2)
 $cb=RR 198 286 116 34 16
 $g.FillPath((New-Object System.Drawing.Drawing2D.LinearGradientBrush((New-Object System.Drawing.Rectangle 198,286,116,34),$col1,$col2,0)),$cb)}

# ---- V1: gold figures form A (monument style) ----
$c=NewCanvas $navy $black;$g=$c[1];Glow $g 256 300 210 ([System.Drawing.Color]::FromArgb(70,235,170,60));ArenaBase $g
Crossbar $g $goldHi $goldDk
Leg $g 168 418 14 $goldHi $goldDk $goldRim
Leg $g 344 418 -14 $goldHi $goldDk $goldRim
Save $c "L1_gold.png"

# ---- V2: blue vs red figures form A (two sides) ----
$c=NewCanvas $navy $black;$g=$c[1];Glow $g 256 300 210 ([System.Drawing.Color]::FromArgb(60,90,120,180));ArenaBase $g
Crossbar $g ([System.Drawing.Color]::FromArgb(150,120,160)) ([System.Drawing.Color]::FromArgb(90,70,110))
Leg $g 168 418 14 $blueHi $blueDk $blueRim
Leg $g 344 418 -14 $redHi $redDk $redRim
Save $c "L2_twosides.png"

# ---- V3: bold gold A letter + two small humans inside, on arena ----
$c=NewCanvas $navy $black;$g=$c[1];Glow $g 256 290 210 ([System.Drawing.Color]::FromArgb(65,230,175,70));ArenaBase $g
# big A as thick outline (two legs + crossbar) gold
$Apath=New-Object System.Drawing.Drawing2D.GraphicsPath
$Apath.AddPolygon(@(
 (New-Object System.Drawing.Point 256,96),(New-Object System.Drawing.Point 300,96),
 (New-Object System.Drawing.Point 396,430),(New-Object System.Drawing.Point 340,430),
 (New-Object System.Drawing.Point 318,352),(New-Object System.Drawing.Point 194,352),
 (New-Object System.Drawing.Point 172,430),(New-Object System.Drawing.Point 116,430),
 (New-Object System.Drawing.Point 212,96)))
$Ag=New-Object System.Drawing.Drawing2D.LinearGradientBrush((New-Object System.Drawing.Rectangle 116,96,280,334),$goldHi,$goldDk,90)
$g.FillPath($Ag,$Apath)
# crossbar of A
$g.FillPath($Ag,(RR 206 300 100 30 12))
# two small humans inside lower opening, facing each other
function MiniPerson{param($g,$cx,$col)
 $g.FillEllipse((SB $col),$cx-18,352,36,36)
 $g.FillPath((SB $col),(RR ($cx-26) 392 52 52 22))}
MiniPerson $g 230 ([System.Drawing.Color]::FromArgb(70,140,230))
MiniPerson $g 282 ([System.Drawing.Color]::FromArgb(226,64,76))
Save $c "L3_Awithpeople.png"

# ---- montage ----
$cols=3;$cell=300;$pad=22;$labelH=36
$mw=$cols*$cell+($cols+1)*$pad;$mh=$cell+$labelH+2*$pad
$m=New-Object System.Drawing.Bitmap $mw,$mh;$mg=[System.Drawing.Graphics]::FromImage($m)
$mg.SmoothingMode=[System.Drawing.Drawing2D.SmoothingMode]::HighQuality;$mg.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$mg.TextRenderingHint=[System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit;$mg.Clear([System.Drawing.Color]::FromArgb(245,246,248))
$files=@("L1_gold.png","L2_twosides.png","L3_Awithpeople.png");$labels=@("A1  Gold figures = A","A2  Blue vs Red = A","A3  A + two people")
for($i=0;$i -lt 3;$i++){$x=$pad+$i*($cell+$pad);$y=$pad
 $img=[System.Drawing.Image]::FromFile("$dir\$($files[$i])");$mg.DrawImage($img,$x,$y,$cell,$cell);$img.Dispose()
 $sf=New-Object System.Drawing.StringFormat;$sf.Alignment=1
 $mg.DrawString($labels[$i],(New-Object System.Drawing.Font("Segoe UI",16,[System.Drawing.FontStyle]::Bold)),(SB ([System.Drawing.Color]::FromArgb(30,40,55))),(New-Object System.Drawing.RectangleF $x,($y+$cell+4),$cell,$labelH),$sf)}
$mg.Dispose();$m.Save("$dir\ALL_COMBINED.png",[System.Drawing.Imaging.ImageFormat]::Png);$m.Dispose()
Write-Output "combined logos done"
