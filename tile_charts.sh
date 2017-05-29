#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace
IFS=$(printf '\n\t')   # IFS is newline or tab
# BUG TODO: Fix zoom levels for insets and grand grand_canyon

main() {
    # Types of charts
    local -r chart_types_array=( caribbean enroute gom grand_canyon heli insets planning sectional tac )
        
    # An associative array of the individual chart arrays for different scales and 
    # each one's associated zoom levels
    declare -A chart_zoom_levels_array=( 
        [sectional_chart_array_500000]="0,1,2,3,4,5,6,7,8,9,10,11"
        [sectional_chart_array_250000]="0,1,2,3,4,5,6,7,8,9,10,11,12" 
        [tac_chart_array]="7,8,9,10,11,12"
        [insets_chart_array]="8,9,10,11,12"
        [heli_chart_array_1000000]="0,1,2,3,4,5,6,7,8,9,10"
        [heli_chart_array_250000]="0,1,2,3,4,5,6,7,8,9,10,11,12"
        [heli_chart_array_125000]="0,1,2,3,4,5,6,7,8,9,10,11,12,13"
        [heli_chart_array_90000]="0,1,2,3,4,5,6,7,8,9,10,11,12,13"
        [heli_chart_array_62500]="0,1,2,3,4,5,6,7,8,9,10,11,12,13,14"
        [heli_chart_array_50000]="0,1,2,3,4,5,6,7,8,9,10,11,12,13,14"
        [grand_canyon_chart_array]="8"
        [enroute_chart_array_2000000]="0,1,2,3,4,5,6,7,8,9"
        [enroute_chart_array_1000000]="0,1,2,3,4,5,6,7,8,9,10"
        [enroute_chart_array_500000]="0,1,2,3,4,5,6,7,8,9,10,11"
        [enroute_chart_array_250000]="0,1,2,3,4,5,6,7,8,9,10,11,12"
        [caribbean_chart_array]="0,1,2,3,4,5,6,7,8,9,10"
        [planning_chart_array]="0,1,2,3,4,5,6,7"
        )
        
    # Charts that are at 1:500,000 scale
    local -r sectional_chart_array_500000=(
        Albuquerque_SEC Anchorage_SEC Atlanta_SEC Bethel_SEC Billings_SEC
        Brownsville_SEC Cape_Lisburne_SEC Charlotte_SEC Cheyenne_SEC Chicago_SEC
        Cincinnati_SEC Cold_Bay_SEC Dallas_Ft_Worth_SEC Dawson_SEC Denver_SEC
        Detroit_SEC Dutch_Harbor_SEC El_Paso_SEC Fairbanks_SEC Great_Falls_SEC
        Green_Bay_SEC Halifax_SEC Hawaiian_Islands_SEC Houston_SEC
        Jacksonville_SEC Juneau_SEC Kansas_City_SEC Ketchikan_SEC Klamath_Falls_SEC
        Kodiak_SEC Lake_Huron_SEC Las_Vegas_SEC Los_Angeles_SEC 
        McGrath_SEC Memphis_SEC Miami_SEC Montreal_SEC New_Orleans_SEC New_York_SEC
        Nome_SEC Omaha_SEC Phoenix_SEC Point_Barrow_SEC Salt_Lake_City_SEC
        San_Antonio_SEC San_Francisco_SEC Seattle_SEC
        Seward_SEC St_Louis_SEC Twin_Cities_SEC Washington_SEC
        Western_Aleutian_Islands_East_SEC Western_Aleutian_Islands_West_SEC
        Whitehorse_SEC Wichita_SEC
        )

    # Charts that are at 1:250,000 scale
    local -r sectional_chart_array_250000=(
        Honolulu_Inset_SEC
        Mariana_Islands_Inset_SEC
        Samoan_Islands_Inset_SEC
        )

    local -r tac_chart_array=(
        Anchorage_TAC Atlanta_TAC Baltimore_Washington_TAC Boston_TAC Charlotte_TAC
        Chicago_TAC Cincinnati_TAC Cleveland_TAC Colorado_Springs_TAC Dallas_Ft_Worth_TAC
        Denver_TAC Detroit_TAC Fairbanks_TAC Houston_TAC Kansas_City_TAC Las_Vegas_TAC
        Los_Angeles_TAC Memphis_TAC Miami_TAC Minneapolis_St_Paul_TAC New_Orleans_TAC
        New_York_TAC Orlando_TAC Philadelphia_TAC Phoenix_TAC Pittsburgh_TAC
        Puerto_Rico_VI_TAC Salt_Lake_City_TAC San_Diego_TAC San_Francisco_TAC Seattle_TAC
        St_Louis_TAC Tampa_TAC
        )

    local -r insets_chart_array=(
        Dutch_Harbor_Inset
        Jacksonville_Inset
        Juneau_Inset
        Ketchikan_Inset
        Kodiak_Inset
        Norfolk_Inset
        Pribilof_Islands_Inset
        )
        
    local -r heli_chart_array_1000000=(
        U_S_Gulf_Coast_HEL
        )

    local -r heli_chart_array_250000=(
        Eastern_Long_Island_HEL
        )
            
    local -r heli_chart_array_125000=(
        Baltimore_HEL
        Boston_HEL
        Chicago_HEL
        Dallas_Ft_Worth_HEL
        Detroit_HEL
        Houston_North_HEL
        Houston_South_HEL
        Los_Angeles_East_HEL
        Los_Angeles_West_HEL
        New_York_HEL
        Washington_HEL
        )

    local -r heli_chart_array_90000=(
        Chicago_O_Hare_Inset_HEL
        Dallas_Love_Inset_HEL
        )

    local -r heli_chart_array_62500=(
        Washington_Inset_HEL
        )

    local -r heli_chart_array_50000=(
        Boston_Downtown_HEL
        Downtown_Manhattan_HEL
        )
        
    local -r grand_canyon_chart_array=(
        Grand_Canyon_General_Aviation
        Grand_Canyon_Air_Tour_Operators
        )
        
    local -r enroute_chart_array_2000000=(
        ENR_CL01
        ENR_CL02
        ENR_CL03    
        ENR_CL05
        ENR_AKH01 ENR_AKH02
        )

    local -r enroute_chart_array_1000000=(
        ENR_AKL01
        ENR_AKL02C
        ENR_AKL02E
        ENR_AKL02W
        ENR_AKL03
        ENR_AKL04
        ENR_AKL01_JNU
        ENR_L09
        ENR_L11
        ENR_L12
        ENR_L13
        ENR_L14
        ENR_L21
        ENR_L32
        ENR_CL06
        Mexico_City_Area
        Miami_Nassau
        Lima_Area
        Guatemala_City_Area
        Dominican_Republic_Puerto_Rico_Area
        Bogota_area
        ENR_P02
        ENR_AKH01_SEA ENR_H01 ENR_H02 ENR_H03 ENR_H04 ENR_H05 
        ENR_H06 ENR_H07 ENR_H08 ENR_H09 ENR_H10 ENR_H11 ENR_H12 
        )
        
    local -r enroute_chart_array_500000=(
        Buenos_Aires_Area
        Santiago_Area
        Rio_De_Janeiro_Area
        Panama_Area
        ENR_AKL01_VR
        ENR_AKL04_ANC
        ENR_AKL03_FAI
        ENR_AKL03_OME
        ENR_L01
        ENR_L02
        ENR_L03
        ENR_L04
        ENR_L05
        ENR_L06N
        ENR_L06S
        ENR_L07
        ENR_L08
        ENR_L10
        ENR_L15
        ENR_L16
        ENR_L17
        ENR_L18
        ENR_L19
        ENR_L20
        ENR_L22
        ENR_L23
        ENR_L24
        ENR_L25
        ENR_L26
        ENR_L27
        ENR_L28
        ENR_L29
        ENR_L30
        ENR_L31
        ENR_L33
        ENR_L34
        ENR_L35
        ENR_L36
        ENR_A01_DCA
        ENR_A02_DEN
        ENR_A02_PHX
        )

    local -r enroute_chart_array_250000=(
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
        
    local -r caribbean_chart_array=(
        Caribbean_1_VFR_Chart
        Caribbean_2_VFR_Chart
        )
    
    local -r planning_chart_array=(
        Alaska_Wall_Planning_Chart
        US_IFR_PLAN_EAST
        US_IFR_PLAN_WEST
        U_S_VFR_Wall_Planning_Chart
        )

    # Get command line parameters
    local -r destinationRoot="$1"
    local -r chart_type="$2"

    # Check that the destination directory exists
    if [ ! -d "$destinationRoot" ]; then
        echo "Destination directory $destinationRoot doesn't exist"
        exit 1
    fi
    
    # For all the keys in the chart_zoom_levels_array
    for chart_array in "${!chart_zoom_levels_array[@]}"; do
        
        # Get the zoom levels for this array of charts
        zoom_levels="${chart_zoom_levels_array[$chart_array]}"
        

        # Compare the name of requested chart type to array name
        if [[ "$chart_array" == "$chart_type"*  ]]; then
            
#             echo "------------------"
#             echo "Chart array: $chart_array"
#             echo "Zoom levels: $zoom_levels"
            
            # List of all elements
            charts="${chart_array}[@]"

            # For all of the charts in the array 
            for chart in "${!charts}"; do
#                 echo "chart: $chart"
                tile_chart "$chart" "$chart_type" "$destinationRoot" "$zoom_levels"
                done
        fi
    done
}

tile_chart() {

    echo "--------Tiling ${chart}------------"
    
    # Validate number of parameters
    if [ "$#" -ne 4 ] ; then
        echo "Usage: tile_chart <chart> <chart_type> <destination_root> <zoom_levels>" >&2
        exit 1
    fi

    local -r chart="$1"
    local -r chartType="$2"
    local -r destinationRoot="$3"
    local -r zoom_levels="$4"
 
    # Where to put tiled charts (each in its own directory)
    local -r tiled_charts_directory="$destinationRoot/6_tiles"
    
    # Where to put tiles we create
    local -r output_tiles_directory="$tiled_charts_directory/${chart}.tms"
    
    # The mbtiles file for this chart
    local -r mbtiles_file="$destinationRoot/7_mbtiles/${chart}.mbtiles"
    
    # The warped version of this chart
    local -r warped_chart="$destinationRoot/5_warpedRasters/$chartType/$chart.tif"
    
    echo "Zoom levels are ${zoom_levels}"

    # Check that the destination directory exists
    if [ ! -d "$tiled_charts_directory" ]; then
        echo "Tiled charts directory $tiled_charts_directory doesn't exist"
        exit 1
    fi
    
    # Check that the source raster exists
    if [ ! -f "$warped_chart" ]; then
        echo "Warped chart $warped_chart doesn't exist" >&2
        exit 1
    fi
    
    # Create tiles from the source raster
    ./memoize.py -i "$tiled_charts_directory"  -d "$destinationRoot" \
        ./tilers_tools/gdal_tiler.py            \
            --profile=tms                       \
            --release                           \
            --paletted                          \
            --zoom="${zoom_levels}"             \
            --dest-dir="$tiled_charts_directory"               \
            "$warped_chart"
        
    # Did the user want to optimize the individual tiles?
    if [ -n "$optimize_tiles_flag" ]
        then
            echo "Optimizing tiles for $chart"
            # Optimize the tiled png files
            ./pngquant_all_files_in_directory.sh "$output_tiles_directory"
        fi

    # Did the user want to package the individual tiles into an mbtiles file
    if [ -n "$create_mbtiles_flag" ]
        then
            echo "Creating mbtiles for $chart"
            
            # Delete any existing mbtiles file
            rm -f "$mbtiles_file"
            
            # Package tiles into an .mbtiles file
            ./memoize.py -i "$tiled_charts_directory"  -d "$destinationRoot"    \
                python ./mbutil/mb-util \
                    --scheme=tms        \
                    "$output_tiles_directory"   \
                    "$mbtiles_file"
            printf "\n"
            
        fi
        
    # Copy leaflet and the simple viewer to our tiled directory
    cp -r ./leaflet/* "$output_tiles_directory"
    }
    
    
# The script starts here
verbose='false'
optimize_tiles_flag=''
create_mbtiles_flag=''

# Variables to indicate which charts to process
should_process_caribbean=''
should_process_enroute=''
should_process_grand_canyon=''
should_process_helicopter=''
should_process_planning=''
should_process_sectional=''
should_process_tac=''

# Process command line options
while getopts 'omvceghpst' flag; do
  case "${flag}" in
    o) optimize_tiles_flag='true'           ;;
    m) create_mbtiles_flag='true'           ;;
    v) verbose='true'                       ;;
    c) should_process_caribbean='true'      ;;
    e) should_process_enroute='true'        ;;
    g) should_process_grand_canyon='true'   ;;
    h) should_process_helicopter='true'     ;;
    p) should_process_planning='true'       ;;
    s) should_process_sectional='true'      ;;
    t) should_process_tac='true'            ;;
    *) error "Unexpected option ${flag}"    ;;
  esac
done

# Remove the flag operands
shift $((OPTIND-1))

# Validate number of command line parameters
if [ "$#" -ne 2 ] ; then
  echo "Usage: $0 <DESTINATION_BASE_DIRECTORY> <chart_type>" >&2
  echo "    -o  Optimize tiles"
  echo "    -m  Create mbtiles file"
  exit 1
fi

# Call the main routine
main "$@"
exit 0











