Add-Type -AssemblyName System.Drawing
$dir = "C:\Users\rahul\Desktop\Apps\arena\playstore\icon_options"
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
$W = 512

function NewCanvas { param($c1,$c2,$angle)
  $bmp = New-Object System.Drawing.Bitmap $W,$W
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode=[System.Drawing.Drawing2D.SmoothingMode]::HighQuality
  $g.CompositingQuality=[System.Drawing.Drawing2D.CompositingQuality]::HighQuality
  $g.TextRenderingHint=[System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
  $r=New-Object System.Drawing.Rectangle 0,0,$W,$W
  $b=New-Object System.Drawing.Drawing2D.LinearGradientBrush($r,$c1,$c2,$angle)
  $g.FillRectangle($b,$r)
  return @($bmp,$g)
}
function Glow { param($g,$cx,$cy,$rad,$col)
  $p=New-Object System.Drawing.Drawing2D.GraphicsPath;$p.AddEllipse($cx-$rad,$cy-$rad,$rad*2,$rad*2)
  $pg=New-Object System.Drawing.Drawing2D.PathGradientBrush $p
  $pg.CenterColor=$col;$pg.SurroundColors=@([System.Drawing.Color]::FromArgb(0,0,0,0))
  $g.FillPath($pg,$p)
}
function RR { param($x,$y,$w,$h,$r)
  $p=New-Object System.Drawing.Drawing2D.GraphicsPath;$d=$r*2
  $p.AddArc($x,$y,$d,$d,180,90);$p.AddArc($x+$w-$d,$y,$d,$d,270,90)
  $p.AddArc($x+$w-$d,$y+$h-$d,$d,$d,0,90);$p.AddArc($x,$y+$h-$d,$d,$d,90,90);$p.CloseFigure();return $p
}
function Save { param($bmp,$name) $bmp[0].Save("$dir\$name",[System.Drawing.Imaging.ImageFormat]::Png);$bmp[1].Dispose();$bmp[0].Dispose() }

$dkNavy=[System.Drawing.Color]::FromArgb(20,25,36); $black=[System.Drawing.Color]::FromArgb(5,6,10)
$blue=[System.Drawing.Color]::FromArgb(46,110,214); $red=[System.Drawing.Color]::FromArgb(230,57,70)
$teal=[System.Drawing.Color]::FromArgb(38,196,180)

# ---------- 1) Face-off figures (blue + ash 3D) ----------
$c=NewCanvas $dkNavy $black 90; $g=$c[1]
Glow $g 256 240 200 ([System.Drawing.Color]::FromArgb(50,60,90,140))
function Figure { param($g,$bodyCx,$headCx,$hi,$dark,$bTop,$bBot,$rim)
  $bp=RR ($bodyCx-95) 300 190 260 95
  $bb=New-Object System.Drawing.Drawing2D.LinearGradientBrush((New-Object System.Drawing.Rectangle ($bodyCx-95),300,190,260),$bTop,$bBot,90)
  $g.FillPath($bb,$bp)
  $hd=156;$hx=$headCx-78;$hy=132
  $hp=New-Object System.Drawing.Drawing2D.GraphicsPath;$hp.AddEllipse($hx,$hy,$hd,$hd)
  $pg=New-Object System.Drawing.Drawing2D.PathGradientBrush $hp
  $pg.CenterPoint=New-Object System.Drawing.PointF ([single]($hx+$hd*0.33)),([single]($hy+$hd*0.30))
  $pg.CenterColor=$hi;$pg.SurroundColors=@($dark);$g.FillPath($pg,$hp)
  $g.DrawEllipse((New-Object System.Drawing.Pen($rim,3)),$hx+2,$hy+2,$hd-4,$hd-4)
}
Figure $g 150 176 ([System.Drawing.Color]::FromArgb(78,116,166)) ([System.Drawing.Color]::FromArgb(9,18,34)) ([System.Drawing.Color]::FromArgb(26,42,72)) ([System.Drawing.Color]::FromArgb(6,11,20)) ([System.Drawing.Color]::FromArgb(120,110,150,205))
Figure $g 362 336 ([System.Drawing.Color]::FromArgb(130,137,146)) ([System.Drawing.Color]::FromArgb(20,22,26)) ([System.Drawing.Color]::FromArgb(44,47,52)) ([System.Drawing.Color]::FromArgb(11,12,14)) ([System.Drawing.Color]::FromArgb(120,160,168,178))
Save $c "opt1_faceoff.png"

# ---------- 2) Versus split (blue vs red + bolt) ----------
$c=NewCanvas $dkNavy $black 90; $g=$c[1]
$lft=New-Object System.Drawing.Drawing2D.GraphicsPath
$lft.AddPolygon(@((New-Object System.Drawing.Point 0,0),(New-Object System.Drawing.Point 300,0),(New-Object System.Drawing.Point 212,512),(New-Object System.Drawing.Point 0,512)))
$lb=New-Object System.Drawing.Drawing2D.LinearGradientBrush((New-Object System.Drawing.Rectangle 0,0,300,512),([System.Drawing.Color]::FromArgb(40,90,190)),([System.Drawing.Color]::FromArgb(10,26,60)),70)
$g.FillPath($lb,$lft)
$rgt=New-Object System.Drawing.Drawing2D.GraphicsPath
$rgt.AddPolygon(@((New-Object System.Drawing.Point 300,0),(New-Object System.Drawing.Point 512,0),(New-Object System.Drawing.Point 512,512),(New-Object System.Drawing.Point 212,512)))
$rb=New-Object System.Drawing.Drawing2D.LinearGradientBrush((New-Object System.Drawing.Rectangle 212,0,300,512),([System.Drawing.Color]::FromArgb(200,44,56)),([System.Drawing.Color]::FromArgb(70,12,18)),70)
$g.FillPath($rb,$rgt)
# glowing bolt
$bolt=New-Object System.Drawing.Drawing2D.GraphicsPath
$bolt.AddPolygon(@((New-Object System.Drawing.Point 300,0),(New-Object System.Drawing.Point 250,0),(New-Object System.Drawing.Point 236,180),(New-Object System.Drawing.Point 268,190),(New-Object System.Drawing.Point 224,360),(New-Object System.Drawing.Point 250,360),(New-Object System.Drawing.Point 212,512),(New-Object System.Drawing.Point 262,512),(New-Object System.Drawing.Point 300,300),(New-Object System.Drawing.Point 262,290),(New-Object System.Drawing.Point 300,120),(New-Object System.Drawing.Point 274,120)))
$g.FillPath((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(245,245,250))),$bolt)
$sf=New-Object System.Drawing.StringFormat;$sf.Alignment=1;$sf.LineAlignment=1
$g.DrawString("VS",(New-Object System.Drawing.Font("Arial Black",70,[System.Drawing.FontStyle]::Bold)),(New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(235,255,255,255))),(New-Object System.Drawing.RectangleF 0,380,512,120),$sf)
Save $c "opt2_versus.png"

# ---------- 3) Clashing speech bubbles (glossy) ----------
$c=NewCanvas $dkNavy $black 90; $g=$c[1]
Glow $g 256 256 210 ([System.Drawing.Color]::FromArgb(45,60,90,140))
# left blue bubble, tail pointing right
$lbub=RR 60 120 250 150 40
$lg=New-Object System.Drawing.Drawing2D.LinearGradientBrush((New-Object System.Drawing.Rectangle 60,120,250,150),([System.Drawing.Color]::FromArgb(70,140,240)),([System.Drawing.Color]::FromArgb(22,60,140)),90)
$g.FillPath($lg,$lbub)
$lt=New-Object System.Drawing.Drawing2D.GraphicsPath;$lt.AddPolygon(@((New-Object System.Drawing.Point 250,262),(New-Object System.Drawing.Point 320,300),(New-Object System.Drawing.Point 230,270)))
$g.FillPath((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(40,100,200))),$lt)
# right red bubble, tail pointing left
$rbub=RR 202 260 250 150 40
$rg=New-Object System.Drawing.Drawing2D.LinearGradientBrush((New-Object System.Drawing.Rectangle 202,260,250,150),([System.Drawing.Color]::FromArgb(240,80,92)),([System.Drawing.Color]::FromArgb(150,24,32)),90)
$g.FillPath($rg,$rbub)
$rt=New-Object System.Drawing.Drawing2D.GraphicsPath;$rt.AddPolygon(@((New-Object System.Drawing.Point 262,260),(New-Object System.Drawing.Point 192,222),(New-Object System.Drawing.Point 282,252)))
$g.FillPath((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(200,50,60))),$rt)
$wd=New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(235,255,255,255))
foreach($i in 0,1,2){ $g.FillEllipse($wd,(120+$i*52),178,30,30) }
foreach($i in 0,1,2){ $g.FillEllipse($wd,(262+$i*52),318,30,30) }
Save $c "opt3_bubbles.png"

# ---------- 4) Bold A monogram (gradient) ----------
$c=NewCanvas $dkNavy $black 90; $g=$c[1]
Glow $g 256 256 210 ([System.Drawing.Color]::FromArgb(55,60,90,150))
$sf=New-Object System.Drawing.StringFormat;$sf.Alignment=1;$sf.LineAlignment=1
$ab=New-Object System.Drawing.Drawing2D.LinearGradientBrush((New-Object System.Drawing.Rectangle 100,80,312,360),([System.Drawing.Color]::FromArgb(90,170,255)),([System.Drawing.Color]::FromArgb(30,120,150)),90)
$g.DrawString("A",(New-Object System.Drawing.Font("Arial Black",300,[System.Drawing.FontStyle]::Bold)),$ab,(New-Object System.Drawing.RectangleF 6,-30,512,512),$sf)
Save $c "opt4_monogram.png"

# ---------- 5) Flame (on-brand) ----------
$c=NewCanvas ([System.Drawing.Color]::FromArgb(24,20,28)) $black 90; $g=$c[1]
Glow $g 256 300 200 ([System.Drawing.Color]::FromArgb(70,230,90,40))
$flame=New-Object System.Drawing.Drawing2D.GraphicsPath
$flame.AddClosedCurve(@(
 (New-Object System.Drawing.PointF 256,80),(New-Object System.Drawing.PointF 320,180),
 (New-Object System.Drawing.PointF 330,270),(New-Object System.Drawing.PointF 356,360),
 (New-Object System.Drawing.PointF 300,440),(New-Object System.Drawing.PointF 256,452),
 (New-Object System.Drawing.PointF 212,440),(New-Object System.Drawing.PointF 156,360),
 (New-Object System.Drawing.PointF 182,270),(New-Object System.Drawing.PointF 196,180)
),0.4)
$fg=New-Object System.Drawing.Drawing2D.LinearGradientBrush((New-Object System.Drawing.Rectangle 150,80,220,380),([System.Drawing.Color]::FromArgb(255,90,40)),([System.Drawing.Color]::FromArgb(255,205,0)),90)
$g.FillPath($fg,$flame)
$inner=New-Object System.Drawing.Drawing2D.GraphicsPath
$inner.AddClosedCurve(@(
 (New-Object System.Drawing.PointF 256,210),(New-Object System.Drawing.PointF 296,300),
 (New-Object System.Drawing.PointF 300,370),(New-Object System.Drawing.PointF 256,420),
 (New-Object System.Drawing.PointF 212,370),(New-Object System.Drawing.PointF 216,300)
),0.4)
$ig=New-Object System.Drawing.Drawing2D.LinearGradientBrush((New-Object System.Drawing.Rectangle 210,210,90,220),([System.Drawing.Color]::FromArgb(255,225,90)),([System.Drawing.Color]::FromArgb(255,255,220)),90)
$g.FillPath($ig,$inner)
Save $c "opt5_flame.png"

# ---------- 6) VS circle badge (two-tone) ----------
$c=NewCanvas $dkNavy $black 90; $g=$c[1]
$circle=New-Object System.Drawing.Drawing2D.GraphicsPath;$circle.AddEllipse(86,86,340,340)
$g.SetClip($circle)
$g.FillRectangle((New-Object System.Drawing.Drawing2D.LinearGradientBrush((New-Object System.Drawing.Rectangle 86,86,170,340),([System.Drawing.Color]::FromArgb(46,104,200)),([System.Drawing.Color]::FromArgb(16,40,96)),90)),(New-Object System.Drawing.Rectangle 86,86,170,340))
$g.FillRectangle((New-Object System.Drawing.Drawing2D.LinearGradientBrush((New-Object System.Drawing.Rectangle 256,86,170,340),([System.Drawing.Color]::FromArgb(210,50,62)),([System.Drawing.Color]::FromArgb(96,16,22)),90)),(New-Object System.Drawing.Rectangle 256,86,170,340))
$g.ResetClip()
$g.DrawEllipse((New-Object System.Drawing.Pen(([System.Drawing.Color]::FromArgb(180,255,255,255)),5)),86,86,340,340)
$sf=New-Object System.Drawing.StringFormat;$sf.Alignment=1;$sf.LineAlignment=1
$g.DrawString("VS",(New-Object System.Drawing.Font("Arial Black",120,[System.Drawing.FontStyle]::Bold)),(New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)),(New-Object System.Drawing.RectangleF 0,0,512,512),$sf)
Save $c "opt6_vsbadge.png"

# ---------- montage ----------
$cols=3;$rows=2;$cell=256;$pad=20;$labelH=34
$mw=$cols*$cell+($cols+1)*$pad; $mh=$rows*($cell+$labelH)+($rows+1)*$pad
$m=New-Object System.Drawing.Bitmap $mw,$mh
$mg=[System.Drawing.Graphics]::FromImage($m)
$mg.SmoothingMode=[System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$mg.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$mg.TextRenderingHint=[System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$mg.Clear([System.Drawing.Color]::FromArgb(245,246,248))
$files=@("opt1_faceoff.png","opt2_versus.png","opt3_bubbles.png","opt4_monogram.png","opt5_flame.png","opt6_vsbadge.png")
$labels=@("1  Face-off","2  Versus","3  Bubbles","4  A monogram","5  Flame","6  VS badge")
for($i=0;$i -lt 6;$i++){
  $col=$i%$cols;$row=[math]::Floor($i/$cols)
  $x=$pad+$col*($cell+$pad); $y=$pad+$row*($cell+$labelH+$pad)
  $img=[System.Drawing.Image]::FromFile("$dir\$($files[$i])")
  $mg.DrawImage($img,$x,$y,$cell,$cell);$img.Dispose()
  $sf=New-Object System.Drawing.StringFormat;$sf.Alignment=1
  $mg.DrawString($labels[$i],(New-Object System.Drawing.Font("Segoe UI",15,[System.Drawing.FontStyle]::Bold)),(New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(30,40,55))),(New-Object System.Drawing.RectangleF $x,($y+$cell+4),$cell,$labelH),$sf)
}
$mg.Dispose();$m.Save("$dir\ALL_OPTIONS.png",[System.Drawing.Imaging.ImageFormat]::Png);$m.Dispose()
Write-Output "Generated 6 icons + montage in $dir"
