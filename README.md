# Disk Image Manager

Disk Image Manager is an application for examining and manipulating disk images in the Standard and Extended DSK format used by many Spectrum, Amstrad PCW and CPC emulators.

Many of this tools features and functions were driven by the Spectrum Disk Preservation team which used this format and tool to help manage the selection and testing of disk images archived to The World of Spectrum and The TZX Vault.

These images are traditionally created with CPDRead under DOS but Simon Owen's mordern [SamDisk](http://simonowen.com/samdisk/) works great under Windows and provides for much more advanced imaging especially around copy-protected disks.

## Features

### Images

* Conversion between standard and extended image formats
* Identification of tool that created the image
* List all ASCII strings found on a disk image

### Analysis

* Display of extended disk parameter block (XDPB)
* Boot compatibility: Amstrad PCW 9512, Amstrad PCW 8256, Amstrad CPC 664/6128, Sinclair Spectrum +3
* Visual customisable map of space utilisation, track structure and controller flags
* Save visual map to bitmap
* Hex and ASCII display of sector data
* Search sector data for ASCII data 

### Disk format identification

Capable of identifying the following original disk formats even when de-skewed by image tools.

* Amstrad PCW 9512
* Amstrad PCW 8256 (CF2/CF2DD variants)
* Amstrad CPC system
* Amstrad CPC data
* Spectrum +3
* Ultra 208 (Chris Pile)
* HiForm 208/203 (Ian Collier)
* Supermat 192/XCF2
* MGT SAM Coupe BDOS
* SAMDOS
* MasterDOS

### Copy protection identification

Identification of copy-protection schemes both signed and somtimes unsigned:

* Alkatraz +3/CPC
* Frontier
* Hexagon
* Paul Owens
* Speedlock +3 1987/1988
* Speedlock 1985/1986//1987/1987v2.1/1988/1989/1990
* Three Inch Loader type 1/2/3
* Laser Load
* W.R.M Disc Protection (Martech)
* P.M.S. Loader 1986/1987
* Players 16-sector
* ERE/Remi HERBULOT
* KBI-19/KBI-10/CAAV
* DiscSYS 2/2.5/3/Mean
* Amsoft EXOPAL
* ARMORLOC
* Studio B Disc format
* DiscLoc by Oddball

### File system

* Can list a CP/M file system such as used on +3, PCW and CPC.
* Understands +3 DOS and CPC file headers
* Experimental binary "File save as..." available from file entry.

### Modification

* Manipulation of controller flags, actual sector sizes and indicated FDC size
* Formatting and unformatting of specific sectors & tracks
* Compress out unused tracks and sectors option 

### Creation

* Formatting of new disk images to known formats
* Formatting of new disk images to custom tailored formats: Sides, tracks per side, sectors per track, sector size, first sector ID, interleave, reverse tracks, skew tracks, skew sides, gap read/write, gap format, directory blocks, block size, filler byte
* Writing of disk boot sectors as part of the image formatting process 

## Building
This application requires the [Lazarus development system](http://www.lazarus.freepascal.org/) and was tested using Lazarus IDE v2.2.4 on Windows 11.

To be able to build and visually edit the forms you will need to install the supplied DIMComponents package. To do that:

1. Go to **Package > Open a Package File...**
2. Select the **DIMComponents.lpk** file from the DiskImageManager **Source** folder and press **Open**
3. Press the **Compile** button on the window "Package DimComponents" 
4. Once complete press the **Use >>** button and choose **Install**
5. On completion a DIM tab should appear next to the RTTI tab in the components area below the Lazarus main menu

## Screenshots

![Screenshot identifying a disk format and details](https://user-images.githubusercontent.com/118951/216734998-c292ac84-72ac-494b-af85-fba73b3bcefa.png)
![Screenshot showing visual map](https://user-images.githubusercontent.com/118951/216735001-94cdd473-3fa1-414b-85b4-16d61604a1f5.png)
![Screenshot with hex sector data](https://user-images.githubusercontent.com/118951/216734940-e23a997e-6ae4-4dcf-ad9e-97ec33795278.png)
![Screenshot showing sector properties](https://user-images.githubusercontent.com/118951/216734959-67a68b52-5f0e-4d28-812f-c9cf1edbaaf9.png)
![Screenshot of advanced formatter](https://user-images.githubusercontent.com/118951/216734979-edae81e3-bc49-44b1-80a8-fe19f41c2e13.png)

## TODO

* Extend support for SamDisk DSK extensions

## Licence

Copyright 2002-2023 Damien Guard.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
