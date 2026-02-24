# Folder where your raw card PNGs from Inkscape live
$cardFolder = ".\raw_cards"

# Output sheet settings
$cardsPerSheet = 70
$columns = 10
$rows = 7

# Card dimensions (per card)
$cardWidth = 750
$cardHeight = 1050

# Maximum allowed size in TTS
$maxSize = 8192

# Get all PNG files in raw_cards, ignoring previous countersheets
$files = Get-ChildItem "$cardFolder\*.png" |
    Sort-Object { [int]($_.BaseName -replace '\D','') }

# Compute how many sheets are needed
$totalSheets = [math]::Ceiling($files.Count / $cardsPerSheet)

for ($s = 0; $s -lt $totalSheets; $s++) {

    # Determine which cards go in this sheet
    $start = $s * $cardsPerSheet
    $end = [math]::Min($start + $cardsPerSheet - 1, $files.Count - 1)
    $subset = $files[$start..$end] | ForEach-Object { $_.FullName }

    # Temporary master sheet
    $sheetName = "countersheet_$($s+1)_master.png"

    # Create the montage
    magick montage $subset `
        -tile ${columns}x${rows} `
        -geometry ${cardWidth}x${cardHeight}+0+0 `
        $sheetName

    # Get resulting sheet dimensions
    $img = magick identify -format "%w %h" $sheetName
    $dims = $img -split ' '
    $width = [int]$dims[0]
    $height = [int]$dims[1]

    # Compute scale factor to stay under TTS limit
    $scale = [math]::Min([math]::Min($maxSize / $width, $maxSize / $height), 1)
    $percent = [math]::Floor($scale * 100)

    # Final resized sheet
    $finalName = "countersheet_$($s+1).png"
    magick $sheetName -resize "${percent}%" $finalName

    # Clean up master sheet
    Remove-Item $sheetName

    Write-Host "Generated $finalName ($($subset.Count) cards, scale: $percent%)"
}