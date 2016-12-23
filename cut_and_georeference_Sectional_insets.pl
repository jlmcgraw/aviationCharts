#!/usr/bin/perl

# Cut out and georeference insets from FAA aeronautical maps
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
    my $chartType = 'sectional';
    
    #The inset's name
    #Their source raster, upper left X, upper left Y, lower right X, lower right Y pixel coordinates of the inset
    #The Ground Control Points for each inset relative to clipped file: Pixel X, Pixel Y, Longitude, Latitude
    my %HashOfInsets = (
        "Dutch_Harbor" => [
            "Dutch_Harbor_SEC",
            "10288", "427", "13556", "3445",
            [
                "  68     42 167-00W 54-15N",
                " 837     47 166-45W 54-15N",
                "1607     47 166-30W 54-15N",
                "2377     47 166-15W 54-15N",
                "3147     43 166-00W 54-15N",
                "  59   1357 167-00W 54-00N",
                " 833   1361 166-45W 54-00N",
                "1607   1363 166-30W 54-00N",
                "2381   1362 166-15W 54-00N",
                "3147   1357 166-00W 54-00N",
                "  49   2671 167-00W 53-45N",
                " 828   2676 166-45W 53-45N",
                "1608   2677 166-30W 53-45N",
                "2387   2676 166-15W 53-45N",
                "3165   2671 166-00W 53-45N"
            ]
        ],
        ,
        "Pribilof_Islands" => [
            "Dutch_Harbor_SEC",
            "5142", "445", "7334", "3945",
            [
                "268 438 170-30W 57-30N",
                "976 441 170-00W 57-30N",
                "1684 438 169-30W 57-30N",
                "257 1753 170-30W 57-00N",
                "976 1756 170-00W 57-00N",
                "1694 1754 169-30W 57-00N",
                "248 3069 170-30W 56-30N",
                "976 3072 170-00W 56-30N",
                "1704 3070 169-30W 56-30N"
            ]
        ],
        "Jacksonville" => [
            "Jacksonville_SEC",
            "13676", "4", "16592", "3353",
            [
                "1116 1134  81-45W  30-30N",
                "1116 2447  81-45W  30-15N",
                "2252 1134  81-30W  30-30N",
                "2252 2447  81-30W  30-15N"
            ]
        ],
        "Juneau" => [
            "Juneau_SEC",
            "1696", "4107", "4146", "5765",
            [
                " 596  253 134-45W 58-27N",
                "1285  245 134-30W 58-27N",
                "1973  234 134-15W 58-27N",
                " 607 1305 134-45W 58-15N",
                "1301 1297 134-30W 58-15N",
                "1993 1285 134-15W 58-15N"
            ]
        ],
        "Ketchikan" => [
            "Ketchikan_SEC",
            "4730", "1007", "7144", "4328",
            [
                "    113 607 132-00W 55-30N",
                "    859 611 131-45W 55-30N",
                "   1606 611 131-30W 55-30N",
                "   2352 609 131-15W 55-30N",
                "   105 1922 132-00W 55-15N",
                "   856 1926 131-45W 55-15N",
                "  1607 1926 131-30W 55-15N",
                "  2359 1923 131-15W 55-15N",
                "    97 3237 132-00W 55-00N",
                "   853 3240 131-45W 55-00N",
                "  1608 3241 131-30W 55-00N",
                "  2364 3238 131-15W 55-00N"
            ]
        ],
        "Kodiak" => [
            "Kodiak_SEC",
            "13811", "8576", "16457", "11989",
            [
                " 531 264  152-45W 58-00N",
                "1229 265  152-30W 58-00N",
                "1927 264  152-15W 58-00N",
                " 526 1578 152-45W 57-45N",
                "1229 1578 152-30W 57-45N",
                "1932 1578 152-15W 57-45N",
                " 521 2893 152-45W 57-30N",
                "1229 2893 152-30W 57-30N",
                "1937 2893 152-15W 57-30N"
            ]
        ],
        "Norfolk" => [
            "Washington_SEC",
            "14108", "6565", "16556", "8952",
            [
                "  61 1021 76-30W 37-00N",
                "1112 1020 76-15W 37-00N",
                "2162 1016 76-00W 37-00N",
                "  61 2330 76-30W 36-45N",
                "1115 2330 76-15W 36-45N",
                "2168 2325 76-00W 36-45N "
            ]
        ],
    );

    #Number of arguments supplied on command line
    my $num_args = $#ARGV + 1;

    if ( $num_args != 1 ) {
        say "Usage: $0 <destination_root_dir>";
        exit;
    }

    #Get the base directory from command line
    my $destinationRoot = $ARGV[0];
    
    #For files that have a version in their name, this is where the links to the lastest version
    #will be stored
    my $linkedRastersDirectory = "$destinationRoot/expandedRasters/$chartType/";

    #Where clipped rasters are stored
    my $clippedRastersDirectory = "$destinationRoot/clippedRasters/insets/";

    #Where warped rasters are stored
    my $warpedRastersDirectory = "$destinationRoot/warpedRasters/insets/";

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

    say "linkedRastersDirectory: $linkedRastersDirectory";
    say "clippedRastersDirectory: $clippedRastersDirectory ";
    say "warpedRastersDirectory: $warpedRastersDirectory";
    
    foreach my $key ( keys %HashOfInsets ) {

        #$key is the inset's name
        #Pull out the relevant data for each inset
        my $sourceChart = $HashOfInsets{$key}[0];
        my $ulX         = $HashOfInsets{$key}[1];
        my $ulY         = $HashOfInsets{$key}[2];
        my $lrX         = $HashOfInsets{$key}[3];
        my $lrY         = $HashOfInsets{$key}[4];
        my $gcpArrayRef = $HashOfInsets{$key}[5];

        my $clippedRaster = $key . "_Inset.vrt";
        my $finalRaster   = $key . "_Inset.tif";
        say $key;

        #create the string of ground control points
        my $gcpString = createGcpString($gcpArrayRef);

        #cut out the inset from source raster and add GCPs
        cutOutInsetFromSourceRaster( $sourceChart, $ulX, $ulY, $lrX, $lrY,
            $gcpString, $clippedRaster, $linkedRastersDirectory, $clippedRastersDirectory );

        #warp and georeference the clipped file
        warpRaster( $clippedRaster, $finalRaster, $clippedRastersDirectory, $warpedRastersDirectory );
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
    my ( $sourceChart, $ulX, $ulY, $lrX, $lrY, $gcpString, $destinationRaster, $linkedRastersDirectory, $clippedRastersDirectory )
      = validate_pos(
        @_,
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR },
      );

    my $sourceRaster = $linkedRastersDirectory . $sourceChart . ".vrt";

    #Add the destination path to the raster name
    $destinationRaster = $clippedRastersDirectory . $destinationRaster;

    say "Clip: $sourceRaster -> $destinationRaster, $ulX, $ulY, $lrX, $lrY";

    #Create the source window string for gdal
    my $srcWin =
      $ulX . " " . $ulY . " " . eval( $lrX - $ulX ) . " " . eval( $lrY - $ulY );
    say $srcWin;

    #Assemble the command
    my $gdal_translateCommand = "gdal_translate \\
      -strict \\
      -of VRT \\
      -srcwin $srcWin \\
      -a_srs WGS84 \\
      -r lanczos  \\
      $gcpString \\
      '$sourceRaster' \\
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
        die "return code: $retval";
    }
    say $gdal_translateoutput if $main::debug;

    return;

}

sub warpRaster {
    my ( $sourceRaster, $destinationRaster, $clippedRastersDirectory, $warpedRastersDirectory  ) =
      validate_pos( @_, 
        { type => SCALAR }, 
        { type => SCALAR },
        { type => SCALAR }, 
        { type => SCALAR }, 
        );

    $sourceRaster = $clippedRastersDirectory . $sourceRaster;

    #Add the destination path to the raster name
    $destinationRaster = $warpedRastersDirectory . $destinationRaster;

    say "warp: $sourceRaster -> $destinationRaster";

    #Assemble the command
    my $gdalWarpCommand = "gdalwarp \\
        -t_srs WGS84 \\
        -tps \\
        -dstalpha \\
        -r lanczos  \\
        -multi \\
        -wo NUM_THREADS=ALL_CPUS  \\
        -wm 1024 \\
        --config GDAL_CACHEMAX 1024 \\
        -co TILED=YES \\
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
        die "return code: $retval";
    }
    say $gdalWarpOutput if $main::debug;

    return;
}

sub createGcpString {
    my ($gcpArrayRef) = validate_pos( @_, { type => ARRAYREF }, );
    my $gcpString;

    #Create the gcpString from the array of gcp entries
    foreach (@$gcpArrayRef) {
        my ( $lonDecimal, $latDecimal );

        #Pull out components
        $_ =~ m/
              (?<rasterX>\d+) \s+ 
              (?<rasterY>\d+) \s+
              (?<lonDegrees>\d{2,})-(?<lonMinutes>\d+)(?<lonDeclination>[E|W]) \s+
              (?<latDegrees>\d{2,})-(?<latMinutes>\d+)(?<latDeclination>[N|S])
              /ix;

        my $rasterX = $+{rasterX};
        my $rasterY = $+{rasterY};

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
        say "$lonDecimal, $latDecimal" if $main::debug;

        #Add it to the overall GCP string
        $gcpString =
          $gcpString . "-gcp $rasterX $rasterY $lonDecimal $latDecimal ";
    }

    say "gcpString: $gcpString" if $main::debug;
    return $gcpString;
}

