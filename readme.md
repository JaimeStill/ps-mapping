# PowerShell Mapping Data Visualization

* [Setup](#setup)
* [Overview](#overview)
* [Run](#run)

[![texas](https://user-images.githubusercontent.com/14102723/68511018-f59c9c00-0242-11ea-8294-17dd565991a8.png)](https://user-images.githubusercontent.com/14102723/68511018-f59c9c00-0242-11ea-8294-17dd565991a8.png)

## Setup
[Back to Top](#powershell-mapping-data-visualization)

> I'm not sure entirely why, but getting the npm packages to play nice with PowerShell required me to install globally with both package managers. This is something I intend to troubleshoot further.

In order to run this, you will need to have the following installed:

* [NodeJS](https://nodejs.org)
* [Yarn](https://yarnpkg.com)
* [PowerShell Core](https://github.com/PowerShell/PowerShell#get-powershell)
  * This was built and tested with PowerShell Core. Your mileage may vary in other PS environments

With these installed, you will need the following packages installed globally:

```
yarn global add shapefile d3 d3-geo-projection d3-scale-chromatic ndjson-cli topojson-server topojson-client topojson-simplify
```

and

```
npm install -g shapefile d3 d3-geo-projection d3-scale-chromatic ndjson-cli topojson-server topojson-client topojson-simplify
```

## Overview
[Back to Top](#powershell-mapping-data-visualization)

This repository provides me with an initial starting point for automating data visualizations in a disconnected environment.

I initially started by going through **Mike Bostock's** [Command Line Cartography](https://medium.com/@mbostock/command-line-cartography-part-1-897aa8f8ca2c), but worked through it using the state of [Texas](https://github.com/JaimeStill/mapping-research/blob/master/texas/texas-choropleth.md).

Now that I have a better understanding of it, and the way it works translated from bash to cmd, I wanted to try to make it more dynamic by building it as a PowerShell script that can generate the same choropleths, but with the state, size, and color scale determined at runtime.

## Run
[Back to Top](#powershell-mapping-data-visualization)

**Parameters**

Parameter | Type | Description
----------|------|------------
`fips` | string | Specifies the [FIPS Code](https://en.wikipedia.org/wiki/Federal_Information_Processing_Standard_state_code) corresponding to the state to generate a choropleth for (the 50 states and Puerto Rico are supported).
`width` | int | Width in pixels of the generated choropleth
`height` | int | Height in pixels of the generated choropleth
`scheme` | string | A supported [d3-scale-chromatic](https://github.com/d3/d3-scale-chromatic) scheme. Should start with *scheme* and accept an array index, for instance, `d3.schemeBuPu[k]`

### Demonstrations
[Back to Top](#powershell-mapping-data-visualization)

**Florida**

```
create-choropleth.ps1 -fips "12" -scheme "schemeSpectral"
```

Generates the following:

[![florida](https://user-images.githubusercontent.com/14102723/68510743-48c21f00-0242-11ea-889b-928869d2afe0.png)](https://user-images.githubusercontent.com/14102723/68510743-48c21f00-0242-11ea-889b-928869d2afe0.png)

**North Carolina**

```
create-choropleth.ps1 -fips "37" -scheme "schemeBuGn"
```

Generates the following:

[![north-carolina](https://user-images.githubusercontent.com/14102723/68511396-de11e300-0243-11ea-90be-c879a5e28062.png)](https://user-images.githubusercontent.com/14102723/68511396-de11e300-0243-11ea-90be-c879a5e28062.png)

**Virginia**

```
create-choropleth.ps1 -fips "51" -scheme "schemeBuPu"
```

Generates the following:

[![virginia](https://user-images.githubusercontent.com/14102723/68511512-229d7e80-0244-11ea-98c6-90a951306f73.png)](https://user-images.githubusercontent.com/14102723/68511512-229d7e80-0244-11ea-98c6-90a951306f73.png)