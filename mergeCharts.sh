#!/bin/bash
set -eu                # Die on errors and unbound variables
IFS=$(printf '\n\t')   # IFS is newline or tab

#The base type of chart we're processing in this script
chartType=wac

#Validate number of command line parameters
if [ "$#" -ne 1 ] ; then
  echo "Usage: $0 <DESTINATION_BASE_DIRECTORY>" >&2
  exit 1
fi

#Get command line parameters
destinationRoot="$1"

#Where to put tiled charts (each in its own directory)
destDir="$destinationRoot/individual_tiled_charts"

#Check that the destination directory exists
if [ ! -d $destDir ]; then
    echo "$destDir doesn't exist"
    exit 1
fi

#VFR Charts sorted by scale, highest to lowest
vfr_chart_list=(
    U.S._VFR_Wall_Planning_Chart
    CC-8_WAC
    CC-9_WAC
    CD-10_WAC
    CD-11_WAC
    CD-12_WAC
    CE-12_WAC
    CE-13_WAC
    CE-15_WAC
    CF-16_WAC
    CF-17_WAC
    CF-18_WAC
    CF-19_WAC
    CG-18_WAC
    CG-19_WAC
    CG-20_WAC
    CG-21_WAC
    CH-22_WAC
    CH-23_WAC
    CH-24_WAC
    CH-25_WAC
    CJ-26_WAC
    CJ-27_WAC
    Albuquerque_SEC
    Anchorage_SEC
    Atlanta_SEC
    Bethel_SEC
    Billings_SEC
    Brownsville_SEC
    Cape_Lisburne_SEC
    Charlotte_SEC
    Cheyenne_SEC
    Chicago_SEC
    Cincinnati_SEC
    Cold_Bay_SEC
    Dallas-Ft_Worth_SEC
    Dawson_SEC
    Denver_SEC
    Detroit_SEC
    Dutch_Harbor_SEC
    El_Paso_SEC
    Fairbanks_SEC
    Great_Falls_SEC
    Green_Bay_SEC
    Halifax_SEC
    Hawaiian_Islands_SEC
    Houston_SEC
    Jacksonville_SEC
    Juneau_SEC
    Kansas_City_SEC
    Ketchikan_SEC
    Klamath_Falls_SEC
    Kodiak_SEC
    Lake_Huron_SEC
    Las_Vegas_SEC
    Los_Angeles_SEC
    Mariana_Islands_Inset_SEC
    McGrath_SEC
    Memphis_SEC
    Miami_SEC
    Montreal_SEC
    New_Orleans_SEC
    New_York_SEC
    Nome_SEC
    Omaha_SEC
    Phoenix_SEC
    Point_Barrow_SEC
    Salt_Lake_City_SEC
    Samoan_Islands_Inset_SEC
    San_Antonio_SEC
    San_Francisco_SEC
    Seattle_SEC
    Seward_SEC
    St_Louis_SEC
    Twin_Cities_SEC
    Washington_SEC
    Western_Aleutian_Islands_East_SEC
    Western_Aleutian_Islands_West_SEC
    Whitehorse_SEC
    Wichita_SEC
    Anchorage_TAC
    Atlanta_TAC
    Baltimore-Washington_TAC
    Boston_TAC
    Charlotte_TAC
    Chicago_TAC
    Cincinnati_TAC
    Cleveland_TAC
    Colorado_Springs_TAC
    Dallas-Ft_Worth_TAC
    Denver_TAC
    Detroit_TAC
    Dutch_Harbor_Inset
    Fairbanks_TAC
    Grand_Canyon_Air_Tour_Operators
    Grand_Canyon_General_Aviation
    Honolulu_Inset_SEC
    Houston_TAC
    Jacksonville_Inset
    Juneau_Inset
    Kansas_City_TAC
    Ketchikan_Inset
    Kodiak_Inset
    Las_Vegas_TAC
    Los_Angeles_TAC
    Memphis_TAC
    Miami_TAC
    Minneapolis-St_Paul_TAC
    New_Orleans_TAC
    New_York_TAC
    Norfolk_Inset
    Orlando_TAC
    Philadelphia_TAC
    Phoenix_TAC
    Pittsburgh_TAC
    Pribilof_Islands_Inset
    Puerto_Rico-VI_TAC
    Salt_Lake_City_TAC
    San_Diego_TAC
    San_Francisco_TAC
    Seattle_TAC
    St_Louis_TAC
    Tampa_TAC
    )

#IFR-LOW Charts sorted by scale, highest to lowest
ifr_low_chart_list=(
    ENR_CL03.tif
    ENR_CL02.tif
    ENR_CL05.tif
    ENR_CL01.tif
    ENR_AKL01.tif
    ENR_AKL02C.tif
    ENR_AKL02E.tif
    ENR_AKL02W.tif
    ENR_AKL03.tif
    ENR_AKL04.tif
    ENR_CL06.tif
    ENR_L21.tif
    Mexico_City_Area.tif
    Miami_Nassau.tif
    Lima_Area.tif
    Guatemala_City_Area.tif
    Dominican_Republic_Puerto_Rico_Area.tif
    ENR_L13.tif
    Bogota_area.tif
    ENR_AKL01_JNU.tif
    ENR_L09.tif
    ENR_L11.tif
    ENR_L12.tif
    ENR_L14.tif
    ENR_L32.tif
    ENR_P02.tif
    Buenos_Aires_Area.tif
    ENR_L10.tif
    ENR_L31.tif
    Santiago_Area.tif
    ENR_AKL04_ANC.tif
    ENR_AKL03_FAI.tif
    ENR_AKL03_OME.tif
    ENR_L05.tif
    ENR_L06N.tif
    ENR_L06S.tif
    ENR_L08.tif
    ENR_L15.tif
    ENR_L16.tif
    ENR_L17.tif
    ENR_L18.tif
    ENR_L19.tif
    ENR_L20.tif
    ENR_L22.tif
    ENR_L23.tif
    ENR_L24.tif
    ENR_L27.tif
    ENR_L28.tif
    Rio_De_Janeiro_Area.tif
    ENR_A02_PHX.tif
    ENR_AKL01_VR.tif
    ENR_L01.tif
    ENR_L02.tif
    ENR_L03.tif
    Panama_Area.tif
    ENR_A01_DCA.tif
    ENR_A02_DEN.tif
    ENR_L04.tif
    ENR_L07.tif
    ENR_L25.tif
    ENR_L26.tif
    ENR_L29.tif
    ENR_L30.tif
    ENR_L33.tif
    ENR_L34.tif
    ENR_L35.tif
    ENR_L36.tif
    ENR_A01_ATL.tif
    ENR_A01_JAX.tif
    ENR_A01_MIA.tif
    ENR_A01_MSP.tif
    ENR_A01_STL.tif
    ENR_A02_DFW.tif
    ENR_A02_ORD.tif
    ENR_A02_SFO.tif
    ENR_A01_DET.tif
    ENR_A02_LAX.tif
    ENR_A02_MKC.tif
    )

#IFR-HIGH Charts sorted by scale, highest to lowest
ifr_high_chart_list=(
    ENR_AKH01.tif
    ENR_AKH02.tif
    ENR_AKH01_SEA.tif
    ENR_H01.tif
    ENR_H02.tif
    ENR_H03.tif
    ENR_H04.tif
    ENR_H05.tif
    ENR_H06.tif
    ENR_H07.tif
    ENR_H08.tif
    ENR_H09.tif
    ENR_H10.tif
    ENR_H11.tif
    ENR_H12.tif
    )

for chart in "${vfr_chart_list[@]}"
  do
  echo $chart

  ./merge_tile_sets.pl \
    /media/sf_Shared_Folder/individual_tiled_charts/$chart.tms/ \
    ./tile_merging_test/VFR
  done

for chart in "${ifr_low_chart_list[@]}"
  do
  echo $chart

  ./merge_tile_sets.pl \
    /media/sf_Shared_Folder/individual_tiled_charts/$chart.tms/ \
    ./tile_merging_test/IFR-LOW
  done

for chart in "${ifr_high_chart_list[@]}"
  do
  echo $chart

  ./merge_tile_sets.pl \
    /media/sf_Shared_Folder/individual_tiled_charts/$chart.tms/ \
    ./tile_merging_test/IFR-HIGH
  done
  