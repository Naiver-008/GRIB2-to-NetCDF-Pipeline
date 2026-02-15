#!/bin/bash

# 📄 Personal Information
# 👨‍💻 Author: Innocent Junior
# 📅 Date Created: 2025-05-05
# 🔄 Last Updated: 2026-02-15
# 📧 Email: innocent.juniour@aol.com



shopt -s nullglob

# User-friendly configuration
#start_date="2017-02-01"
#end_date="2017-02-30"

# Read arguments from Python
start_date="$1"
end_date="$2"

echo "📅 Processing from $start_date to $end_date"

# Base directories for the processing
base_dir="./Data/NCAR_GFS/3-hours"
output_dir="${base_dir}/1.Processed"
mkdir -p "$output_dir"

# 📌 Set bounding box (West:East South:North) Longitude(E:W) Latitude(S:N)
bbox="28:43 -12:0"
temp_dir="${base_dir}/temp"
mkdir -p "$temp_dir"

# Function to process a specific GRIB file for a given date, cycle, and forecast hour
process_grib() {
    local date="$1"
    local cycle="$2"
    local fh="$3"

    yyyymmdd=$(date -d "$date" +%Y%m%d)
    year=$(date -d "$date" +%Y)
    year_dir="${base_dir}/${year}"

    grib_file="${year_dir}/gfs.0p25.${yyyymmdd}${cycle}.f${fh}.grib2"
    if [[ ! -f "$grib_file" ]]; then
        echo "❌ Missing: $grib_file"
        return
    fi

    clipped="${temp_dir}/clipped_${yyyymmdd}_${cycle}f${fh}.grib2"
    wgrib2 "$grib_file" -small_grib ${bbox//,/ } "$clipped" >/dev/null 2>&1 || {
        echo "❌ ERROR cropping $grib_file" >> gfs_processing.log
        return
    }

    prefix="${clipped%.grib2}"
    if [[ "$fh" == "000" ]]; then
        matches=":PRES:surface:|:UGRD:10 m above ground:|:VGRD:10 m above ground:|:TMP:2 m above ground:|:SPFH:2 m above ground:|:RH:2 m above ground:"
    else
        last_digit="${fh: -1}"  # Extract last character of $fh
        matches=":PRES:surface:|:UGRD:10 m above ground:|:VGRD:10 m above ground:|:TMP:2 m above ground:|:SPFH:2 m above ground:|:RH:2 m above ground:|:APCP:surface:|:PRATE:surface:${last_digit} hour fcst:"
    fi

    selected="${prefix}_selected.grib2"
    wgrib2 "$clipped" -match "$matches" -grib_out "$selected" >/dev/null 2>> gfs_processing.log

    if [[ ! -s "$selected" ]]; then
        echo "⚠️ WARNING: Empty output for $grib_file" >> gfs_processing.log
        return
    fi

    # ✅ Store by forecast hour into temp dir
    merge_dir="${temp_dir}/by_fhour/${fh}"
    mkdir -p "$merge_dir"

    copied_grib="${merge_dir}/${yyyymmdd}_${cycle}f${fh}.grib2"
    cp "$selected" "$copied_grib"

    # ✅ Clean up temp clipped and selected
    rm -f "$clipped" "$selected"
    echo "✅ Collected: $copied_grib"
}

export -f process_grib
export base_dir output_dir bbox temp_dir

current_date="$start_date"
while [[ "$current_date" != "$(date -I -d "$end_date + 1 day")" ]]; do
    yyyymmdd=$(date -d "$current_date" +%Y%m%d)
    year=$(date -d "$current_date" +%Y)
    year_dir="${base_dir}/${year}"

    # Check if all expected output files already exist
    final_f000="${output_dir}/${yyyymmdd}.f000.nc"
    final_f003="${output_dir}/${yyyymmdd}.f003.nc"
    final_f006="${output_dir}/${yyyymmdd}.f006.nc"

    if [[ -f "$final_f000" && -f "$final_f003" && -f "$final_f006" ]]; then
        echo "⏭️ Skipping $yyyymmdd — already processed."
        current_date=$(date -I -d "$current_date + 1 day")
        continue
    fi

    echo "🚀 Processing date: $current_date"

    # Process each forecast hour independently
    for fh in 003 006; do
        # Check if all cycles exist for this forecast hour
        all_cycles_present=true
        for cycle in 00 06 12 18; do
            expected_file="${year_dir}/gfs.0p25.${yyyymmdd}${cycle}.f${fh}.grib2"
            if [[ ! -f "$expected_file" ]]; then
                all_cycles_present=false
                echo "⚠️ Missing cycle $cycle for f${fh} on ${yyyymmdd}"
                break
            fi
        done

        if ! $all_cycles_present; then
            echo "❌ Skipping f${fh} on ${yyyymmdd} - incomplete cycles"
            continue
        fi

        echo "✔️ All cycles present for f${fh} on ${yyyymmdd} - processing..."

        # Process all cycles for this forecast hour
        jobs=()
        for cycle in 00 06 12 18; do
            jobs+=("$current_date $cycle $fh")
        done

        printf "%s\n" "${jobs[@]}" | parallel -j 20 --colsep ' ' process_grib {1} {2} {3}

        # Merge and convert GRIB files for this forecast hour
        fh_dir="${temp_dir}/by_fhour/${fh}"
        
        if [[ ! -d "$fh_dir" ]]; then
            echo "⚠️ No directory found for forecast hour $fh - skipping"
            continue
        fi

        grib_files=("$fh_dir"/${yyyymmdd}_??f${fh}.grib2)

        if [ ${#grib_files[@]} -ne 4 ]; then
            echo "⚠️ Expected 4 GRIB files for ${yyyymmdd} f${fh}, found ${#grib_files[@]} - skipping"
            continue
        fi

        merged_grib="${output_dir}/${yyyymmdd}.f${fh}.grib2"
        merged_nc="${output_dir}/${yyyymmdd}.f${fh}.nc"

        cat "${grib_files[@]}" > "$merged_grib"

        wgrib2 "$merged_grib" -netcdf "$merged_nc" >/dev/null 2>&1 || {
            echo "❌ ERROR converting $merged_grib to NetCDF" >> gfs_processing.log
            continue
        }

        netcdf_file="$merged_nc"

        # ✅ Rename variables using ncrename
        var_map=(
        "PRES_surface=sp"
        "RH_2maboveground=2r"
        "TMP_2maboveground=2t"
        "SPFH_2maboveground=2sh"
        "UGRD_10maboveground=10u"
        "VGRD_10maboveground=10v"
        "PRATE_surface=prate"
        "APCP_surface=tp"
        )

        for pair in "${var_map[@]}"; do
            old_var="${pair%%=*}"
            new_var="${pair##*=}"
            if ncks -m "$netcdf_file" | grep -q "$old_var"; then
                ncrename -v "$old_var","$new_var" "$netcdf_file"
                echo "🔁 Renamed $old_var → $new_var in $netcdf_file" >> gfs_processing.log
            else
                echo "⚠️ Skipped: $old_var not found in $netcdf_file" >> gfs_processing.log
            fi
        done

        # ✅ Add attributes using ncatted
        declare -A var_attrs=(
        [sp]="units=Pa,long_name=Surface pressure"
        [2sh]="units=kg/kg,long_name=2-meter specific humidity"
        [2t]="units=K,long_name=2-meter air temperature"
        [2r]="units=%,long_name=2-meter relative humidity"
        [10u]="units=m/s,long_name=10-meter u-wind component"
        [10v]="units=m/s,long_name=10-meter v-wind component"
        [prate]="units=kg/m^2/s,long_name=Surface precipitation rate"
        [tp]="units=kg/m^2,long_name=Total precipitation"
        )

        for var in "${!var_attrs[@]}"; do
            if ncks -m "$netcdf_file" | grep -qw "$var"; then
                IFS=',' read -r units_attr long_name_attr <<< "${var_attrs[$var]}"
                ncatted -a ${units_attr/,/ -a } "$var",o,c \
                        -a ${long_name_attr/,/ -a } "$var",o,c \
                        "$netcdf_file" >/dev/null 2>&1 || {
                    echo "❌ ERROR adding attributes to $var in $netcdf_file" >> gfs_processing.log
                }
            else
                echo "⚠️ Skipped attribute setting: $var not found in $netcdf_file" >> gfs_processing.log
            fi
        done

        echo "✅ Successfully processed f${fh} for ${yyyymmdd}: $merged_nc"

        # Clean up temporary files
        rm -f "${grib_files[@]}" "$merged_grib"

        # Only delete original GRIB2s if NetCDF conversion was successful
        if [[ -f "$merged_nc" ]]; then
            echo "🗑️ Deleting original GRIB2 files for ${yyyymmdd} f${fh}..."
            find "$year_dir" -name "gfs.0p25.${yyyymmdd}*.f${fh}.grib2" -delete
        fi
    done

    current_date=$(date -I -d "$current_date + 1 day")
done

echo "🎉 All processing complete!"
echo "📦 Final NetCDFs saved in: $output_dir"

# 🎉 All processing complete!
echo "📦 Final NetCDFs saved in: $output_dir"

# 👉 Create a zip file labeled with start and end dates
zip_file="/content/processed_${start_date}_to_${end_date}.zip"
cd "$output_dir/.."
zip -r "$zip_file" "$(basename "$output_dir")"

echo "✅ Processed folder compressed into: $zip_file"

# 🗑️ Clean up original processed folder to free space
rm -rf "$output_dir"
echo "🧹 Deleted original processed folder to save space."

# 👉 Copy zip to Google Drive for persistence
drive_dir="/content/drive/MyDrive/NCAR_GFS_Zips"
mkdir -p "$drive_dir"
mv "$zip_file" "$drive_dir/"

echo "✅ Final archive stored in Google Drive: $drive_dir/processed_${start_date}_to_${end_date}.zip"


