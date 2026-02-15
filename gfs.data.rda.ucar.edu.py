"""
# 🏢 Company: NaiverCompanies
# 👨‍💻 Author: Innocent Junior
# 📅 Date Created: 2026-02-15
# 🔄 Last Updated: 2026-02-15 
# 📧 Email: innocent.juniour@aol.com
# 📍 Location: Dar es Salaam, UDSM, Physics

"""

__author__ = "Innocent Junior"
__copyright__ = "Copyright 2024", "NaiverCompanies"
__credits__ = ["A.Iddi", "J.Jumasia"]
__license__ = "UDSM"
__maintainer__ = "I.Junior"
__status__ = "Developed"

# This script downloads GFS data from NCAR for January 2016, organizes it by year, and processes it with a Bash script.
import os
import time
import requests
from datetime import datetime, timedelta

# Base directory in Colab
SCRIPT_DIR = os.getcwd()   # or "/content"
BASE_DATA_PATH = os.path.join(SCRIPT_DIR, "Data", "NCAR_GFS")

# Ensure base path exists
os.makedirs(BASE_DATA_PATH, exist_ok=True)

# Date range
start_date = datetime(2016, 1, 1)
end_date = datetime(2016, 1, 31)
start_str = start_date.strftime("%Y%m%d")
end_str = end_date.strftime("%Y%m%d")   

# Months selection
months = list(range(1, 13))

# Forecast and base hours
forecast_hours = ['003','006']
base_hours = ['00', '06', '12', '18']

# Track monthly files
monthly_expected_files = []

current_date = start_date
current_year = None
year_folder = None

while current_date <= end_date:

    if current_date.month not in months:
        current_date += timedelta(days=1)
        continue

    # Create year folder if new
    if current_date.year != current_year:
        current_year = current_date.year
        year_folder = os.path.join(BASE_DATA_PATH, "3-hours", str(current_year))
        os.makedirs(year_folder, exist_ok=True)
        print(f"\n📁 Created folder for year: {current_year}")

    date_str = current_date.strftime("%Y%m%d")
    month_id = current_date.strftime("%Y-%m")

    for base_hour in base_hours:
        for fcst_hour in forecast_hours:
            filename = f"gfs.0p25.{date_str}{base_hour}.f{fcst_hour}.grib2"
            file_url = f"https://data.rda.ucar.edu/d084001/{current_year}/{date_str}/{filename}"
            file_path = os.path.join(year_folder, filename)

            monthly_expected_files.append(file_path)

            if os.path.exists(file_path):
                print(f"✔️ Exists: {filename}")
            else:
                try:
                    print(f"📥 Downloading: {filename}")
                    r = requests.get(file_url, stream=True)
                    if r.status_code == 200:
                        with open(file_path, 'wb') as f:
                            for chunk in r.iter_content(chunk_size=8192):
                                f.write(chunk)
                        print(f"✅ Saved: {filename}")
                    else:
                        print(f"⚠️ Failed ({r.status_code}): {filename}")
                except Exception as e:
                    print(f"❌ Error downloading {filename}: {e}")

    current_date += timedelta(days=1)

    # If it's the start of a new month
    if current_date.day == 1:
        print(f"\n📅 Finished month: {month_id} | Checking files...")

        missing = [f for f in monthly_expected_files if not os.path.exists(f)]
        if missing:
            print(f"⚠️ Missing {len(missing)} files for month {month_id}:")
            for m in missing:
                print(f"   - {os.path.basename(m)}")
            # Run bash script directly in Colab
            print("🚀 Launching processing script...")
            # Pass to bash script
            os.system(f"bash wgrib2testfile_v6.sh {start_str} {end_str}")
            #os.system("bash wgrib2testfile_v6.sh")
            print("✅ Finished processing with Bash script.\n")

        else:
            print("✅ All files for the month are present!")

            # Run bash script directly in Colab
            print("🚀 Launching processing script...")


            # Pass to bash script
            os.system(f"bash wgrib2testfile_v6.sh {start_str} {end_str}")
            #os.system("bash wgrib2testfile_v6.sh")
            print("✅ Finished processing with Bash script.\n")

        monthly_expected_files = []

print("\n✅ All downloads attempted.")
print(f"📂 Files organized by year in: {os.path.join(BASE_DATA_PATH, '3-hours')}")



# Download the zip file created by Bash
from google.colab import files
files.download(f"/content/processed_{start_str}_to_{end_str}.zip")

