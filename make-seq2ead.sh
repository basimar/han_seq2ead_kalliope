#!/bin/bash

# make-seq2ead.sh
#   Export-Skript für DSV05-Daten nach Kalliope im ead-Format
# 
# author:   
#   basil.marti@unibas.ch
#
# history:

DO_DOWNLOAD=1
DO_TRANSFORM=1
DO_SPLIT=1
DO_FINISH=1

HOME=/opt/scripts/han_seq2ead_kalliope/
DATA=/opt/data/dsv05/
FILES=tmp/split/*

LINE='------------------------------------------------'

echo $LINE
echo "Exporting DSV05 data for Kalliope"
echo "Attention: Script takes several hours to run!"
echo "START:  $(date)"
echo $LINE
echo $LINE

cd $HOME

if [ "$DO_DOWNLOAD" == "1" ]; then
    echo $LINE
    echo "*Getting DSV05 data from Aleph-Server" 
    echo $LINE

    # Auskommentiert für Einsatz auf ub-catmandu
    # ./download-dsv05-sequential.sh 
    # mv ./dsv05.seq input/

    cp $DATA/dsv05.seq $HOME/input/
fi

if [ "$DO_TRANSFORM" == "1" ]; then
    echo $LINE
    echo "*Transforming DSV05 data to ead" 
    echo $LINE
    perl seq2ead.pl input/dsv05.seq tmp/ead.xml
fi


if [ "$DO_SPLIT" == "1" ]; then
    echo $LINE
    echo "*Splitting ead-file"
    echo $LINE
    cd tmp/split
    rm *
    cd $HOME

    cd output/
    rm validation_errors.txt
    rm validation_ok.txt
    cd $HOME

    cd output/validation
    rm *
    cd $HOME

    cd output/no_validation
    rm *
    cd $HOME

    perl split.pl tmp/ead.xml tmp/split isil
fi

if [ "$DO_FINISH" == "1" ]; then
    echo $LINE
    echo "*Finishing ead-files"
    echo $LINE

    for f in $FILES
    do
        echo "Finishing file $f"
        xsltproc sanitise.xsl $f > $f.san
        xmllint --format $f.san > $f
        rm $f.san
        sed 's/<ead>/<ead xmlns="urn:isbn:1-931666-22-9" xmlns:xlink="http:\/\/www.w3.org\/1999\/xlink" xmlns:xsi="http:\/\/www.w3.org\/2001\/XMLSchema-instance" xsi:schemaLocation="urn:isbn:1-931666-22-9 http:\/\/www.loc.gov\/ead\/ead.xsd">/g' $f > $f.valid
        mv $f.valid $f
        output="$(xmllint --noout --schema ead.xsd $f 2>&1)"
    
        if [[ $output =~ fails.to.validate ]];
            then 
                cp $f output/no_validation/
                echo $output >> output/validation_errors.txt;
            else
                cp $f output/validation/
                echo $output >> output/validation_ok.txt;
        fi 
    done
fi
echo "END:  $(date)"
