#!/bin/bash
set -eu                # Die on errors and unbound variables
IFS=$(printf '\n\t')   # IFS is newline or tab

#Some other possible software options for tiling pipeline
#https://github.com/makinacorpus/landez.git
#https://github.com/ecometrica/gdal2mbtiles
#https://github.com/mj10777/gdal2mbtiles.git

function USAGE {
    echo "Usage: $0 <SOURCE_BASE_DIRECTORY> <DESTINATION_BASE_DIRECTORY>" >&2
    echo "    -v  Create merged VFR"
    echo "    -h  Create merged IFR-HIGH"
    echo "    -l  Create merged IFR-LOW"
    echo "    -c  Create merged HELICOPTER"
    echo "    -m  Create mbtiles for each chart"
    exit 1
}

verbose='false'
should_create_vfr=''
should_create_ifr_high=''
should_create_ifr_low=''
should_create_heli=''
should_create_mbtiles=''
list=''

while getopts 'vhlcm' flag; do
  case "${flag}" in
    v) should_create_vfr='true' ;;
    h) should_create_ifr_high='true' ;;
    l) should_create_ifr_low='true' ;;
    c) should_create_heli='true' ;;
    m) should_create_mbtiles='true' ;;
    *) error "Unexpected option ${flag}" ;;
  esac
done

#Remove the flag operands
shift $((OPTIND-1))

#Get the number of remaining command line arguments
NUMARGS=$#

#Validate number of command line parameters
if [ $NUMARGS -ne 2 ] ; then
    USAGE
fi

#Get command line parameters
sourceRoot="$1"
destinationRoot="$2"

#Where to put tiled charts (each in its own directory)
srcDir="$sourceRoot/6_tiles"
destDir="$destinationRoot/merged_tiled_charts"

#Check that the source base directory exists
if [ ! -d $srcDir ]; then
    echo "$srcDir doesn't exist"
    exit 1
fi

#Check that the destination base directory exists
if [ ! -d $destDir ]; then
    echo "$destDir doesn't exist"
    exit 1
fi

#VFR Charts sorted by scale, highest to lowest
vfr_chart_list=(
    U.S._VFR_Wall_Planning_Chart
#     CC-8_WAC
#     CC-9_WAC
#     CD-10_WAC
#     CD-11_WAC
#     CD-12_WAC
#     CE-12_WAC
#     CE-13_WAC
#     CE-15_WAC
#     CF-16_WAC
#     CF-17_WAC
#     CF-18_WAC
#     CF-19_WAC
#     CG-18_WAC
#     CG-19_WAC
#     CG-20_WAC
#     CG-21_WAC
#     CH-22_WAC
#     CH-23_WAC
#     CH-24_WAC
#     CH-25_WAC
#     CJ-26_WAC
#     CJ-27_WAC
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
    ENR_CL03
    ENR_CL02
    ENR_CL05
    ENR_CL01
    ENR_AKL01
    ENR_AKL02C
    ENR_AKL02E
    ENR_AKL02W
    ENR_AKL03
    ENR_AKL04
    ENR_CL06
    ENR_L21
    Mexico_City_Area
    Miami_Nassau
    Lima_Area
    Guatemala_City_Area
    Dominican_Republic_Puerto_Rico_Area
    ENR_L13
    Bogota_area
    ENR_AKL01_JNU
    ENR_L09
    ENR_L11
    ENR_L12
    ENR_L14
    ENR_L32
    ENR_P02
    Buenos_Aires_Area
    ENR_L10
    ENR_L31
    Santiago_Area
    ENR_AKL04_ANC
    ENR_AKL03_FAI
    ENR_AKL03_OME
    ENR_L05
    ENR_L06N
    ENR_L06S
    ENR_L08
    ENR_L15
    ENR_L16
    ENR_L17
    ENR_L18
    ENR_L19
    ENR_L20
    ENR_L22
    ENR_L23
    ENR_L24
    ENR_L27
    ENR_L28
    Rio_De_Janeiro_Area
    ENR_A02_PHX
    ENR_AKL01_VR
    ENR_L01
    ENR_L02
    ENR_L03
    Panama_Area
    ENR_A01_DCA
    ENR_A02_DEN
    ENR_L04
    ENR_L07
    ENR_L25
    ENR_L26
    ENR_L29
    ENR_L30
    ENR_L33
    ENR_L34
    ENR_L35
    ENR_L36
    ENR_A01_ATL
    ENR_A01_JAX
    ENR_A01_MIA
    ENR_A01_MSP
    ENR_A01_STL
    ENR_A02_DFW
    ENR_A02_ORD
    ENR_A02_SFO
    ENR_A01_DET
    ENR_A02_LAX
    ENR_A02_MKC
    )

#IFR-HIGH Charts sorted by scale, highest to lowest
ifr_high_chart_list=(
    ENR_AKH01
    ENR_AKH02
    ENR_AKH01_SEA
    ENR_H01
    ENR_H02
    ENR_H03
    ENR_H04
    ENR_H05
    ENR_H06
    ENR_H07
    ENR_H08
    ENR_H09
    ENR_H10
    ENR_H11
    ENR_H12
    )

heli_chart_list=(
    U.S._Gulf_Coast_HEL
    Eastern_Long_Island_HEL
    Baltimore_HEL
    Boston_HEL
    Chicago_HEL
    Dallas-Ft_Worth_HEL
    Detroit_HEL
    Houston_North_HEL
    Houston_South_HEL
    Los_Angeles_East_HEL
    Los_Angeles_West_HEL
    New_York_HEL
    Washington_HEL
    Chicago_O\'Hare_Inset_HEL
    Dallas-Love_Inset_HEL
    Washington_Inset_HEL
    Boston_Downtown_HEL
    Downtown_Manhattan_HEL
    )

#-------------------------------------------------------------------------------
#VFR
if [ -n "$should_create_vfr" ]
    then
        echo "Cleaning $destDir/VFR"
        rm --force --recursive --dir "$destDir/VFR"
        
        for chart in "${vfr_chart_list[@]}"
            do
            echo "VFR: $chart                                                   "

             #Merge the individual charts into an overall chart
            ./merge_tile_sets.pl \
                $srcDir/$chart.tms/ \
                $destDir/VFR
            done

        #Optimize the tiled png files
        ./pngquant_all_files_in_directory.sh $destDir/VFR
        
        if [ -n "$should_create_mbtiles" ]
            then
            
            #Remove the existing mbtiles
            rm --force "$destDir/VFR.mbtiles"
            
            #Package tiles into an .mbtiles file
            ./memoize.py -i $destDir \
                python ./mbutil/mb-util \
                    --scheme=tms \
                    "$destDir/VFR" \
                    "$destDir/VFR.mbtiles"
            fi
    fi

#-------------------------------------------------------------------------------
#IFR LOW
if [ -n "$should_create_ifr_low" ]
    then
        echo "Cleaning $destDir/IFR-LOW"
        rm --force --recursive --dir "$destDir/IFR-LOW"
        
        for chart in "${ifr_low_chart_list[@]}"
            do
            echo "IFR LOW: $chart                                              "

             #Merge the individual charts into an overall chart
            ./merge_tile_sets.pl \
                $srcDir/$chart.tms/ \
                $destDir/IFR-LOW
            done

        #Optimize the tiled png files
        ./pngquant_all_files_in_directory.sh $destDir/IFR-LOW
        
        if [ -n "$should_create_mbtiles" ]
            then
            
            #Remove the existing mbtiles
            rm --force "$destDir/IFR-LOW.mbtiles"
            
            #Package tiles into an .mbtiles file
            ./memoize.py -i $destDir \
                python ./mbutil/mb-util \
                    --scheme=tms \
                    "$destDir/IFR-LOW" \
                    "$destDir/IFR-LOW.mbtiles"
            fi
    fi

#-------------------------------------------------------------------------------
#IFR HIGH
if [ -n "$should_create_ifr_high" ]
    then
        echo "Cleaning $destDir/IFR-HIGH"
        rm --force --recursive --dir "$destDir/IFR-HIGH"
        
        for chart in "${ifr_high_chart_list[@]}"
            do
            echo "IFR HIGH: $chart                                             "

             #Merge the individual charts into an overall chart
            ./merge_tile_sets.pl \
                $srcDir/$chart.tms/ \
                $destDir/IFR-HIGH
            done

        #Optimize the tiled png files
        ./pngquant_all_files_in_directory.sh $destDir/IFR-HIGH

        if [ -n "$should_create_mbtiles" ]
            then
            
            #Remove the existing mbtiles
            rm --force "$destDir/IFR-HIGH.mbtiles"
            
            #Package tiles into an .mbtiles file
            ./memoize.py -i $destDir \
                python ./mbutil/mb-util \
                    --scheme=tms \
                    "$destDir/IFR-HIGH" \
                    "$destDir/IFR-HIGH.mbtiles"
            fi
    fi

#-------------------------------------------------------------------------------
#Heli
if [ -n "$should_create_heli" ]
    then
        echo "Cleaning $destDir/IFR-HELI"
        rm --force --recursive --dir "$destDir/HELI"
        for chart in "${heli_chart_list[@]}"
            do
            echo "HELI: $chart                                                 "

            #Merge the individual charts into an overall chart
            ./merge_tile_sets.pl \
                $srcDir/$chart.tms/ \
                $destDir/HELI
            done

        #Optimize the tiled png files
        ./pngquant_all_files_in_directory.sh $destDir/HELI

        if [ -n "$should_create_mbtiles" ]
            then
            #Remove the existing mbtiles
            rm --force "$destDir/HELI.mbtiles"

            #Package tiles into an .mbtiles file
            ./memoize.py -i $destDir \
                python ./mbutil/mb-util \
                    --scheme=tms \
                    "$destDir/HELI" \
                    "$destDir/HELI.mbtiles"
            fi
    fi

exit 0

