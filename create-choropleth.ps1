[CmdletBinding()]
Param(
  [Parameter()]
  [string]$fips = "01",
  [Parameter()]
  [int]$width = 960,
  [Parameter()]
  [int]$height = 960,
  [Parameter()]
  [string]$scheme = "schemeOrRd"
)

$shape = "cb_2014_$($fips)_tract_500k"
$census = "cb_2014_$($fips)_tract_DP02_0001E"

if (Test-Path -Path "maps/$($shape).zip" -PathType Leaf) {
  if (Test-Path -Path "census/$($census).json" -PathType Leaf) {

    if (!(Test-Path -Path "data" -PathType Container)) {
      New-Item -Name "data" -ItemType "directory" -Force | Out-Null
    }

    if (!(Test-Path -Path "images" -PathType Container)) {
      New-Item -Name "images" -ItemType "directory" -Force | Out-Null
    }

    $state = (Get-Content "data.json" | ConvertFrom-Json).states | Where-Object { $_.fips -eq $fips }

    if (!($state)) {
      Write-Output "$($fips) is not contained in data.json"
      Exit
    }

    Expand-Archive -Path "maps/$($shape).zip" -DestinationPath "maps/$($shape)" -Force

    shp2json "maps/$($shape)/$($shape).shp" | `
      geoproject "d3.$($state.projection).fitSize([$width, $height], d)" | `
      ndjson-split "d.features" | `
      ndjson-map "d.id = d.properties.GEOID.slice(2), d" > `
      "data/$($state.name).ndjson"

    ndjson-cat "census/$($census).json" | `
      cmd /c "ndjson-split `"d.slice(1)`"" | `
      ndjson-map "{id: d[2] + d[3], DP02_0001E: +d[0]}" > `
      "data/$($state.name)-census.ndjson"

    ndjson-join "d.id" "data/$($state.name).ndjson" "data/$($state.name)-census.ndjson" | `
      ndjson-map "d[0].properties = {density: Math.floor(d[1].DP02_0001E / d[0].properties.ALAND * 2589975.2356)}, d[0]" > `
      "data/$($state.name)-density.ndjson"

    Get-Content "data/$($state.name)-density.ndjson" | `
      geo2topo -n tracts="data/$($state.name)-density.ndjson" | `
      toposimplify -p 1 -f | `
      topoquantize 1e5 | `
      topomerge -k "d.id.slice(0, 3)" counties=tracts | `
      topomerge --mesh -f "a !== b" counties=counties > `
      "data/$($state.name)-topo.json"

    Get-Content "data/$($state.name)-topo.json" | `
      topo2geo tracts=- |
      ndjson-map -r d3 -r d3-scale-chromatic "z = d3.scaleThreshold().domain([1, 10, 50, 200, 500, 1000, 2000, 4000]).range(d3.$($scheme)[9]), d.features.forEach(f => f.properties.fill = z(f.properties.density)), d" | `
      ndjson-split "d.features" > `
      "data/$($state.name)-colorized-topo.ndjson"

    Get-Content "data/$($state.name)-colorized-topo.ndjson" | `
      geo2svg -n --stroke none -p 1 -w $width -h $height > `
      "images/$($state.name).svg"

    Remove-Item "maps/$($shape)" -Force -Recurse
    Remove-Item "data" -Force -Recurse
  }
  else {
    Write-Output "$($fips) does not have associated census data"
  }
}
else {
  Write-Output "$($fips) is an invalid FIPS code"
}