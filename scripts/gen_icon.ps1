Add-Type -AssemblyName System.Drawing

$size = 1024
$bmp = New-Object System.Drawing.Bitmap($size, $size)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

function New-RoundRectPath($x, $y, $w, $h, $r) {
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $r * 2
    $path.AddArc($x, $y, $d, $d, 180, 90)
    $path.AddArc(($x + $w - $d), $y, $d, $d, 270, 90)
    $path.AddArc(($x + $w - $d), ($y + $h - $d), $d, $d, 0, 90)
    $path.AddArc($x, ($y + $h - $d), $d, $d, 90, 90)
    $path.CloseFigure()
    return $path
}

function New-Pen($color, $width) {
    $p = New-Object System.Drawing.Pen -ArgumentList @($color, [single]$width)
    return $p
}

# Background: rounded square with diagonal gradient blue -> teal
$bgPath = New-RoundRectPath 0 0 $size $size ($size * 0.22)
$colorBlue = [System.Drawing.Color]::FromArgb(255, 37, 99, 235)   # #2563EB
$colorTeal = [System.Drawing.Color]::FromArgb(255, 20, 184, 166)  # #14B8A6
$pt0 = New-Object System.Drawing.Point -ArgumentList @(0, 0)
$pt1 = New-Object System.Drawing.Point -ArgumentList @($size, $size)
$bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush -ArgumentList @($pt0, $pt1, $colorBlue, $colorTeal)
$g.FillPath($bgBrush, $bgPath)

# Soft shadow ellipse under the pill
$shadowBrush = New-Object System.Drawing.SolidBrush -ArgumentList @([System.Drawing.Color]::FromArgb(60, 0, 0, 0))
$g.FillEllipse($shadowBrush, ($size*0.28), ($size*0.60), ($size*0.46), ($size*0.14))

# --- Capsule (pill) tilted 45 degrees, centered ---
$g.TranslateTransform($size/2, $size/2)
$g.RotateTransform(45)

$capW = $size * 0.62
$capH = $size * 0.27
$capR = $capH / 2
$capPath = New-RoundRectPath (-$capW/2) (-$capH/2) $capW $capH $capR

# clip left half white, right half light blue for two-tone capsule look
$rectLeft = New-Object System.Drawing.RectangleF -ArgumentList @([single](-$capW/2), [single](-$capH/2), [single]($capW/2), [single]$capH)
$rectRight = New-Object System.Drawing.RectangleF -ArgumentList @([single]0, [single](-$capH/2), [single]($capW/2), [single]$capH)
$clipLeft = New-Object System.Drawing.Region -ArgumentList @($rectLeft)
$clipRight = New-Object System.Drawing.Region -ArgumentList @($rectRight)

$oldClip = $g.Clip
$g.Clip = $clipLeft
$whiteBrush = New-Object System.Drawing.SolidBrush -ArgumentList @([System.Drawing.Color]::White)
$g.FillPath($whiteBrush, $capPath)
$g.Clip = $oldClip

$g.Clip = $clipRight
$lightBlueBrush = New-Object System.Drawing.SolidBrush -ArgumentList @([System.Drawing.Color]::FromArgb(255, 186, 230, 253)) # #BAE6FD
$g.FillPath($lightBlueBrush, $capPath)
$g.Clip = $oldClip

# capsule outline
$outlinePen = New-Pen ([System.Drawing.Color]::FromArgb(255, 30, 64, 90)) ($size*0.006)
$g.DrawPath($outlinePen, $capPath)
# center divider line
$g.DrawLine($outlinePen, 0, (-$capH/2), 0, ($capH/2))

$g.ResetTransform()

# --- Clock badge, upper-right ---
$badgeD = $size * 0.30
$badgeX = $size * 0.60
$badgeY = $size * 0.10
$badgeShadow = New-Object System.Drawing.SolidBrush -ArgumentList @([System.Drawing.Color]::FromArgb(50, 0, 0, 0))
$g.FillEllipse($badgeShadow, ($badgeX + $size*0.01), ($badgeY + $size*0.015), $badgeD, $badgeD)

$badgeBrush = New-Object System.Drawing.SolidBrush -ArgumentList @([System.Drawing.Color]::White)
$g.FillEllipse($badgeBrush, $badgeX, $badgeY, $badgeD, $badgeD)
$badgePen = New-Pen ([System.Drawing.Color]::FromArgb(255, 37, 99, 235)) ($size*0.012)
$g.DrawEllipse($badgePen, $badgeX, $badgeY, $badgeD, $badgeD)

$cx = $badgeX + $badgeD/2
$cy = $badgeY + $badgeD/2
$handPen = New-Pen ([System.Drawing.Color]::FromArgb(255, 20, 184, 166)) ($size*0.014)
$handPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
$handPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
# hour hand
$g.DrawLine($handPen, $cx, $cy, ($cx + $badgeD*0.18), ($cy - $badgeD*0.05))
# minute hand
$handPen2 = New-Pen ([System.Drawing.Color]::FromArgb(255, 37, 99, 235)) ($size*0.012)
$handPen2.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
$handPen2.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
$g.DrawLine($handPen2, $cx, $cy, $cx, ($cy - $badgeD*0.28))
# center dot
$dotBrush = New-Object System.Drawing.SolidBrush -ArgumentList @([System.Drawing.Color]::FromArgb(255, 30, 64, 90))
$dotR = $badgeD*0.035
$g.FillEllipse($dotBrush, ($cx - $dotR), ($cy - $dotR), ($dotR*2), ($dotR*2))

$outPath = "C:\Local_Disk_D\App\MedRemind\med_remind_v2\app\assets\icon\MedRemind.png"
$bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)

$g.Dispose()
$bmp.Dispose()
Write-Output "Saved icon to $outPath"
