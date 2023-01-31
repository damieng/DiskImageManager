# Disk Image Manager

Disk Image Manager (previously SPIN Disk Manager) is a cross-platform GUI application for examining and manipulating disk images in the Extended DSK format used by many Spectrum and Amstrad emulators.

Many of this tools features and functions were driven by the Spectrum Disk Preservation team which use this format and tool to help manage the selection and testing of disk images archived to The World of Spectrum and The TZX Vault.

These images are traditionally created with CPDRead under DOS but Simon Owen's mordern [SamDisk](http://simonowen.com/samdisk/) works great under Windows.

## Features

### Images

* Conversion between standard and extended image formats
* Identification of tool that created the image

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
Identification of copy-protection schemes both signed and unsigned versions:

* Alkatraz +3
* Frontier
* Hexagon
* Paul Owens
* Speedlock +3 1987/1988
* Speedlock 1988/1989
* Three Inch Loader type 1/2

### Modification

* Manipulation of controller flags, actual sector sizes and indicated FDC size
* Formatting and unformatting of specific sectors & tracks
* Compress out unused tracks and sectors option 

### Creation

* Formatting of new disk images to known formats
* Formatting of new disk images to custom tailored formats: Sides, tracks per side, sectors per track, sector size, first sector ID, interleave, reverse tracks, skew tracks, skew sides, gap read/write, gap format, directory blocks, block size, filler byte
* Writing of disk boot sectors as part of the image formatting process 

## Building
This application requires the [Lazarus development system](http://www.lazarus.freepascal.org/) and was tested using Lazarus IDE v1.0.14 on Windows 8.1.

To be able to build and visually edit the forms you will need to install the supplied DIMComponents package. To do that:

1. Go to **Package > Open a Package File...**
2. Select the **DIMComponents.lpk** file from the DiskImageManager **Source** folder and press **Open**
3. Press the **Compile** button on the window "Package DimComponents" 
4. Once complete press the **Use >>** button and choose **Install**
5. On completion a DIM tab should appear next to the RTTI tab in the components area below the Lazarus main menu

## Screenshots
![Screenshot identifying a disk format and details](https://cloud.githubusercontent.com/assets/118951/21614473/7996750a-d18e-11e6-8846-09ade9487bb8.png)
![Screenshot showing visual map](https://cloud.githubusercontent.com/assets/118951/21614505/89681434-d18e-11e6-8eee-c0b53a05b11c.png)
![Screenshot with hex sector data](https://cloud.githubusercontent.com/assets/118951/21614520/984b00d8-d18e-11e6-9371-be6766a40d94.png)
![Screenshot showing sector properties](https://cloud.githubusercontent.com/assets/118951/21614531/a7dabbf6-d18e-11e6-9c6a-07e29ee23782.png)
![Screenshot of advanced formatter](https://cloud.githubusercontent.com/assets/118951/21614545/b7a0f1ea-d18e-11e6-8016-c6f178e5155a.png)

## TODO
* Extend support for SamDisk DSK extensions
* Additional disk formats
* Additional copy protection recognition
* Allow file catalog and extract of files

## Licence
Copyright 2002-2023 Damien Guard.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
