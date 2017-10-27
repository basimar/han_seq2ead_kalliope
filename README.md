# han_seq2ead_kalliope
Scripts to transform MARC21-date from the HAN catalogue into ead for the Kalliope metacatalogue

In order to run these scripts the following folders have to be created
./input
./tmp
./output
./output/validation
./output/no_validation

INPUT: Complete export of the HAN catalogue in Aleph sequential format, stored as dsv05.seq in ./inputA
OUTPUT: The generated ead-files will be saved in ./output/validation (if they validate against the ead.xsd file)
        or in ./output/no_validation if they do not validate.

How to run this script: Execute make-seq2ead.sh

Requirements: Catmandu Perl-Modules (from cpan) and libxml2-utils and xsltproc linux packages.
