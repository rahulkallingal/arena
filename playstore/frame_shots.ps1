Add-Type -AssemblyName System.Drawing
$raw="C:\Users\rahul\Desktop\Apps\arena\playstore\raw"
$out="C:\Users\rahul\Desktop\Apps\arena\playstore\screenshots"
if(-not(Test-Path $out)){New-Item -ItemType Directory -Path $out|Out-Null}

function RR{param($x,$y,$w,$h,$r)$p=New-Object System.Drawing.Drawing2D.GraphicsPath;$d=$r*2
 $p.AddArc($x,$y,$d,$d,180,90);$p.AddArc($x+$w-$d,$y,$d,$d,270,90);$p.AddArc($x+$w-$d,$y+$h-$d,$d,$d,0,90);$p.AddArc($x,$y+$h-$d,$d,$d,90,90);$p.CloseFigure();return $p}

$W=1080;$H=1920
$shots=@(
 @{src="s1.png";cap="Fresh debates every day";accent="Topic of the Day"},
 @{src="s2.png";cap="Pick your side";accent="For or Against"},
 @{src="s5.png";cap="Argue it out. See who's winning";accent="Live voting"}
)
$idx=1
foreach($s in $shots){
 $bmp=New-Object System.Drawing.Bitmap $W,$H
 $g=[System.Drawing.Graphics]::FromImage($bmp)
 $g.SmoothingMode=[System.Drawing.Drawing2D.SmoothingMode]::HighQuality
 $g.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
 $g.TextRenderingHint=[System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
 # bg gradient
 $r=New-Object System.Drawing.Rectangle 0,0,$W,$H
 $g.FillRectangle((New-Object System.Drawing.Drawing2D.LinearGradientBrush($r,([System.Drawing.Color]::FromArgb(24,32,50)),([System.Drawing.Color]::FromArgb(9,12,22)),90)),$r)
 # accent kicker
 $sf=New-Object System.Drawing.StringFormat;$sf.Alignment=1
 $g.DrawString($s.accent.ToUpper(),(New-Object System.Drawing.Font("Segoe UI",20,[System.Drawing.FontStyle]::Bold)),(New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(245,150,60))),(New-Object System.Drawing.RectangleF 0,70,$W,40),$sf)
 # caption (white, bold)
 $g.DrawString($s.cap,(New-Object System.Drawing.Font("Segoe UI",44,[System.Drawing.FontStyle]::Bold)),(New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)),(New-Object System.Drawing.RectangleF 40,118,($W-80),120),$sf)
 # phone screenshot scaled to fit
 $img=[System.Drawing.Image]::FromFile("$raw\$($s.src)")
 $tw=720;$th=[int]($img.Height*($tw/$img.Width))   # 720 x 1600
 $px=[int](($W-$tw)/2);$py=270
 # shadow
 $g.FillPath((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(120,0,0,0))),(RR ($px+8) ($py+12) $tw $th 34))
 # clip to rounded rect and draw
 $clip=RR $px $py $tw $th 34
 $st=$g.Save();$g.SetClip($clip)
 $g.DrawImage($img,$px,$py,$tw,$th)
 $g.Restore($st)
 $g.DrawPath((New-Object System.Drawing.Pen(([System.Drawing.Color]::FromArgb(60,255,255,255)),2)),$clip)
 $img.Dispose();$g.Dispose()
 $bmp.Save("$out\shot$idx.png",[System.Drawing.Imaging.ImageFormat]::Png);$bmp.Dispose()
 $idx++
}

# preview montage (side by side, scaled)
$sw=320;$sh=[int](1920*($sw/1080));$pad=20
$mw=3*$sw+4*$pad;$mh=$sh+2*$pad
$m=New-Object System.Drawing.Bitmap $mw,$mh;$mg=[System.Drawing.Graphics]::FromImage($m)
$mg.SmoothingMode=[System.Drawing.Drawing2D.SmoothingMode]::HighQuality;$mg.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$mg.Clear([System.Drawing.Color]::FromArgb(238,240,243))
for($i=1;$i -le 3;$i++){$img=[System.Drawing.Image]::FromFile("$out\shot$i.png");$mg.DrawImage($img,($pad+($i-1)*($sw+$pad)),$pad,$sw,$sh);$img.Dispose()}
$mg.Dispose();$m.Save("$out\ALL_SHOTS.png",[System.Drawing.Imaging.ImageFormat]::Png);$m.Dispose()
Write-Output "framed 3 screenshots (1080x1920) + preview"
