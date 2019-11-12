[CmdletBinding()]
Param(
  [Parameter()]
  [string]$fips = "01",
  [Parameter()]
  [string]$path = '',
  [Parameter()]
  [int]$width = 960,
  [Parameter()]
  [int]$height = 960,
  [Parameter()]
  [string]$scheme = "schemeOrRd"
)

$shape = "cb_2014_$($fips)_tract_500k"
$census = "cb_2014_$($fips)_tract_DP02_0001E"

Write-Output "$($path)maps/$($shape).zip"
Write-Output "$($path)maps/$($census).json"

if (Test-Path -Path "$($path)maps/$($shape).zip" -PathType Leaf) {
  if (Test-Path -Path "$($path)census/$($census).json" -PathType Leaf) {

    if (!(Test-Path -Path "$($path)data" -PathType Container)) {
      New-Item -Path $path -Name "data" -ItemType "directory" -Force | Out-Null
    }

    if (!(Test-Path -Path "$($path)images" -PathType Container)) {
      New-Item -Path $path -Name "images" -ItemType "directory" -Force | Out-Null
    }

    $state = (Get-Content "$($path)data.json" | ConvertFrom-Json).states | Where-Object { $_.fips -eq $fips }

    if (!($state)) {
      Write-Output "$($fips) is not contained in data.json"
      Exit
    }

    Expand-Archive -Path "$($path)maps/$($shape).zip" -DestinationPath "$($path)maps/$($shape)" -Force

    shp2json "$($path)maps/$($shape)/$($shape).shp" | `
      geoproject "d3.$($state.projection).fitSize([$width, $height], d)" | `
      ndjson-split "d.features" | `
      ndjson-map "d.id = d.properties.GEOID.slice(2), d" > `
      "$($path)data/$($state.name).ndjson"

    ndjson-cat "$($path)census/$($census).json" | `
      cmd /c "ndjson-split `"d.slice(1)`"" | `
      ndjson-map "{id: d[2] + d[3], DP02_0001E: +d[0]}" > `
      "$($path)data/$($state.name)-census.ndjson"

    ndjson-join "d.id" "$($path)data/$($state.name).ndjson" "$($path)data/$($state.name)-census.ndjson" | `
      ndjson-map "d[0].properties = {density: Math.floor(d[1].DP02_0001E / d[0].properties.ALAND * 2589975.2356)}, d[0]" > `
      "$($path)data/$($state.name)-density.ndjson"

    Get-Content "$($path)data/$($state.name)-density.ndjson" | `
      geo2topo -n tracts="$($path)data/$($state.name)-density.ndjson" | `
      toposimplify -p 1 -f | `
      topoquantize 1e5 | `
      topomerge -k "d.id.slice(0, 3)" counties=tracts | `
      topomerge --mesh -f "a !== b" counties=counties > `
      "$($path)data/$($state.name)-topo.json"

    Get-Content "$($path)data/$($state.name)-topo.json" | `
      topo2geo tracts=- | `
      ndjson-map -r d3 -r d3-scale-chromatic "z = d3.scaleThreshold().domain([1, 10, 50, 200, 500, 1000, 2000, 4000]).range(d3.$($scheme)[9]), d.features.forEach(f => f.properties.fill = z(f.properties.density)), d" | `
      ndjson-split "d.features" > `
      "$($path)data/$($state.name)-colorized-topo.ndjson"

    Get-Content "$($path)data/$($state.name)-colorized-topo.ndjson" | `
      geo2svg -n --stroke none -p 1 -w $width -h $height > `
      "$($path)images/$($state.name).svg"

    Remove-Item "$($path)maps/$($shape)" -Force -Recurse
    Remove-Item "$($path)data" -Force -Recurse
  }
  else {
    ThrowError -ExceptionMessage "$($fips) does not have associated census data"
  }
}
else {
  ThrowError -ExceptionMessage "$($fips) is an invalid FIPS code"
}