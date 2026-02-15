apt-get update && apt-get install -y dos2unix

dos2unix Install_Wgrib2.sh wgrib2testfile_v6.sh 

chmod +x Install_Wgrib2.sh wgrib2testfile_v6.sh

#proceed with 
./Install_Wgrib2.sh

#Sometimes at the end of installation you need to repeat 
echo 'export PATH="/content/grib2/wgrib2:$PATH"' >> ~/.bashrc
source ~/.bashrc