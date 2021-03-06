#!/bin/bash

# http://plantuml.com/command-line
# http://forum.plantuml.net/4145/is-the-png-output-size-limited-to-4096-pixels-only
# https://ryanstutorials.net/bash-scripting-tutorial/bash-functions.php

# base="$(find . -path ./vendor -prune -o -path ./tests -prune -o -path ./docs -prune -o -type f -name "*.php" -print0 | xargs -0)"


# -- Helpers
function info {
    echo " "
    echo "--> $1"
    echo " "
}

function sleepAndCountDown {
    counter=0
    interval=1
    echo "  INFO : start counting ..."
    while [ $counter -lt $1 ]; do
        sleep ${interval};
        let "counter++"
        echo "  INFO :    ${counter}"
    done
    echo "  INFO : ... done!"
    exit 0
}

function preparePumlDir {
    puml_dir=$1

    if [ ! -d UML/$puml_dir ];
    then
        info "Make UML directories in : UML/$puml_dir"
        mkdir -p UML/$puml_dir
    fi
}

function generatePlantUml {
    phpfiles=$1
    puml_file=$2
    plantuml_jar=$3
    generatePlantUmlAsPng=$4
    debug=$5

    if [ $debug == 'yes' ];
    then
        info "debug mode : $debug"
        echo "phpfiles : $phpfiles"
        echo "puml_file : $puml_file"
        echo "plantuml_jar : $plantuml_jar"
    fi

    info "Generate PlantUML file for : $puml_file"
    echo $phpfiles | xargs vendor/bin/php-plantumlwriter write --without-doc-content -vvv -- > UML/$puml_file.puml
    # cat UML/$puml_file.puml
    
    if [ $generatePlantUmlAsPng == 'yes' ];
    then
        info "Generate PlantUML PNG file for : $puml_file"
        java -Xms128m -Xmx5120m -DPLANTUML_LIMIT_SIZE=9999999 -jar $plantuml_jar -progress -enablestats -realtimestats -duration -failfast2 -tpng UML/$puml_file.puml
    fi
    
    git status
}

# -- Variables
debug=yes
generatePlantUmlAsPng=yes

plantuml_jar=plantuml.1.2017.19.jar

yii2_core_basedir=vendor/yiisoft/yii2-dev/framework
yii2_ext_basedir=vendor/yiisoft/yii2
yii2_exts=( authclient bootstrap composer debug elasticsearch faker gii httpclient imagine jui mongodb queue redis shell smarty sphinx swiftmailer twig )

additional_pkg_dirs=( vendor/bizley/migration )

# -- Scripts

preparePumlDir $yii2_core_basedir
info "Processing PHP files : yii2 core"
puml_file="$yii2_core_basedir/core"
phpfiles="$yii2_core_basedir/Yii.php $yii2_core_basedir/BaseYii.php"
generatePlantUml "$phpfiles" "$puml_file" "$plantuml_jar" "$generatePlantUmlAsPng" "$debug"

for puml_file in $yii2_core_basedir/*;
do
    if [ -d $puml_file -a $puml_file != $yii2_core_basedir/assets -a $puml_file != $yii2_core_basedir/views ];
    then
        info "Search PHP files for : $puml_file"
        phpfiles="$(find $puml_file -type f -name "*.php" -print0 | xargs -0)"

        generatePlantUml "$phpfiles" "$puml_file" "$plantuml_jar" "$generatePlantUmlAsPng" "$debug"
    fi
done

preparePumlDir $yii2_ext_basedir
for ext in "${yii2_exts[@]}"
do
    puml_file="$yii2_ext_basedir-$ext"
    info "Search PHP files for : $puml_file"
    if [ $ext == 'queue' ];
    then
        phpfiles="$(find $puml_file/src -type f -name "*.php" -print0 | xargs -0)"
    else
        phpfiles="$(find $puml_file -path $puml_file/tests -prune -o -type f -name "*.php" -print0 | xargs -0)"
    fi

    generatePlantUml "$phpfiles" "$puml_file" "$plantuml_jar" "$generatePlantUmlAsPng" "$debug"
done

for pkg_dir in "${additional_pkg_dirs[@]}"
do
    preparePumlDir $pkg_dir
    puml_file=$pkg_dir
    info "Search PHP files for : $puml_file"
    phpfiles="$(find $puml_file -path $puml_file/tests -prune -o -type f -name "*.php" -print0 | xargs -0)"
    generatePlantUml "$phpfiles" "$puml_file" "$plantuml_jar" "$generatePlantUmlAsPng" "$debug"
done
