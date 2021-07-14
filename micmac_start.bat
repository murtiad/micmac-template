:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: MICMAC TEMPLATE ::
:: by Arnadi Murtiyoso (c) 2020
:: Photogrammetry and Geomatics Group
:: ICube-TRIO UMR 7357 INSA Strasbourg (France)
:: Contact: arnadi.murtiyoso@insa-strasbourg.fr
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Pro tip: Visit MicMac Wiki (https://micmac.ensg.eu/) 
:: and forum (http://forum-micmac.forumprod.com/) 
:: or Reddit (https://www.reddit.com/r/MicMac/)
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: DISCLAIMER: I AM NOT A MICMAC DEVELOPPER !!! Only a user, like you guys :) 
:: Please go to the above mentioned links for more technical questions
:: Especially CHECK THE WIKI to see what parameters can be modified !!!
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: How to use this template:
:: (1) Edit the file paths accordingly. This template assumes that the file 
::     structure is as follows:
::
::			MyWorkFolder
::	            micmac_win
::              myProject
::                   images in .JPG format (in uppercases, so not .jpg! )
::                   GCP coordinates (.txt file)
::                   etc.
::
:: (2) Use "::" in front of lines to deactivate specific functions
:: (3) Run this file in a command prompt
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: first of all, set the path for MicMac functions and input images ::
set BIN=../micmac_win/bin
set IMG="./*.*JPG"

:: OPTIONAL: Convert embedded/geotagged GPS (and IMU if exists) into approximate EO values ::
 "%BIN%/mm3d" OriConvert OriTxtInFile EmbeddedGPS.csv GeoTagged NameCple=FileImagesNeighbour.xml

:: TIE POINTS GENERATION ::
:: IF embedded GPS is available
 "%BIN%/mm3d" Tapioca File FileImagesNeighbour.xml 800
:: IF no embedded GPS is available
:: "%BIN%/mm3d" Tapioca MulScale ./*.*JPG 200 800

:: RELATIVE ORIENTATION ::
 "%BIN%/mm3d" Tapas RadialExtended %IMG% Out=Adjusted

:: OPTIONAL: INITIAL ABSOLUTE ORIENTATION ::
:: this step greatly helps the GCP input in the next step!
:: using geotags
 "%BIN%/mm3d" CenterBascule %IMG% Adjusted GeoTagged AbsoluteGPS
 "%BIN%/mm3d" AperiCloud %IMG% AbsoluteGPS Out=AperiCloudAbsoluteGPS.ply
:: using four GCPs, choose from list of available GCPs and create a text file for these four
:: try selecting well distributed four GCPs for optimal GCP input prediction in the next step 
:: "%BIN%/mm3d" GCPConvert "#F=N_X_Y_Z" initialfourGCP.txt
:: "%BIN%/mm3d" SaisieAppuisInitQT %IMG% Adjusted initialfourGCP.xml initalfourGCPMeasures.xml
:: "%BIN%/mm3d" GCPBascule %IMG% Adjusted AbsoluteGPS initialfourGCP.xml initalfourGCPMeasures.xml 

:: INPUT THE GCPs ::
:: convert GCP file from text file to MicMac format
 "%BIN%/mm3d" GCPConvert "#F=N_X_Y_Z" GCP.txt
:: input GCPs
 "%BIN%/mm3d" SaisieAppuisPredicQT %IMG% AbsoluteGPS GCP.xml GCPMeasures.xml
:: OPTIONAL: input check points (CPs)
:: "%BIN%/mm3d" SaisieAppuisPredicQT %IMG% AbsoluteGPS CP.xml CPMeasures.xml

:: BUNDLE ADJUSTMENT ("OPTIMISATION")::
 "%BIN%/mm3d" GCPBascule %IMG% AbsoluteGPS Ground GCP.xml GCPMeasures-S2D.xml
 "%BIN%/mm3d" Campari %IMG% Ground AbsoluteAdjusted GCP=[GCPMeasures-S3D.xml,0.005,GCPMeasures-S2D.xml,0.5] EmGPS=[GeoTagged,0.03,0.15]

:: OPTIONAL: Check GCP (and/or CP) error ::
 "%BIN%/mm3d" GCPCtrl %IMG% AbsoluteAdjusted GCP.xml GCPMeasures-S2D.xml
:: "%BIN%/mm3d" GCPCtrl %IMG% AbsoluteAdjusted CP.xml CPMeasures-S2D.xml

:: DENSE MATCHING ::
 "%BIN%/mm3d" Pims MicMac %IMG% AbsoluteAdjusted

:: EXPORT POINT CLOUD ::
 "%BIN%/mm3d" Pims2Ply MicMac Out=MicMacPointCloud.ply

:: EXPORT DEM ::
 "%BIN%/mm3d" Pims2MNT MicMac DoOrtho=1
 "%BIN%/mm3d" to8Bits PIMs-TmpBasc/PIMs-Merged_Prof.tif Out=DEM.tif

:: EXPORT ORTHO ::
 "%BIN%/mm3d" Tawny "PIMs-ORTHO" Out=Orthophotomosaic.tif
