#!/usr/bin/perl

# Cut out and georeference Caribbean insets from FAA aeronautical maps
# Based on the PDFs being rasterized at 300dpi
# Copyright (C) 2013  Jesse McGraw (jlmcgraw@gmail.com)
#
#--------------------------------------------------------------------------------------------------------------------------------------------
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see [http://www.gnu.org/licenses/].

#Standard modules
use strict;
use warnings;
use autodie;
use Carp;

#Using this so users don't need to globally install modules
#allows using "carton install" instead
use FindBin '$Bin';
use lib "$FindBin::Bin/local/lib/perl5";

#Non-Standard modules that should be installed locally
use Modern::Perl '2014';
use Params::Validate qw(:all);

#Call the main routine and exit with its return code
exit main(@ARGV);

sub main {
    our $debug = 0;
    my $chartType = 'enroute';

    #I'm using locally compiled gdal
    #If your version is > 2 then set this to empty string ''
    our $compiled_gdal_dir = '';

    #     our $compiled_gdal_dir = '~/Documents/github/gdal/gdal/apps/';

    #Number of arguments supplied on command line
    my $num_args = $#ARGV + 1;

    if ( $num_args != 1 ) {
        say "Usage: $0 destination_root_dir";
        exit;
    }

    #Get the base directory from command line
    my $destinationRoot = $ARGV[0];

    #For files that have a version in their name, this is where the links to the lastest version
    #will be stored
    my $linkedRastersDirectory = "$destinationRoot/sourceRasters/$chartType/";

    #Where clipped rasters are stored
    my $clippedRastersDirectory = "$destinationRoot/clippedRasters/$chartType/";

    #Where warped rasters are stored
    my $warpedRastersDirectory = "$destinationRoot/warpedRasters/$chartType/";

    #check that the directories exist
    unless ( -d $linkedRastersDirectory ) {
        die
          "Directory for source rasters doesn't exist: $linkedRastersDirectory";
    }

    unless ( -d $clippedRastersDirectory ) {
        die
          "Directory for clipped rasters doesn't exist: $clippedRastersDirectory";
    }
    unless ( -d $warpedRastersDirectory ) {
        die
          "Directory for warped_raster_directory rasters doesn't exist: $warpedRastersDirectory";
    }

    say
      "$linkedRastersDirectory $clippedRastersDirectory $warpedRastersDirectory";

    #The inset's name
    #Their source raster, upper left X, upper left Y, lower right X, lower right Y pixel coordinates of the inset
    #The Ground Control Points for each inset
    #  Relative to the original, unclipped file: Pixel X, Pixel Y, Longitude, Latitude
    my %charts = (

        #Very slightly off in upper right
        "Buenos_Aires_Area" => [
            "ENR_CA01",
            "2102", "490", "4796", "3103",
            [
                "  2362     658     59-30W 34-00S",
                "  4076     672     58-00W 34-00S",
                "  4065     1359    58-00W 34-30S",
                "  4050     2740    58-00W 35-30S",
                "  2916     2730    59-00W 35-30S",
            ]
        ],

        #Pretty accurate
        "Santiago_Area" => [
            "ENR_CA01",
            "5103", "490", "7795", "3110",
            [
                "  5112     1394    72-00W 33-00S",
                "  6374     628     71-00W 32-30S",
                "  7646     618     70-00W 32-30S",
                "  7664     2884    70-00W 34-00S",
                "  6396     2896    71-00W 34-00S",
                "  6396     2896    71-00W 34-00S",
                "  5130     2908    72-00W 34-00S",
            ]
        ],

        #Pretty accurate
        "Lima_Area" => [
            "ENR_CA01",
            "8102", "490", "10796", "3111",
            [
                "  8512     694     78-00W 11-00S",
                "  9491     685     77-00W 11-00S",
                "  10469    679     76-00W 11-00S",
                "  10474   1670     76-00W 12-00S",
                "  10478   2662     76-00W 13-00S",
                "  9505    2668     77-00W 13-00S",
                "  8531    2676     78-00W 13-00S",
                "  8521    1684     78-00W 12-00S",

            ]
        ],
        "Rio_De_Janeiro_Area" => [
            "ENR_CA01",
            "11102",
            "490",
            "13797",
            "3107",
            [
                "  11429     2161 44-00W 23-00S",
                "  13020     1302 43-00W 22-30S",
                "  13020     2160 43-00W 23-00S",
            ]
        ],
        "Antigua_Island_Ascension_Island_Inset" => [
            "ENR_CA01",
            "8102",
            "3481",
            "13795",
            "6102",
            [
                "  8459     3604 70-00W 20-00N",
                "  10466     3893 45-00W 15-00N",
                "  13648     3529 05-00W 20-00N",
                "  13571     4729 05-00W 05-00N",
                "  13498     5858 05-00W 10-00S",
                "  10900     5801 40-00W 10-00S",
                "  8306     5965 75-00W 10-00S",
                "  8187     4840 75-00W 05-00N",
            ]
        ],

        #Pretty accurate
        "Guatemala_City_Area" => [
            "ENR_CA01",
            "4388", "3480", "7796", "6102",
            [
                "  4834 4178    91-00W 15-00N",
                "  4836 5252    91-00W 14-00N",
                "  6932 4178    89-00W 15-00N",
                "  6930 5254    89-00W 14-00N",
            ]
        ],

        #Ok, could use fine tuning
        "Miami_Nassau" => [
            "ENR_CA02",
            "2102", "521", "6279", "3142",
            [
                "  2618     562 80-00W 27-00N",
                "  5549     586 77-00W 27-00N",
                "  5525     2742 77-00W 25-00N",
                "  2610     2720 80-00W 25-00N",
            ]
        ],

        #ok
        "Bogota_area" => [
            "ENR_CA02",
            "6603", "520", "9297", "3141",
            [
                "  7047     1622 75-00W 05-00N",
                "  8415     1624 74-00W 05-00N",
                "  8411     2985 74-00W 04-00N",
                "  7047     2984 75-00W 04-00N",
            ]
        ],

        #Still a bit off, esp. towards East
        "Central_America_Pacific_Ocean_Inset" => [
            "ENR_CA02",
            "9555", "521", "13744", "6103",
            [
                "  9603     1166 90-00W 10-00N",
                "  13154    1110 80-00W 10-00N",
                "  13172    5985 80-00W 04-00S",
                "  9740     6039 90-00W 04-00S",
            ]
        ],

        #Ok
        "Panama_Area" => [
            "ENR_CA02",
            "5108", "3461", "9284", "6102",
            [
                "  6338     4607 80-00W 09-00N",
                "  8435     4608 79-00W 09-00N",
                "  6337     5207 80-00W 08-43N",
            ]
        ],

        #Ok, could use fine tuning
        "Mexico_City_Area" => [
            "ENR_CA02",
            "2102", "3480", "4796", "6102",
            [
                "  2617     3700 100-00W 21-00N",
                "  4122     3700 98-00W 21-00N",
                "  4118     6073 98-00W 18-00N",
                "  2623     6073 100-00W 18-00N",
            ]
        ],

        #Very accurate
        "Dominican_Republic_Puerto_Rico_Area" => [
            "ENR_CA03",
            "2102", "597", "10797", "6102",
            [
                "  2128     1044 72-00W 20-30N",
                "  6444     1021 68-00W 20-30N",
                "  10760     1039 64-00W 20-30N",
                "  10739     3309 64-00W 18-30N",
                "  10714     6093 64-00W 16-00N",
                "  6446     6076 68-00W 16-00N",
                "  2179     6098 72-00W 16-00N",
                "  2156     3875 72-00W 18-00N",
            ]
        ],

        #Pretty accurate
        "ENR_CL01" => [
            "ENR_CL01",
            "2102", "490", "13797", "6103",
            [
                "   2518      1076 116-00W 35-00N",
                "   7316      655  107-00W 32-00N",
                "  13407      884   96-00W 27-00N",
                "  13415     3227   98-00W 23-00N",
                "  13620     5943  100-00W 18-00N",
                "   7757     5954  111-00W 23-00N",
                "   2206     5806  121-00W 28-00N",
                "   2287     3855  119-00W 31-00N",
            ]
        ],

        #Ok, some parts off by ~1000m
        "ENR_CL02" => [
            "ENR_CL02",
            "2102", "473", "13797", "6103",
            [
                "   2181     877    97-00W 27-00N",
                "   7924     651    86-00W 22-00N",
                "  13556     497    75-00W 17-00N",
                "  13786    3001    77-00W 12-00N",
                "  13608    5637    80-00W 07-00N",
                "   8166    5946    91-00W 12-00N",
                "   2163    5535   102-00W 19-00N",
                "   2382    3128    99-00W 23-00N",

            ]
        ],

        #Pretty accurate
        #Points are clockwise from upper left
        "ENR_CL03" => [
            "ENR_CL03",
            "2102", "499", "13797", "6103",
            [
                "   2284     1024     100-00W 29-00N",
                "   7811      523      88-00W 30-00N",
                "  13342      709      76-00W 30-00N",
                "  13698     2797      75-00W 26-00N",
                "  13550     5729      75-00W 20-00N",
                "   7707     5998      88-00W 19-00N",
                "   2332     5973     100-00W 19-00N",
                "   2308     3563     100-00W 24-00N",
            ]
        ],

        #Pretty accurate
        #Points are clockwise from upper left
        "ENR_CL05" => [
            "ENR_CL05",
            "2102", "498", "13797", "6103",
            [
                "   2574      807     81-00W 28-00N",
                "   5895      738     74-00W 28-00N",
                "   8740      999     68-00W 27-30N",
                "   9209     2301     67-00W 25-00N",
                "  13665     2886     57-30W 24-00N",
                "  13352     5857     58-00W 18-00N",
                "   7808     6033     70-00W 17-30N",
                "   2261     5888     82-00W 18-00N",
                "   2198     3921     82-00W 22-00N",
                "   7800     3322     70-00W 23-00N",
            ]
        ],

        #Pretty accurate
        #Points are clockwise from upper left
        "ENR_CL06" => [
            "ENR_CL06",
            "2102", "483", "13796", "6121",
            [
                "   2129     1051     78-00W 19-00N",
                "   7241      691     70-00W 20-00N",
                "  13641      544     60-00W 21-00N",
                "  13327     3850     60-00W 16-00N",
                "  13766     5832     59-00W 13-00N",
                "   7495     5935     69-00W 12-00N",
                "   2520     5620     77-00W 12-00N",
                "   2342     3040     77-30W 16-00N",
            ]
        ],
    );

    foreach my $destination_chart_name ( sort keys %charts ) {

        #$destination_chart_name is what we'll call the final chart
        #Pull out the relevant data for each inset
        my $sourceRaster =
          $linkedRastersDirectory . $charts{$destination_chart_name}[0];
        my $ulX         = $charts{$destination_chart_name}[1];
        my $ulY         = $charts{$destination_chart_name}[2];
        my $lrX         = $charts{$destination_chart_name}[3];
        my $lrY         = $charts{$destination_chart_name}[4];
        my $gcpArrayRef = $charts{$destination_chart_name}[5];

        my $clipped_raster =
          $clippedRastersDirectory . $destination_chart_name . ".vrt";
        my $warped_raster =
          $warpedRastersDirectory . $destination_chart_name . ".tif";
        say $destination_chart_name;

        #create the string of ground control points
        my $gcpString = createGcpString( $gcpArrayRef, $ulX, $ulY );

        #cut out the inset from source raster and add GCPs
        cutOutInsetFromSourceRaster( $sourceRaster, $ulX, $ulY, $lrX, $lrY,
            $gcpString, $clipped_raster );

        #warp and georeference the clipped file
        warpRaster( $clipped_raster, $warped_raster );
    }
    return 0;
}

sub coordinateToDecimal {

    my ( $deg, $min, $sec, $declination ) = validate_pos(
        @_,
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR }
    );

    my $signeddegrees;

    return "" if !( $declination =~ /[NSEW]/i );

    $deg = $deg / 1;
    $min = $min / 60;
    $sec = $sec / 3600;

    $signeddegrees = ( $deg + $min + $sec );

    if ( ( $declination =~ /[SW]/i ) ) {
        $signeddegrees = -($signeddegrees);
    }

    given ($declination) {
        when (/N|S/) {

            #Latitude is invalid if less than -90  or greater than 90
            $signeddegrees = "" if ( abs($signeddegrees) > 90 );
        }
        when (/E|W/) {

            #Longitude is invalid if less than -180 or greater than 180
            $signeddegrees = "" if ( abs($signeddegrees) > 180 );
        }
        default {
        }

    }

    say "Deg: $deg, Min:$min, Sec:$sec, Decl:$declination -> $signeddegrees"
      if $main::debug;
    return ($signeddegrees);
}

sub cutOutInsetFromSourceRaster {
    my ( $sourceRaster, $ulX, $ulY, $lrX, $lrY, $gcpString, $destinationRaster )
      = validate_pos(
        @_,
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR },
      );

    say "Clip: $sourceRaster -> $destinationRaster, $ulX, $ulY, $lrX, $lrY";

    #Create the source window string for gdal
    my $srcWin =
      $ulX . " " . $ulY . " " . eval( $lrX - $ulX ) . " " . eval( $lrY - $ulY );

    #     say $srcWin;

    #Assemble the command
    #Note the "pdf" added in to the file name since I'm to lazy to cut it out earlier
    my $gdal_translateCommand =
        './memoize.py '
      . $main::compiled_gdal_dir
      . "gdal_translate \\
      -strict \\
      -of VRT \\
      -srcwin $srcWin \\
      -a_srs WGS84 \\
      $gcpString \\
      '$sourceRaster.pdf.tif' \\
      '$destinationRaster'";

    if ($main::debug) {
        say $gdal_translateCommand;
        say "";
    }

    #Run gdal_translate
    my $gdal_translateoutput = qx($gdal_translateCommand);

    my $retval = $? >> 8;

    if ( $retval != 0 ) {
        carp
          "Error executing gdal_translate.  Is it installed? Return code was $retval";
        croak "return code: $retval";
    }
    say $gdal_translateoutput if $main::debug;

    return;

}

sub warpRaster {
    my ( $sourceRaster, $destinationRaster ) =
      validate_pos( @_, { type => SCALAR }, { type => SCALAR }, );

    say "warp: $sourceRaster -> $destinationRaster";

    #Assemble the command
    my $gdalWarpCommand =
        './memoize.py '
      . $main::compiled_gdal_dir
      . "gdalwarp \\
         -t_srs WGS84 \\
         -r lanczos \\
         -dstalpha \\
         -overwrite \\
         $sourceRaster \\
         $destinationRaster";

    if ($main::debug) {
        say $gdalWarpCommand;
        say "";
    }

    #Run gdalwarp
    my $gdalWarpOutput = qx($gdalWarpCommand);

    my $retval = $? >> 8;

    if ( $retval != 0 ) {
        carp "Error executing gdalwarp.  Return code was $retval";
        return $retval;
    }
    say $gdalWarpOutput if $main::debug;

    say "Overviews: $sourceRaster -> $destinationRaster";

    my $gdaladdoCommand =
        './memoize.py '
      . $main::compiled_gdal_dir
      . "gdaladdo \\
        -ro \\
        -r gauss \\
        --config INTERLEAVE_OVERVIEW PIXEL \\
        --config COMPRESS_OVERVIEW JPEG \\
        --config BIGTIFF_OVERVIEW IF_NEEDED \\
         $destinationRaster \\
        2 4 8 16 32 64";

    if ($main::debug) {
        say $gdaladdoCommand;
        say "";
    }

    #Run gdalwarp
    my $gdaladdoOutput = qx($gdaladdoCommand);

    $retval = $? >> 8;

    if ( $retval != 0 ) {
        carp "Error executing gdalwarp.  Return code was $retval";
        return $retval;
    }
    say $gdaladdoOutput if $main::debug;

    return;
}

sub createGcpString {
    my ( $gcpArrayRef, $ul_x, $ul_y ) = validate_pos(
        @_,
        { type => ARRAYREF },
        { type => SCALAR },
        { type => SCALAR },
    );
    my $gcpString;

    #Create the gcpString from the array of gcp entries
    foreach (@$gcpArrayRef) {
        my ( $lonDecimal, $latDecimal );

        #Pull out components
        $_ =~ m/
              (?<rasterX>\d+) \s+ 
              (?<rasterY>\d+) \s+
              (?<lonDegrees>\d{2,}) - (?<lonMinutes>\d+) (?<lonDeclination>[E|W]) \s+
              (?<latDegrees>\d{2,}) - (?<latMinutes>\d+) (?<latDeclination>[N|S])
              /ix;

        #Make these pixel coordinates relative to the smaller window of the inset
        my $rasterX = $+{rasterX} - $ul_x;
        my $rasterY = $+{rasterY} - $ul_y;

        my $lonDegrees     = $+{lonDegrees};
        my $lonMinutes     = $+{lonMinutes};
        my $lonSeconds     = 0;
        my $lonDeclination = $+{lonDeclination};

        my $latDegrees     = $+{latDegrees};
        my $latMinutes     = $+{latMinutes};
        my $latSeconds     = 0;
        my $latDeclination = $+{latDeclination};

        say
          "$lonDegrees-$lonMinutes-$lonSeconds-$lonDeclination,$latDegrees-$latMinutes-$latSeconds-$latDeclination"
          if $main::debug;

        #If all seems ok, convert to decimal
        if (   $lonDegrees
            && $lonMinutes
            && $lonDeclination
            && $latDegrees
            && $latMinutes
            && $latDeclination )
        {
            $lonDecimal =
              coordinateToDecimal( $lonDegrees, $lonMinutes, $lonSeconds,
                $lonDeclination );
            $latDecimal =
              coordinateToDecimal( $latDegrees, $latMinutes, $latSeconds,
                $latDeclination );
        }
        else {
            die "Missing some part of coordinate";
        }
        say "$lonDecimal, $latDecimal" if $main::debug;

        #Add it to the overall GCP string
        $gcpString =
          $gcpString . "-gcp $rasterX $rasterY $lonDecimal $latDecimal ";
    }

    say "gcpString: $gcpString" if $main::debug;
    return $gcpString;
}

