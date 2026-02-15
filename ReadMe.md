# GRIB2-to-NetCDF-Pipeline

## Overview
This project provides a reproducible workflow for downloading and processing **NCAR GFS (Global Forecast System)** data in **Google Colab**.  
It focuses on forecast hours **003** and **006**, converting raw GRIB2 files into clean NetCDF outputs suitable for climate and meteorological analysis.  
The pipeline is designed for **Colab data processing** environments, ensuring outputs are zipped, labeled by date range, and safely stored in Google Drive to avoid runtime data loss.

## Features
- 📥 Automated download of GFS GRIB2 files (003 and 006 forecast hours)
- 🗂 Organized storage by year and forecast cycle (00, 06, 12, 18)
- ✂️ Spatial cropping with `wgrib2` using bounding boxes
- 🔎 Variable selection (temperature, humidity, wind, precipitation, etc.)
- 🔄 Conversion to NetCDF format
- 🏷 Variable renaming and attribute annotation with `nco`
- 🚀 Parallel processing with GNU `parallel`
- 📦 Automatic zipping and saving to Google Drive
- 🔑 Each run produces a labeled archive:  
  `processed_<startdate>_to_<enddate>.zip`

## Requirements
- Python 3.x
- Bash
- Google Colab or Ubuntu
- Installed packages:
  - `wgrib2`
  - `nco`
  - `cdo`
  - `parallel`
  - `requests`

## Usage

1. Clone the repository:
```bash
git clone https://github.com/Naiver-008/GRIB2-to-NetCDF-Pipeline.git
cd GRIB2-to-NetCDF-Pipeline
```
2. Run the installation script:
```bash
chmod +x Install_Wgrib2.sh
./Install_Wgrib2.sh 
```


3. Run the Python downloader:
```bash
python gfs_downloader.py
```

Find the processed NetCDF files zipped and saved in:
/content/drive/MyDrive/NCAR_GFS_Zips

## Output
NetCDF files labeled by forecast hour (f000, f003, f006)
Variables renamed to standard climate conventions (2t, 2r, 10u, 10v, tp, etc.)
Attributes added for units and long names
Zipped archives labeled with start and end dates

## Keywords
-GFS 003 006
-Colab data processing

## License
This project is licensed under the University of Dar es Salaam (UDSM) License.  
All rights reserved by the authors and UDSM. Redistribution and use are permitted with proper attribution.


## Authors
Innocent Junior

## Contact
innocent.juniour@aol.com

