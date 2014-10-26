#!/bin/bash
export PATH=/opt/local/bin/:/opt/local/sbin:$PATH:/usr/local/bin:

convertPath=`which convert`
echo ${convertPath}
if [[ ! -f ${convertPath} || -z ${convertPath} ]]; then
  echo "WARNING: Skipping Icon versioning, you need to install ImageMagick and ghostscript (fonts) first, you can use brew to simplify process:
  brew install imagemagick ghostscript"
exit 0;
fi

git=`sh /etc/profile; which git`
build_num=`"$git" rev-list --all | wc -l | tr -d ' '`
branch=`"$git" rev-parse --abbrev-ref HEAD`
commit=`"$git" rev-parse --short HEAD`

branch="${branch}->${BUNDLE_DISPLAY_NAME_SUFFIX}"

caption="$build_num\n${branch}\n${commit}"
echo $caption

function abspath() { pushd . > /dev/null; if [ -d "$1" ]; then cd "$1"; dirs -l +0; else cd "`dirname \"$1\"`"; cur_dir=`dirs -l +0`; if [ "$cur_dir" == "/" ]; then echo "$cur_dir`basename \"$1\"`"; else echo "$cur_dir/`basename \"$1\"`"; fi; fi; popd > /dev/null; }

function processIcon() {
	iconFile=$1
	storedIconFile=$iconFile.tmp
	normalizedIconFile=$iconFile.normalized

    if [[ -f ${storedIconFile} ]]; then
      echo "found previous file at path ${storedIconFile}, using it as base"
      mv "${storedIconFile}" "${iconFile}"
    fi
    
#    if [ $CONFIGURATION = "Release" ]; then
#      cp "${base_path}" "$target_path"
#      return 0;
#    fi
    
    echo "Reverting optimized PNG to normal"
    # Normalize
    xcrun -sdk iphoneos pngcrush -revert-iphone-optimizations -q "${iconFile}" "${normalizedIconFile}"
    
    # move original pngcrush png to tmp file
    echo "moving pngcrushed png file at ${iconFile} to ${storedIconFile}"
    mv "${iconFile}" "${storedIconFile}"
    
    # Rename normalized png's filename to original one
    echo "Moving normalized png file to original one ${normalizedIconFile} to ${iconFile}"
    mv "${normalizedIconFile}" "${iconFile}"
    
    width=`identify -format %w ${iconFile}`
    height=`identify -format %h ${iconFile}`
    band_height=$((($height * 47) / 100))
    band_position=$(($height - $band_height))
    text_position=$(($band_position - 3))
    point_size=$(((13 * $width) / 100))
    
    echo "Image dimensions ($width x $height) - band height $band_height @ $band_position - point size $point_size"
    
    #
    # blur band and text
    #
    tmpDir=$(mktemp -dt "\$0")
    convert ${iconFile} -blur 10x8 ${tmpDir}/blurred.png
    convert ${tmpDir}/blurred.png -gamma 0 -fill white -draw "rectangle 0,$band_position,$width,$height" ${tmpDir}/mask.png
    convert -size ${width}x${band_height} xc:none -fill 'rgba(0,0,0,0.2)' -draw "rectangle 0,0,$width,$band_height" ${tmpDir}/labels-base.png
    convert -background none -size ${width}x${band_height} -pointsize $point_size -fill white -gravity center -gravity South caption:"$caption" ${tmpDir}/labels.png
    
    convert ${iconFile} ${tmpDir}/blurred.png ${tmpDir}/mask.png -composite ${tmpDir}/temp.png

    #
    # compose final image
    #
    filename=New${base_file}
    convert ${tmpDir}/temp.png ${tmpDir}/labels-base.png -geometry +0+$band_position -composite ${tmpDir}/labels.png -geometry +0+$text_position -geometry +${w}-${h} -composite "${iconFile}"
    
    # clean up
    rm -r ${tmpDir}
    
    echo "Overlayed ${iconFile}"
}

iconFiles="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/AppIcon*.png"

for file in $iconFiles; do
	processIcon $file
done
