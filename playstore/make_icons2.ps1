Add-Type -AssemblyName System.Drawing
$dir = "C:\Users\rahul\Desktop\Apps\arena\playstore\icon_options2"
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
$W = 512

function NewCanvas { param($c1,$c2,$angle)
  $bmp=New-Object System.Drawing.Bitmap $W,$W
  $g=[System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode=[System.Drawing.Drawing2D.SmoothingMode]::HighQuality
  $g.CompositingQuality=[System.Drawing.Drawing2D.CompositingQuality]::HighQuality
  $g.TextRenderingHint=[System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
  $r=New-Object System.Drawing.Rectangle 0,0,$W,$W
  $g.FillRectangle((New-Object System.Drawing.Drawing2D.LinearGradientBrush($r,$c1,$c2,$angle)),$r)
  return @($bmp,$g)
}
function Glow { param($g,$cx,$cy,$rad,$col)
  $p=New-Object System.Drawing.Drawing2D.GraphicsPath;$p.AddEllipse($cx-$rad,$cy-$rad,$rad*2,$rad*2)
  $pg=New-Object System.Drawing.Drawing2D.PathGradientBrush $p
  $pg.CenterColor=$col;$pg.SurroundColors=@([System.Drawing.Color]::FromArgb(0,0,0,0));$g.FillPath($pg,$p)
}
function RR { param($x,$y,$w,$h,$r)
  $p=New-Object System.Drawing.Drawing2D.GraphicsPath;$d=$r*2
  $p.AddArc($x,$y,$d,$d,180,90);$p.AddArc($x+$w-$d,$y,$d,$d,270,90);$p.AddArc($x+$w-$d,$y+$h-$d,$d,$d,0,90);$p.AddArc($x,$y+$h-$d,$d,$d,90,90);$p.CloseFigure();return $p
}
function Save { param($bmp,$name) $bmp[0].Save("$dir\$name",[System.Drawing.Imaging.ImageFormat]::Png);$bmp[1].Dispose();$bmp[0].Dispose() }
$navy=[System.Drawing.Color]::FromArgb(20,25,36);$black=[System.Drawing.Color]::FromArgb(5,6,10)
function SB { param($col) New-Object System.Drawing.SolidBrush $col }
function PEN { param($col,$w) New-Object System.Drawing.Pen($col,$w) }

# ---------- 1) Colosseum = literal "Arena" ----------
$c=NewCanvas ([System.Drawing.Color]::FromArgb(28,24,20)) $black 90;$g=$c[1]
Glow $g 256 250 210 ([System.Drawing.Color]::FromArgb(70,235,150,40))
$wall=New-Object System.Drawing.Drawing2D.GraphicsPath;$wall.AddEllipse(96,120,320,300)
$stone=New-Object System.Drawing.Drawing2D.LinearGradientBrush((New-Object System.Drawing.Rectangle 96,120,320,300),([System.Drawing.Color]::FromArgb(224,196,140)),([System.Drawing.Color]::FromArgb(150,120,74)),90)
$g.FillPath($stone,$wall)
# punch arches (two rows) using bg-dark rounded-top openings
$dark=SB ([System.Drawing.Color]::FromArgb(22,18,14))
foreach($ax in 128,186,244,302,360){
  $g.FillPath($dark,(RR $ax 168 40 70 20))
  $g.FillPath($dark,(RR $ax 258 40 70 20))
}
# hollow centre (the field)
$g.FillEllipse((SB ([System.Drawing.Color]::FromArgb(20,16,12))),176,210,160,120)
$g.FillEllipse((SB ([System.Drawing.Color]::FromArgb(120,90,50))),186,220,140,100)
Save $c "c1_colosseum.png"

# ---------- 2) Yin-Yang bubbles (two opposing sides) ----------
$c=NewCanvas $navy $black 90;$g=$c[1]
Glow $g 256 256 200 ([System.Drawing.Color]::FromArgb(50,80,110,170))
$cx=256;$cy=256;$R=170
$blue=SB ([System.Drawing.Color]::FromArgb(46,110,214));$red=SB ([System.Drawing.Color]::FromArgb(224,58,72))
$g.FillEllipse($red,$cx-$R,$cy-$R,$R*2,$R*2)
$clip=New-Object System.Drawing.Drawing2D.GraphicsPath;$clip.AddRectangle((New-Object System.Drawing.Rectangle ($cx-$R),($cy-$R),$R,($R*2)))
$g.SetClip($clip);$g.FillEllipse($blue,$cx-$R,$cy-$R,$R*2,$R*2);$g.ResetClip()
$half=[int]($R/2)
$g.FillEllipse($blue,$cx-$half,$cy-$R,$R,$R)
$g.FillEllipse($red,$cx-$half,$cy,$R,$R)
$g.FillEllipse($red,$cx-24,($cy-$R+$half-24),48,48)
$g.FillEllipse($blue,$cx-24,($cy+$half-24),48,48)
$g.DrawEllipse((PEN ([System.Drawing.Color]::FromArgb(120,255,255,255)) 4),$cx-$R,$cy-$R,$R*2,$R*2)
Save $c "c2_yinyang.png"

# ---------- 3) Speech bubble with bold A ----------
$c=NewCanvas $navy $black 90;$g=$c[1]
Glow $g 256 236 200 ([System.Drawing.Color]::FromArgb(55,70,120,200))
$bub=RR 96 96 320 250 54
$bg=New-Object System.Drawing.Drawing2D.LinearGradientBrush((New-Object System.Drawing.Rectangle 96,96,320,250),([System.Drawing.Color]::FromArgb(70,150,250)),([System.Drawing.Color]::FromArgb(28,86,170)),90)
$g.FillPath($bg,$bub)
$tail=New-Object System.Drawing.Drawing2D.GraphicsPath;$tail.AddPolygon(@((New-Object System.Drawing.Point 180,338),(New-Object System.Drawing.Point 250,338),(New-Object System.Drawing.Point 176,410)))
$g.FillPath((SB ([System.Drawing.Color]::FromArgb(40,110,205))),$tail)
$sf=New-Object System.Drawing.StringFormat;$sf.Alignment=1;$sf.LineAlignment=1
$g.DrawString("A",(New-Object System.Drawing.Font("Arial Black",210,[System.Drawing.FontStyle]::Bold)),(SB ([System.Drawing.Color]::White)),(New-Object System.Drawing.RectangleF 96,74,320,250),$sf)
Save $c "c3_bubbleA.png"

# ---------- 4) Balance scale (two sides weighed) ----------
$c=NewCanvas $navy $black 90;$g=$c[1]
Glow $g 256 256 200 ([System.Drawing.Color]::FromArgb(50,90,110,150))
$gold=New-Object System.Drawing.Drawing2D.LinearGradientBrush((New-Object System.Drawing.Rectangle 0,120,512,300),([System.Drawing.Color]::FromArgb(240,210,120)),([System.Drawing.Color]::FromArgb(170,130,60)),90)
$g.FillPath($gold,(RR 246 130 20 240 10))         # post
$g.FillEllipse($gold,236,120,40,40)               # top knob
$state=$g.Save();$g.TranslateTransform(256,168);$g.RotateTransform(-8)
$g.FillPath($gold,(RR -170 -9 340 18 9))          # beam
$g.Restore($state)
# left pan (blue bubble) + right pan (red bubble) via chains
$g.DrawLine((PEN ([System.Drawing.Color]::FromArgb(210,220,150)) 4),120,150,120,250)
$g.DrawLine((PEN ([System.Drawing.Color]::FromArgb(210,220,150)) 4),392,186,392,286)
$g.FillEllipse((SB ([System.Drawing.Color]::FromArgb(46,110,214))),74,250,92,72)
$g.FillEllipse((SB ([System.Drawing.Color]::FromArgb(224,58,72))),346,286,92,72)
$g.FillPath($gold,(RR 196 372 120 26 12))          # base
Save $c "c4_scale.png"

# ---------- 5) Crossed swords (verbal combat) ----------
$c=NewCanvas $navy $black 90;$g=$c[1]
Glow $g 256 256 200 ([System.Drawing.Color]::FromArgb(45,90,110,150))
function Sword { param($g,$angle,$blade,$hilt)
  $st=$g.Save();$g.TranslateTransform(256,256);$g.RotateTransform($angle)
  $bl=New-Object System.Drawing.Drawing2D.GraphicsPath
  $bl.AddPolygon(@((New-Object System.Drawing.Point -22,-190),(New-Object System.Drawing.Point 22,-190),(New-Object System.Drawing.Point 28,120),(New-Object System.Drawing.Point 0,150),(New-Object System.Drawing.Point -28,120)))
  $bg=New-Object System.Drawing.Drawing2D.LinearGradientBrush((New-Object System.Drawing.Rectangle -30,-190,60,340),$blade,([System.Drawing.Color]::FromArgb(120,130,140)),0)
  $g.FillPath($bg,$bl)
  $g.FillPath((SB $hilt),(RR -60 120 120 26 10))   # guard
  $g.FillPath((SB $hilt),(RR -16 146 32 70 12))    # handle
  $g.Restore($st)
}
Sword $g 32 ([System.Drawing.Color]::FromArgb(225,232,240)) ([System.Drawing.Color]::FromArgb(60,110,200))
Sword $g -32 ([System.Drawing.Color]::FromArgb(225,232,240)) ([System.Drawing.Color]::FromArgb(210,60,72))
Save $c "c5_swords.png"

# ---------- 6) Trophy + flame (win the room) ----------
$c=NewCanvas ([System.Drawing.Color]::FromArgb(26,22,20)) $black 90;$g=$c[1]
Glow $g 256 250 200 ([System.Drawing.Color]::FromArgb(70,240,170,50))
$goldB=New-Object System.Drawing.Drawing2D.LinearGradientBrush((New-Object System.Drawing.Rectangle 150,120,220,240),([System.Drawing.Color]::FromArgb(255,224,120)),([System.Drawing.Color]::FromArgb(190,140,50)),90)
$cup=New-Object System.Drawing.Drawing2D.GraphicsPath
$cup.AddArc(168,120,176,150,0,180)   # bowl bottom
$cup.AddLine(168,195,168,140);$cup.AddArc(168,120,176,40,180,180);$cup.CloseFigure()
$g.FillPath($goldB,(RR 176 130 160 90 20))
$g.FillEllipse($goldB,176,196,160,70)
$g.FillPath($goldB,(RR 238 250 36 60 8))     # stem
$g.FillPath($goldB,(RR 196 306 120 26 10))   # base
$g.FillPath($goldB,(RR 176 332 160 26 12))
# handles
$g.DrawArc((PEN ([System.Drawing.Color]::FromArgb(230,200,110)) 16),120,150,80,90,60,200)
$g.DrawArc((PEN ([System.Drawing.Color]::FromArgb(230,200,110)) 16),312,150,80,90,280,200)
# little flame on top
$fl=New-Object System.Drawing.Drawing2D.GraphicsPath
$fl.AddClosedCurve(@((New-Object System.Drawing.PointF 256,70),(New-Object System.Drawing.PointF 286,120),(New-Object System.Drawing.PointF 276,150),(New-Object System.Drawing.PointF 256,164),(New-Object System.Drawing.PointF 236,150),(New-Object System.Drawing.PointF 226,120)),0.4)
$g.FillPath((New-Object System.Drawing.Drawing2D.LinearGradientBrush((New-Object System.Drawing.Rectangle 226,70,60,100),([System.Drawing.Color]::FromArgb(255,110,40)),([System.Drawing.Color]::FromArgb(255,210,60)),90)),$fl)
Save $c "c6_trophy.png"

# ---------- montage ----------
$cols=3;$rows=2;$cell=256;$pad=20;$labelH=34
$mw=$cols*$cell+($cols+1)*$pad;$mh=$rows*($cell+$labelH)+($rows+1)*$pad
$m=New-Object System.Drawing.Bitmap $mw,$mh;$mg=[System.Drawing.Graphics]::FromImage($m)
$mg.SmoothingMode=[System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$mg.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$mg.TextRenderingHint=[System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$mg.Clear([System.Drawing.Color]::FromArgb(245,246,248))
$files=@("c1_colosseum.png","c2_yinyang.png","c3_bubbleA.png","c4_scale.png","c5_swords.png","c6_trophy.png")
$labels=@("7  Colosseum","8  Yin-Yang","9  Bubble A","10  Balance","11  Swords","12  Trophy")
for($i=0;$i -lt 6;$i++){
  $col=$i%$cols;$row=[math]::Floor($i/$cols);$x=$pad+$col*($cell+$pad);$y=$pad+$row*($cell+$labelH+$pad)
  $img=[System.Drawing.Image]::FromFile("$dir\$($files[$i])");$mg.DrawImage($img,$x,$y,$cell,$cell);$img.Dispose()
  $sf=New-Object System.Drawing.StringFormat;$sf.Alignment=1
  $mg.DrawString($labels[$i],(New-Object System.Drawing.Font("Segoe UI",15,[System.Drawing.FontStyle]::Bold)),(SB ([System.Drawing.Color]::FromArgb(30,40,55))),(New-Object System.Drawing.RectangleF $x,($y+$cell+4),$cell,$labelH),$sf)
}
$mg.Dispose();$m.Save("$dir\ALL_OPTIONS2.png",[System.Drawing.Imaging.ImageFormat]::Png);$m.Dispose()
Write-Output "done"
