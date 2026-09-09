# Animated GIF encoder using only Windows PowerShell and System.Drawing.
param(
    [Parameter(Mandatory = $true)]
    [string]$Job
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

function Read-SubBlocks([byte[]]$Bytes, [ref]$Pos) {
    $start = $Pos.Value
    while ($Pos.Value -lt $Bytes.Length) {
        $len = $Bytes[$Pos.Value]
        $Pos.Value++
        if ($len -eq 0) {
            break
        }
        $Pos.Value += $len
    }
    $count = $Pos.Value - $start
    $part = New-Object byte[] $count
    [Array]::Copy($Bytes, $start, $part, 0, $count)
    return $part
}

function Get-LocalColorTableSize([byte]$Packed) {
    if (($Packed -band 0x80) -eq 0) {
        return 0
    }
    return 3 * [int][Math]::Pow(2, ($Packed -band 0x07) + 1)
}

function Convert-PngToGifBytes([string]$Path) {
    $fileBytes = [System.IO.File]::ReadAllBytes($Path)
    $inStream = New-Object System.IO.MemoryStream(,$fileBytes)
    $src = [System.Drawing.Image]::FromStream($inStream, $false, $true)
    $bmp = New-Object System.Drawing.Bitmap($src.Width, $src.Height, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear([System.Drawing.Color]::White)
    $g.DrawImage($src, 0, 0, $src.Width, $src.Height)
    $g.Dispose()
    $src.Dispose()
    $inStream.Dispose()

    $gifStream = New-Object System.IO.MemoryStream
    $bmp.Save($gifStream, [System.Drawing.Imaging.ImageFormat]::Gif)
    $bmp.Dispose()
    $bytes = $gifStream.ToArray()
    $gifStream.Dispose()
    return $bytes
}

function Get-GifFrameInfo([byte[]]$Bytes) {
    if ($Bytes.Length -lt 13) {
        throw "GIF data is too small."
    }

    $pos = 13
    $lsdPacked = $Bytes[10]
    $gctSize = 0
    $gct = $null
    if (($lsdPacked -band 0x80) -ne 0) {
        $gctSize = 3 * [int][Math]::Pow(2, ($lsdPacked -band 0x07) + 1)
        $gct = New-Object byte[] $gctSize
        [Array]::Copy($Bytes, $pos, $gct, 0, $gctSize)
        $pos += $gctSize
    }

    $imageStart = -1
    while ($pos -lt $Bytes.Length) {
        $b = $Bytes[$pos]
        if ($b -eq 0x3B) {
            break
        }
        elseif ($b -eq 0x21) {
            $pos += 2
            [void](Read-SubBlocks $Bytes ([ref]$pos))
        }
        elseif ($b -eq 0x2C) {
            $imageStart = $pos
            break
        }
        else {
            throw "Unexpected GIF block 0x$($b.ToString('X2'))."
        }
    }

    if ($imageStart -lt 0) {
        throw "GIF frame has no image data."
    }

    $desc = New-Object byte[] 10
    [Array]::Copy($Bytes, $imageStart, $desc, 0, 10)
    $width = [BitConverter]::ToUInt16($desc, 5)
    $height = [BitConverter]::ToUInt16($desc, 7)
    $packed = $desc[9]
    $pos = $imageStart + 10
    $lctSize = Get-LocalColorTableSize $packed
    $lct = $null
    if ($lctSize -gt 0) {
        $lct = New-Object byte[] $lctSize
        [Array]::Copy($Bytes, $pos, $lct, 0, $lctSize)
        $pos += $lctSize
    }

    $rasterStart = $pos
    $minCode = $Bytes[$pos]
    $pos++
    [void]$minCode
    [void](Read-SubBlocks $Bytes ([ref]$pos))
    $rasterLen = $pos - $rasterStart
    $raster = New-Object byte[] $rasterLen
    [Array]::Copy($Bytes, $rasterStart, $raster, 0, $rasterLen)

    $useTable = $lct
    $tableSizeBits = $packed -band 0x07
    if ($useTable -eq $null) {
        if ($gct -eq $null) {
            throw "GIF frame has no color table."
        }
        $useTable = $gct
        $tableSizeBits = $lsdPacked -band 0x07
    }

    $newPacked = [byte](($packed -band 0x78) -bor 0x80 -bor $tableSizeBits)
    $newDesc = New-Object byte[] 10
    [Array]::Copy($desc, $newDesc, 10)
    $newDesc[1] = 0
    $newDesc[2] = 0
    $newDesc[3] = 0
    $newDesc[4] = 0
    $newDesc[9] = $newPacked

    return @{
        Width      = [int]$width
        Height     = [int]$height
        Descriptor = $newDesc
        ColorTable = $useTable
        Raster     = $raster
    }
}

function Write-Gce([System.IO.BinaryWriter]$Writer, [int]$DelayMs) {
    $hundredths = [int][Math]::Max(1, [Math]::Round($DelayMs / 10.0))
    if ($hundredths -gt 65535) {
        $hundredths = 65535
    }
    $delayBytes = [BitConverter]::GetBytes([uint16]$hundredths)
    $Writer.Write([byte]0x21)
    $Writer.Write([byte]0xF9)
    $Writer.Write([byte]0x04)
    $Writer.Write([byte]0x08)
    $Writer.Write($delayBytes[0])
    $Writer.Write($delayBytes[1])
    $Writer.Write([byte]0x00)
    $Writer.Write([byte]0x00)
}

$ErrorFile = Join-Path $env:TEMP "gifmaker_err.txt"
try {
    if (Test-Path -LiteralPath $ErrorFile) {
        Remove-Item -LiteralPath $ErrorFile -Force
    }

    if (-not (Test-Path -LiteralPath $Job)) {
        throw "Job file not found: $Job"
    }

    $jobObj = Get-Content -LiteralPath $Job -Raw -Encoding UTF8 | ConvertFrom-Json
    $frames = @($jobObj.frames)
    if ($frames.Count -lt 1) {
        throw "Job has no frames."
    }

    $frameInfos = New-Object System.Collections.Generic.List[object]
    $maxW = 1
    $maxH = 1
    foreach ($frame in $frames) {
        $path = [string]$frame.path
        if (-not $path -or -not (Test-Path -LiteralPath $path)) {
            throw "Frame not found: $path"
        }
        $gifBytes = Convert-PngToGifBytes $path
        $info = Get-GifFrameInfo $gifBytes
        $info.DelayMs = [int]$frame.delayMs
        $frameInfos.Add($info)
        if ($info.Width -gt $maxW) { $maxW = $info.Width }
        if ($info.Height -gt $maxH) { $maxH = $info.Height }
    }

    $outPath = [string]$jobObj.output
    if (-not $outPath) {
        throw "Job has no output path."
    }
    $outDir = Split-Path -Parent $outPath
    if ($outDir -and -not (Test-Path -LiteralPath $outDir)) {
        New-Item -ItemType Directory -Path $outDir | Out-Null
    }

    $ms = New-Object System.IO.MemoryStream
    $writer = New-Object System.IO.BinaryWriter($ms)

    $header = [System.Text.Encoding]::ASCII.GetBytes("GIF89a")
    $writer.Write($header)

    $writer.Write([BitConverter]::GetBytes([uint16]$maxW))
    $writer.Write([BitConverter]::GetBytes([uint16]$maxH))
    $writer.Write([byte]0x80)
    $writer.Write([byte]0x00)
    $writer.Write([byte]0x00)
    $writer.Write([byte]0x00); $writer.Write([byte]0x00); $writer.Write([byte]0x00)
    $writer.Write([byte]0xFF); $writer.Write([byte]0xFF); $writer.Write([byte]0xFF)

    $writer.Write([byte]0x21)
    $writer.Write([byte]0xFF)
    $writer.Write([byte]0x0B)
    $writer.Write([System.Text.Encoding]::ASCII.GetBytes("NETSCAPE2.0"))
    $writer.Write([byte]0x03)
    $writer.Write([byte]0x01)
    $writer.Write([byte]0x00)
    $writer.Write([byte]0x00)
    $writer.Write([byte]0x00)

    foreach ($info in $frameInfos) {
        Write-Gce $writer $info.DelayMs
        $writer.Write($info.Descriptor)
        $writer.Write($info.ColorTable)
        $writer.Write($info.Raster)
    }

    $writer.Write([byte]0x3B)
    $writer.Flush()
    [System.IO.File]::WriteAllBytes($outPath, $ms.ToArray())
    $writer.Dispose()
    $ms.Dispose()
    exit 0
}
catch {
    $msg = $_.Exception.Message
    Set-Content -LiteralPath $ErrorFile -Value $msg -Encoding UTF8
    exit 1
}
