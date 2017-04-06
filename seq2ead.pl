#!/usr/bin/env perl

use strict;
use warnings;
no warnings 'uninitialized';

# Data::Dumper for debugging
use Data::Dumper;

# XML::Writer to write output file
use XML::Writer;
use IO::File;

# Unicode-support in the Perl script and for output
use utf8;
binmode STDOUT, ":utf8";

# Min Max functions
use List::Util qw(min max);

# Read out current date
use DateTime;
my $dt            = DateTime->now;
my $syncdate      = $dt->ymd('');
my $syncdatehuman = $dt->datetime() . "+00:00";

# Catmandu-Module for importin Aleph sequential
use Catmandu::Importer::MARC::ALEPHSEQ;

# Information about output file (ead-xml)
my $output    = IO::File->new(">$ARGV[1]");
my $xlink     = "http://www.w3.org/1999/xlink";
my $xmlns     = "urn:isbn:1-931666-22-9";
my $xsi       = "http://www.w3.org/2001/XMLSchema-instance";
my $xsischema = "urn:isbn:1-931666-22-9 http://www.loc.gov/ead/ead.xsd";
my $writer    = XML::Writer->new(
    OUTPUT     => $output,
    NEWLINES   => 1,
    ENCODING   => "utf-8",
    NAMESPACES => 1,
    PREFIX_MAP => {
        $xlink     => 'xlink',
        $xsi       => 'xsi',
        $xsischema => 'xsi:schemaLocation',
        $xmlns     => ''
    }
);

# Check arguments
die "Argumente: $0 Input-Dokument (alephseq), Output Dokument\n"
  unless @ARGV == 2;

# Hash with concordance 351$c and ead-elements
my %lvl = (
    'Bestand=Fonds'                     => 'archdesc',
    'Teilbestand=Sub-fonds=Sous-fonds'  => 'c',
    'Serie=Series=Série'                => 'c',
    'Teilserie=Sub-series=Sous-série'   => 'c',
    'Dossier=File'                      => 'c',
    'Teildossier=Sub-file=Sous-dossier' => 'c',
    'Dokument=Item=Pièce'               => 'c'
);

# Hash with concordance 351$c and ead level attributes
my %lvlarg = (
    'Bestand=Fonds'                                    => 'collection',
    'Teilbestand=Sub-fonds=Sous-fonds'                 => 'fonds',
    'Serie=Series=Série'                               => 'class',
    'Teilserie=Sub-series=Sous-série'                  => 'class',
    'Dossier=File'                                     => 'file',
    'Teildossier=Sub-file=Sous-dossier'                => 'file',
    'Dokument=Item=Pièce'                              => 'item',
    'Abteilung=Division'                               => 'file',
    'Hauptabteilung=Main division=Division principale' => 'file'
);

# Hash with concordance 852$a and ISIL
my %isil = (
    'Rorschach'        => 'CH-000956-2',
    'Gosteli'          => 'CH-000924-9',
    'Ausserrhoden'     => 'CH-000095-1',
    'Vadiana'          => 'CH-000009-3',
    'SWA'              => 'CH-000133-4',
    'Thurgau'          => 'CH-000086-2',
    'Stiftsbibliothek' => 'CH-000093-7',
    'UBHandschriften'  => 'CH-000004-7',
    'Solothurn'        => 'CH-000045-X',
    'Luzern'           => 'CH-000006-1'
);

# Hash with concordance MARC21 relator codes and ead relator codes
my %relator = (
    'Andere'                     => 'Beiträger',
    'Autor'                      => 'Verfasser',
    'Bildhauer'                  => 'Künstler',
    'Buchbinder/Buchbinderei'    => 'Buchbinder',
    'Darsteller/Interpret'       => 'Interpret',
    'Filmemacher'                => 'Regisseur',
    'Früherer Eigentümer'        => 'Vorbesitzer',
    'Gegenwärtiger Eigentümer'   => 'Inhaber',
    'Illustrator/Atelier'        => 'Illustrator',
    'Kartograph'                 => 'Verfasser',
    'Mitwirkender'               => 'Beiträger',
    'Sänger'                     => 'Künstler',
    'Schreiber/Scriptorium'      => 'Schreiber',
    'Sprecher/Erzähler'          => 'Sprecher',
    'Textdichter'                => 'Texter',
    'Widmungsverfasser'          => 'Widmungsschreiber',
    'Zweifelhafter Autor'        => 'Verfasser',
);

# Hash with concordance MARC21 language codes and written language name
my %language = (
    afr => 'Afrikaans',
    alb => 'Albanisch',
    chu => 'Altbulgarisch, Kirchenslawisch',
    grc => 'Altgriechisch',
    san => 'Sanskrit',
    eng => 'Englisch',
    ara => 'Arabisch',
    arc => 'Aramäisch',
    arm => 'Armenisch',
    aze => 'Azeri',
    gez => 'Äthiopisch',
    baq => 'Baskisch',
    bel => 'Weissrussisch',
    ben => 'Bengali',
    bur => 'Burmesisch',
    cze => 'Tschechisch',
    bos => 'Bosnisch',
    bul => 'Bulgarisch',
    roh => 'Rätoromanisch',
    spa => 'Spanisch',
    chi => 'Chinesisch',
    dan => 'Dänisch',
    egy => 'Ägyptisch',
    ger => 'Deutsch',
    gsw => 'Schweizerdeutsch',
    gla => 'Gälisch',
    est => 'Estnisch',
    fin => 'Finnisch',
    dut => 'Niederländisch',
    fre => 'Französisch',
    gle => 'Gälisch',
    geo => 'Georgisch',
    gre => 'Neugriechisch',
    heb => 'Hebräisch',
    hin => 'Hindi',
    ind => 'Indonesisch',
    ice => 'Isländisch',
    ita => 'Italienisch',
    jpn => 'Japanisch',
    yid => 'Jiddisch',
    khm => 'Khmer',
    kaz => 'Kasachisch',
    kas => 'Kashmiri',
    kir => 'Kirisisch',
    swa => 'Swahili',
    ukr => 'Ukrainisch',
    cop => 'Koptisch',
    kor => 'Koreanisch',
    hrv => 'Kroatisch',
    kur => 'Kurdisch',
    lat => 'Lateinisch',
    lav => 'Lettisch',
    lit => 'Litauisch',
    hun => 'Ungarisch',
    mac => 'Mazedonisch',
    may => 'Malaiisch',
    rum => 'Rumänisch',
    mon => 'Mongolisch',
    per => 'Persisch',
    nor => 'Norwegisch',
    pol => 'Polnisch',
    por => 'Portugiesisch',
    rus => 'Russisch',
    swe => 'Schwedisch',
    srp => 'Serbisch',
    slo => 'Slowakisch',
    slv => 'Slowenisch',
    wen => 'Sorbisch',
    syr => 'Syrisch',
    tgk => 'Tadschikisch',
    tgl => 'Philippinisch',
    tam => 'Tamil',
    tha => 'Siamesisch',
    tur => 'Türkisch',
    tuk => 'Turkmenisch',
    urd => 'Urdu',
    uzb => 'Usbekisch',
    vie => 'Vietnamisch',
    rom => 'Romani'
);

# Define hashes with information exported out of the .seq file (hash key = system number)
my (
    %title,            %alttitle,        %alttitleintro,
    %ausreifung,       %music,           %date,
    %datenorm,         %datenormhuman,   %date008,
    %date008human,     %size,            %dimension,
    %carrier,          %arrangement,     %restrict,
    %content,          %contentform,     %bibliography,
    %level,            %link,            %note,
    %noteA,            %acqinfo,         %relatedmat,
    %bioghist,         %findaid,         %custodhist,
    %einband,          %literatur,       %institution,
    %institutionname,  %signature,       %signaturealt,
    %signatureold,     %isilsysnum,      %isilnum,
    %languages,        %langcodes,       %controlper,
    %controlpernorm,   %controlpergnd,   %controlperfamily,
    %controlkorp,      %controlkorpnorm, %controlkorpgnd,
    %controlkong,      %controlkongnorm, %controlkonggnd,
    %controlsub,       %controlsubnorm,  %controlsubgnd,
    %controlgeo,       %controlgeonorm,  %controlgeognd,
    %controlgenre,     %nebenper,        %nebenpernorm,
    %nebenpergnd,      %nebenperrelator, %nebenkorp,
    %nebenkorpnorm,    %nebenkorpgnd,    %nebenkorprelator,
    %nebenkong,        %nebenkongnorm,   %nebenkonggnd,
    %nebenkongrelator, %originationa,    %originationgnd,
    %hyperlink,        %hyperlinknote,   %hide,
    %catdate,          %catdatehuman,    %sysnumcheck
);

# Sysnum-Array contains all the system numbers of all MARC records
my @sysnum;

# Catmandu importer to read each MARC record and export the information needed to generate the xml file
my $importer = Catmandu::Importer::MARC::ALEPHSEQ->new( file => $ARGV[0] );
$importer->each(
    sub {
        my $data          = $_[0];
        my $sysnum        = $data->{'_id'};
        my $title         = marc_map( $data, '245a' );
        my $titleb        = marc_map( $data, '245b', '-join', ', ' );
        my $titlec        = marc_map( $data, '245c', '-join', ', ' );
        my $titled        = marc_map( $data, '245d', '-join', ', ' );
        my $titlei        = marc_map( $data, '245i', '-join', ', ' );
        my $titlej        = marc_map( $data, '245j', '-join', ', ' );
        my $titlen        = marc_map( $data, '245n', '-join', ', ' );
        my $titlep        = marc_map( $data, '245p', '-join', ', ' );
        my @alttitlea     = marc_map( $data, '246a' );
        my @alttitlen     = marc_map( $data, '246n', '-join', ', ' );
        my @alttitlep     = marc_map( $data, '246p', '-join', ', ' );
        my @alttitleintro = marc_map( $data, '246i' );
        my $ausreifung    = marc_map( $data, '250a' );
        my @music         = marc_map( $data, '254a' );
        my $date          = marc_map( $data, '260c' );
        my $sizea         = marc_map( $data, '300a', '-join', ', ' );
        my $sizee         = marc_map( $data, '300e' );
        my $dimension     = marc_map( $data, '300c', '-join', ', ' );
        my @carrier       = marc_map( $data, '340a', '-join', ', ' );
        my $arrangement   = marc_map( $data, '351a' );
        my $level         = marc_map( $data, '351c' );
        my @note          = marc_map( $data, '500[  ]a' );
        my @noteA         = marc_map( $data, '525a' );
        my @contenta      = marc_map( $data, '505a' );
        my @contentn      = marc_map( $data, '505n' );
        my @contentg      = marc_map( $data, '505g' );
        my @contentt      = marc_map( $data, '505t' );
        my @contentr      = marc_map( $data, '505r' );
        my @contenti      = marc_map( $data, '505i' );
        my @contents      = marc_map( $data, '505s' );
        my @contentv      = marc_map( $data, '505v', '-join', ', ' );
        my @contentforma  = marc_map( $data, '520a' );
        my @contentformb  = marc_map( $data, '520b', '-join', ', ' );
        my @contentform3  = marc_map( $data, '5203' );
        my @restricta     = marc_map( $data, '506a' );
        my @restrictc     = marc_map( $data, '506c' );
        my @bibliographya = marc_map( $data, '510a' );
        my @bibliographyi = marc_map( $data, '510i' );
        my @acqinfo3      = marc_map( $data, '5413' );
        my @acqinfoc      = marc_map( $data, '541c' );
        my @acqinfoa      = marc_map( $data, '541a' );
        my @acqinfod      = marc_map( $data, '541d' );
        my @acqinfoe      = marc_map( $data, '541e' );
        my @acqinfof      = marc_map( $data, '541f' );
        my @relatedmat    = marc_map( $data, '544n' );
        my @bioghista     = marc_map( $data, '545a' );
        my @bioghistb     = marc_map( $data, '545b', '-join', ', ' );
        my @findaid       = marc_map( $data, '555a' );
        my @custodhist    = marc_map( $data, '561a' );
        my @einband       = marc_map( $data, '563a' );
        my @literaturi    = marc_map( $data, '581i' );
        my @literatura    = marc_map( $data, '581a' );
        my @literatur3    = marc_map( $data, '5813', '-join', ', ' );
        my @datenorma     = marc_map( $data, '046a' );
        my @datenormb     = marc_map( $data, '046b' );
        my @datenormc     = marc_map( $data, '046c' );
        my @datenormd     = marc_map( $data, '046d' );
        my @datenorme     = marc_map( $data, '046e' );
        my @controlpera   = marc_map( $data, '600a' );
        my @controlperq   = marc_map( $data, '600q' );
        my @controlperb   = marc_map( $data, '600b' );
        my @controlperc   = marc_map( $data, '600c', '-join', ', ' );
        my @controlperd   = marc_map( $data, '600d' );
        my @controlpergnd = marc_map( $data, '6001' );
        for (@controlpergnd) { s/\(DE-588\)//g }
        my @controlkorpa   = marc_map( $data, '610a' );
        my @controlkorpb   = marc_map( $data, '610b', '-join', ', ' );
        my @controlkorpgnd = marc_map( $data, '6101' );
        for (@controlkorpgnd) { s/\(DE-588\)//g }
        my @controlkonga   = marc_map( $data, '611a' );
        my @controlkonge   = marc_map( $data, '611e', '-join', ', ' );
        my @controlkonggnd = marc_map( $data, '6111' );
        for (@controlkonggnd) { s/\(DE-588\)//g }
        my @controlsuba   = marc_map( $data, '650[ 7]a' );
        my @controlsubv   = marc_map( $data, '650[ 7]v', '-join', ', ' );
        my @controlsubx   = marc_map( $data, '650[ 7]x', '-join', ', ' );
        my @controlsuby   = marc_map( $data, '650[ 7]y', '-join', ', ' );
        my @controlsubz   = marc_map( $data, '650[ 7]z', '-join', ', ' );
        my @controlsubgnd = marc_map( $data, '650[ 7]1' );
        for (@controlsubgnd) { s/\(DE-588\)//g }
        my @controlgeoa   = marc_map( $data, '651[ 7]a' );
        my @controlgeov   = marc_map( $data, '651[ 7]v', '-join', ', ' );
        my @controlgeox   = marc_map( $data, '651[ 7]x', '-join', ', ' );
        my @controlgeoy   = marc_map( $data, '651[ 7]y', '-join', ', ' );
        my @controlgeoz   = marc_map( $data, '651[ 7]z', '-join', ', ' );
        my @controlgeognd = marc_map( $data, '651[ 7]1' );
        for (@controlgeognd) { s/\(DE-588\)//g }
        my @controlgenre  = marc_map( $data, '655[ 7]a' );
        my @nebenpera     = marc_map( $data, '700a' );
        my @nebenperq     = marc_map( $data, '700q' );
        my @nebenperb     = marc_map( $data, '700b' );
        my @nebenperc     = marc_map( $data, '700c', '-join', ', ' );
        my @nebenperd     = marc_map( $data, '700d' );
        my @nebenpert     = marc_map( $data, '700t' );
        my @nebenpern     = marc_map( $data, '700n', '-join', ', ' );
        my @nebenperp     = marc_map( $data, '700p', '-join', ', ' );
        my @nebenperm     = marc_map( $data, '700m', '-join', ', ' );
        my @nebenperr     = marc_map( $data, '700r' );
        my @nebenpers     = marc_map( $data, '700s' );
        my @nebenpero     = marc_map( $data, '700o' );
        my @nebenperh     = marc_map( $data, '700h' );
        my @nebenperrelator = marc_map( $data, '700e' );
        my @nebenpergnd     = marc_map( $data, '7001' );
        my @nebenkorpa   = marc_map( $data, '710a' );
        my @nebenkorpb   = marc_map( $data, '710b', '-join', ', ' );
        my @nebenkorpgnd = marc_map( $data, '7101' );
        my @nebenkorprelator = marc_map( $data, '710e' );
        my @nebenkonga       = marc_map( $data, '711a' );
        my @nebenkonge       = marc_map( $data, '711e', '-join', ', ' );
        my @nebenkonggnd     = marc_map( $data, '7111' );
        my @nebenkongrelator = marc_map( $data, '711j' );

        if ( marc_map( $data, '100' ) ne "" ) {
            unshift @nebenpera,       marc_map( $data, '100a' );
            unshift @nebenperq,       marc_map( $data, '100q' );
            unshift @nebenperb,       marc_map( $data, '100b' );
            unshift @nebenperc,       marc_map( $data, '100c', '-join', ', ' );
            unshift @nebenperd,       marc_map( $data, '100d' );
            unshift @nebenpert,       undef;
            unshift @nebenpern,       undef;
            unshift @nebenperp,       undef;
            unshift @nebenperm,       undef;
            unshift @nebenperr,       undef;
            unshift @nebenpers,       undef;
            unshift @nebenpero,       undef;
            unshift @nebenperh,       undef;
            unshift @nebenperrelator, marc_map( $data, '100e' );
            unshift @nebenpergnd,     marc_map( $data, '1001' );
        }

        for (@nebenpergnd) { s/\(DE-588\)//g }
        if ( marc_map( $data, '110' ) ne "" ) {
            unshift @nebenkorpa,       marc_map( $data, '110a' );
            unshift @nebenkorpb,       marc_map( $data, '110b', '-join', ', ' );
            unshift @nebenkorpgnd,     marc_map( $data, '1101' );
            unshift @nebenkorprelator, marc_map( $data, '110e' );
        }

        for (@nebenkorpgnd) { s/\(DE-588\)//g }
        if ( marc_map( $data, '111' ) ne "" ) {
            unshift @nebenkonga,       marc_map( $data, '111a' );
            unshift @nebenkonge,       marc_map( $data, '111e', '-join', ', ' );
            unshift @nebenkonggnd,     marc_map( $data, '1111' );
            unshift @nebenkongrelator, marc_map( $data, '111j' );
        }

        for (@nebenkonggnd) { s/\(DE-588\)//g }
        my @originationa   = marc_map( $data, '751a' );
        my @originationgnd = marc_map( $data, '7511' );
        for (@originationgnd) { s/\(DE-588\)//g }
        my $institution     = marc_map( $data, '852' );
        my @institutionname = marc_map( $data, '852[  ]a' );
        my @signature       = marc_map( $data, '852[  ]p' );
        my @signaturealt    = marc_map( $data, '852[A ]p' );
        my @signatureold    = marc_map( $data, '852[E ]p' );
        my @hyperlink       = marc_map( $data, '856u' );
        my @hyperlinknote   = marc_map( $data, '856z' );
        my $link            = marc_map( $data, '490w' );
        my $alink           = marc_map( $data, '773w' );
        my $fixedfields     = marc_map( $data, '008' );
        my $language008 = substr( $fixedfields, 35, 3 );
        my $date0081    = substr( $fixedfields, 7,  4 );
        my $date0082    = substr( $fixedfields, 11, 4 );
        my $language041 = marc_map( $data, '041a' );
        my $hide        = marc_map( $data, '909f' );
        my @catdate     = marc_map( $data, 'CATc' );

        isbd( $title, $titleb, " : " );
        isbd( $title, $titled, " = " );
        isbd( $title, $titlec, " / " );
        isbd( $title, $titlei, " ; " );
        isbd( $title, $titlej, ". " );
        isbd( $title, $titlen, ". " );
        isbd( $title, $titlep, ". " );

        for my $i ( 0 .. (@alttitlea) - 1 ) {
            if ( !( hasvalue( $alttitleintro[$i] ) ) ) {
                $alttitleintro[$i] = "Weiterer Titel";
            }
        }

        my @alttitle;
        my $alttitle_max = maxarray( \@alttitlea, \@alttitlen, \@alttitlep );
        for my $i ( 0 .. ($alttitle_max) - 1 ) {
            isbd( $alttitle[$i], $alttitlea[$i] );
            isbd( $alttitle[$i], $alttitlen[$i], ". " );
            isbd( $alttitle[$i], $alttitlep[$i], ". " );
            $alttitle[$i] =~ s/^.\s//;
        }

        my $size = $sizea;
        isbd( $size, $sizee, " + " );

        my @restrict;
        my $restrict_max = maxarray( \@restricta, \@restrictc );
        for my $i ( 0 .. ($restrict_max) - 1 ) {
            isbd( $restrict[$i], $restricta[$i] );
            isbd( $restrict[$i], $restrictc[$i], ". " );
            $restrict[$i] =~ s/^,\s//;
        }

        my @bibliography;
        my $bibliography_max = maxarray( \@bibliographya, \@bibliographyi );
        for my $i ( 0 .. ($bibliography_max) - 1 ) {
            isbd( $bibliography[$i], $bibliographyi[$i], ": " );
            isbd( $bibliography[$i], $bibliographya[$i] );
        }

        my @content;
        my $content_max = maxarray(
            \@contenta, \@contentn, \@contentg, \@contentt,
            \@contentr, \@contenti, \@contents, \@contentv
        );
        for my $i ( 0 .. ($content_max) - 1 ) {
            if ( hasvalue( $contenta[$i] ) ) { $content[$i] = $contenta[$i] }
            else {
                isbd( $content[$i], $contentn[$i] );
                isbd( $content[$i], $contentg[$i], ". (", ")" );
                isbd( $content[$i], $contentt[$i], " " );
                isbd( $content[$i], $contentr[$i], " / " );
                isbd( $content[$i], $contenti[$i], ". " );
                isbd( $content[$i], $contents[$i], " " );
                isbd( $content[$i], $contentv[$i], " - " );
            }
            $content[$i] =~ s/^,\s//;
        }

        my @contentform;
        my $contentform_max =
          maxarray( \@contentforma, \@contentformb, \@contentform3 );
        for my $i ( 0 .. ($contentform_max) - 1 ) {
            isbd( $contentform[$i], $contentform3[$i], "", ": " );
            isbd( $contentform[$i], $contentforma[$i] );
            isbd( $contentform[$i], $contentformb[$i], ". " );
            $contentform[$i] =~ s/^,\s//;
        }

        my @acqinfo;
        my $acqinfo_max = maxarray(
            \@acqinfo3, \@acqinfoc, \@acqinfoa,
            \@acqinfod, \@acqinfoe, \@acqinfof
        );
        for my $i ( 0 .. ($acqinfo_max) - 1 ) {
            isbd( $acqinfo[$i], $acqinfo3[$i], "",           ": " );
            isbd( $acqinfo[$i], $acqinfoc[$i], "",           ". " );
            isbd( $acqinfo[$i], $acqinfoa[$i], "Herkunft: ", ". " );
            isbd( $acqinfo[$i], $acqinfod[$i], "Datum: ",    ". " );
            isbd( $acqinfo[$i], $acqinfoe[$i], "Akz.-Nr.: ", ". " );
            isbd( $acqinfo[$i], $acqinfof[$i], "Eigentümer: " );
        }

        my @literatur;
        my $literatur_max =
          maxarray( \@literaturi, \@literatura, \@literatur3 );
        for my $i ( 0 .. ($literatur_max) - 1 ) {
            isbd( $literatur[$i], $literaturi[$i], "",         ": " );
            isbd( $literatur[$i], $literatura[$i] );
            isbd( $literatur[$i], $literatur3[$i], " (betr. ", ")" );
            $literatur[$i] =~ s/^,\s//;
        }

        my @bioghist;
        my $bioghist_max = maxarray( \@bioghista, \@bioghistb );
        for my $i ( 0 .. ($bioghist_max) - 1 ) {
            $bioghist[$i] = $bioghista[$i];
            isbd( $bioghist[$i], $bioghistb[$i], ". " );
        }

        my @datenormbhuman;
        for (@datenormb) {
            s/\.//g;
            s/\[//g;
            s/\]//g;
            s/ //g;
            push @datenormbhuman, $_;
        }

        my @datenormchuman;
        for (@datenormc) {
            s/\.//g;
            s/\[//g;
            s/\]//g;
            s/ //g;
            push @datenormchuman, $_;
        }

        my @datenormdhuman;
        for (@datenormd) {
            s/\.//g;
            s/\[//g;
            s/\]//g;
            s/ //g;
            push @datenormdhuman, $_;
        }

        my @datenormehuman;
        for (@datenorme) {
            s/\.//g;
            s/\[//g;
            s/\]//g;
            s/ //g;
            push @datenormehuman, $_;
        }

        my $datenorm_max =
          maxarray( \@datenorma, \@datenormb, \@datenormc, \@datenormd,
            \@datenorme );

        my @datenormhuman;
        my @datenorm;

        for my $i ( 0 .. ($datenorm_max) - 1 ) {
            if ( length( $datenormb[$i] ) == 6 ) {
                $datenormbhuman[$i] = "v"
                  . substr( $datenormbhuman[$i], 4, 2 ) . "."
                  . substr( $datenormbhuman[$i], 0, 4 );
                $datenormb[$i] = "-"
                  . substr( $datenormb[$i], 0, 4 ) . "-"
                  . substr( $datenormb[$i], 4, 2 );
            }
            elsif ( length( $datenormb[$i] ) == 8 ) {
                $datenormbhuman[$i] = "v"
                  . substr( $datenormbhuman[$i], 6, 2 ) . "."
                  . substr( $datenormbhuman[$i], 4, 2 ) . "."
                  . substr( $datenormbhuman[$i], 0, 4 );
                $datenormb[$i] = "-" . $datenormb[$i];
            }
            elsif ( $datenormb[$i] ) {
                $datenormbhuman[$i] = "v" . $datenormbhuman[$i];
                $datenormb[$i]      = "-" . $datenormb[$i];
            }

            if ( length( $datenormc[$i] ) == 6 ) {
                $datenormchuman[$i] = substr( $datenormchuman[$i], 4, 2 ) . "."
                  . substr( $datenormchuman[$i], 0, 4 );
                $datenormc[$i] = substr( $datenormc[$i], 0, 4 ) . "-"
                  . substr( $datenormc[$i], 4, 2 );
            }
            elsif ( length( $datenormc[$i] ) == 8 ) {
                $datenormchuman[$i] =
                    substr( $datenormchuman[$i], 6, 2 ) . "."
                  . substr( $datenormchuman[$i], 4, 2 ) . "."
                  . substr( $datenormchuman[$i], 0, 4 );
            }

            if ( length( $datenormd[$i] ) == 6 ) {
                $datenormdhuman[$i] = "v"
                  . substr( $datenormdhuman[$i], 4, 2 ) . "."
                  . substr( $datenormdhuman[$i], 0, 4 );
                $datenormd[$i] = "-"
                  . substr( $datenormd[$i], 0, 4 ) . "-"
                  . substr( $datenormd[$i], 4, 2 );
            }
            elsif ( length( $datenormd[$i] ) == 8 ) {
                $datenormdhuman[$i] = "v"
                  . substr( $datenormdhuman[$i], 6, 2 ) . "."
                  . substr( $datenormdhuman[$i], 4, 2 ) . "."
                  . substr( $datenormdhuman[$i], 0, 4 );
                $datenormd[$i] = "-" . $datenormd[$i];
            }
            elsif ( $datenormd[$i] ) {
                $datenormdhuman[$i] = "v" . $datenormdhuman[$i];
                $datenormd[$i]      = "-" . $datenormd[$i];
            }

            if ( length( $datenorme[$i] ) == 6 ) {
                $datenormehuman[$i] = substr( $datenormehuman[$i], 4, 2 ) . "."
                  . substr( $datenormehuman[$i], 0, 4 );
                $datenorme[$i] = substr( $datenorme[$i], 0, 4 ) . "-"
                  . substr( $datenorme[$i], 4, 2 );
            }
            elsif ( length( $datenorme[$i] ) == 8 ) {
                $datenormehuman[$i] =
                    substr( $datenorme[$i], 6, 2 ) . "."
                  . substr( $datenormehuman[$i], 4, 2 ) . "."
                  . substr( $datenormehuman[$i], 0, 4 );
            }

            $datenormc[$i] = $datenormb[$i] unless $datenormc[$i];
            $datenorme[$i] = $datenormd[$i] unless $datenorme[$i];

            $datenormchuman[$i] = $datenormbhuman[$i]
              unless $datenormchuman[$i];
            $datenormehuman[$i] = $datenormdhuman[$i]
              unless $datenormehuman[$i];

            my $newdatenormhuman;

            $newdatenormhuman = $datenormchuman[$i] . "-" . $datenormehuman[$i]
              unless $datenormehuman[$i] eq "";

            push @datenormhuman, $newdatenormhuman;

            my $newdatenorm;

            $newdatenorm = $datenormc[$i] . "/" . $datenorme[$i]
              unless $datenorme[$i] eq "";

            if ( $newdatenorm =~
/^(-?(0|1|2)([0-9]{3})(((01|02|03|04|05|06|07|08|09|10|11|12)((0[1-9])|((1|2)[0-9])|(3[0-1])))|-((01|02|03|04|05|06|07|08|09|10|11|12)(\-((0[1-9])|((1|2)[0-9])|(3[0-1])))?))?)(\/-?(0|1|2)([0-9]{3})(((01|02|03|04|05|06|07|08|09|10|11|12)((0[1-9])|((1|2)[0-9])|(3[0-1])))|-((01|02|03|04|05|06|07|08|09|10|11|12)(-((0[1-9])|((1|2)[0-9])|(3[0-1])))?))?)?$/
              )
            {
                push @datenorm, $newdatenorm;
                print "OK:" . $newdatenorm . "\n";

            }
            else {
                print "NOK:" . $newdatenorm . "\n";
                push @datenorm, "";
            }
        }

        if ( $date0081 eq '----' ) {
            $date0081 = '';
        }

        if ( $date0082 eq '----' ) {
            $date0082 = '';
        }

        if ( $date0081 eq 'uuuu' ) {
            $date0081 = '';
        }

        if ( $date0082 eq 'uuuu' ) {
            $date0082 = '';
        }

        my $date008;
        my $date008human;
        if ( hasvalue($date0081) && hasvalue($date0082) ) {
            $date008      = $date0081 . "/" . $date0082;
            $date008human = $date0081 . "-" . $date0082;
        }
        else {
            $date008      = $date0081;
            $date008human = $date0081;
        }

        my @catdatehuman;
        for (@catdate) {
            push @catdatehuman,
              (
                    substr( $_, 6 ) . "."
                  . substr( $_, 4, 2 ) . "."
                  . substr( $_, 0, 4 ) );
        }
        my @controlper;
        my $controlper_max = maxarray(
            \@controlpera, \@controlperq, \@controlperb,
            \@controlperc, \@controlperd
        );
        for my $i ( 0 .. ($controlper_max) - 1 ) {
            $controlper[$i] = $controlpera[$i];
            isbd( $controlper[$i], $controlperq[$i], " (",  ")" );
            isbd( $controlper[$i], $controlperb[$i], " " );
            isbd( $controlper[$i], $controlperc[$i], ", " );
            isbd( $controlper[$i], $controlperd[$i], ", (", ")" );
        }

        my @controlkorp;
        my $controlkorp_max = maxarray( \@controlkorpa, \@controlkorpb );
        for my $i ( 0 .. ($controlkorp_max) - 1 ) {
            $controlkorp[$i] = $controlkorpa[$i];
            isbd( $controlkorp[$i], $controlkorpb[$i], ". " );
        }

        my @controlkong;
        my $controlkong_max = maxarray( \@controlkonga, \@controlkonge );
        for my $i ( 0 .. ($controlkong_max) - 1 ) {
            $controlkong[$i] = $controlkonga[$i];
            isbd( $controlkong[$i], $controlkonge[$i], ". " );
        }

        my @controlsub;
        my $controlsub_max = maxarray(
            \@controlsuba, \@controlsubv, \@controlsubx,
            \@controlsuby, \@controlsubz
        );
        for my $i ( 0 .. ($controlsub_max) - 1 ) {
            $controlsub[$i] = $controlsuba[$i];
            isbd( $controlsub[$i], $controlsubv[$i], " -- " );
            isbd( $controlsub[$i], $controlsubx[$i], " -- " );
            isbd( $controlsub[$i], $controlsuby[$i], " -- " );
            isbd( $controlsub[$i], $controlsubz[$i], " -- " );
        }

        my @controlgeo;
        my $controlgeo_max = maxarray(
            \@controlgeoa, \@controlgeov, \@controlgeox,
            \@controlgeoy, \@controlgeoz
        );
        for my $i ( 0 .. ($controlgeo_max) - 1 ) {
            $controlgeo[$i] = $controlgeoa[$i];
            isbd( $controlgeo[$i], $controlgeov[$i], " -- " );
            isbd( $controlgeo[$i], $controlgeox[$i], " -- " );
            isbd( $controlgeo[$i], $controlgeoy[$i], " -- " );
            isbd( $controlgeo[$i], $controlgeoz[$i], " -- " );
        }

        my @nebenper;
        my $nebenper_max = maxarray(
            \@nebenpera, \@nebenperq, \@nebenperb, \@nebenperc, \@nebenperd,
            \@nebenpert, \@nebenpern, \@nebenperp, \@nebenperm, \@nebenperr,
            \@nebenpers, \@nebenpero, \@nebenperh
        );
        for my $i ( 0 .. ($nebenper_max) - 1 ) {
            $nebenper[$i] = $nebenpera[$i];
            isbd( $nebenper[$i], $nebenperq[$i], " (", ")" );
            isbd( $nebenper[$i], $nebenperb[$i], " " );
            isbd( $nebenper[$i], $nebenperc[$i], ", " );
            isbd( $nebenper[$i], $nebenperd[$i], " (", ")" );
            isbd( $nebenper[$i], $nebenpert[$i], " -- " );
            isbd( $nebenper[$i], $nebenpern[$i], ". " );
            isbd( $nebenper[$i], $nebenperp[$i], ". " );
            isbd( $nebenper[$i], $nebenperm[$i], ". " );
            isbd( $nebenper[$i], $nebenperr[$i], ". " );
            isbd( $nebenper[$i], $nebenpers[$i], ". " );
            isbd( $nebenper[$i], $nebenpero[$i], ". " );
            isbd( $nebenper[$i], $nebenperh[$i], ". " );
        }

        my @nebenkorp;
        my $nebenkorp_max = maxarray( \@nebenkorpa, \@nebenkorpb );
        for my $i ( 0 .. ($nebenkorp_max) - 1 ) {
            $nebenkorp[$i] = $nebenkorpa[$i];
            isbd( $nebenkorp[$i], $nebenkorpb[$i], ". " );
        }

        my @nebenkong;
        my $nebenkong_max = maxarray( \@nebenkonga, \@nebenkonge );
        for my $i ( 0 .. ($nebenkong_max) - 1 ) {
            $nebenkong[$i] = $nebenkonga[$i];
            isbd( $nebenkong[$i], $nebenkonge[$i], ". " );
        }

        foreach (@hyperlinknote) {
            s/^.*Digitalisat.*$/Digitalisat/g;
        }

        my @langcodes;
        my @language041 = $language041 =~ m/(...)/g;
        shift @language041;

        push @langcodes, $language008 unless $language008 =~ /(zxx|und)/;

        my @languages;
        foreach my $lang (@langcodes) {
            foreach my $lang1 ( keys %language ) {
                if ( $lang1 eq $lang ) {
                    push @languages, $language{$lang1};
                }
            }
        }

        $link  = sprintf( "%-9.9d", $link );
        $alink = sprintf( "%-9.9d", $alink );
        $link = $alink unless $link;

        my $isilsysnum = ( 'CH-001880-7-' . $sysnum );
        my $isilnum;
        for my $isil ( keys %isil ) {
            if ( $institution =~ $isil ) {
                $isilnum = $isil{$isil};
            }
        }

        for my $relator ( keys %relator ) {
            foreach my $i ( 0 .. ( @nebenperrelator - 1 ) ) {
                if ( $nebenperrelator[$i] =~ $relator ) {
                    $nebenperrelator[$i] = $relator{$relator};
                }
            }
            foreach my $j ( 0 .. ( @nebenkorprelator - 1 ) ) {
                if ( $nebenperrelator[$j] =~ $relator ) {
                    $nebenperrelator[$j] = $relator{$relator};
                }
            }
            foreach my $k ( 0 .. ( @nebenkongrelator - 1 ) ) {
                if ( $nebenperrelator[$k] =~ $relator ) {
                    $nebenperrelator[$k] = $relator{$relator};
                }
            }
        }

        unless ( hasvalue($level) ) {
            $level = "Dossier=File";
        }

        unless ( hasvalue( $lvlarg{$level} ) ) {
            $level = "Dossier=File";
        }

        if ( $hide =~ /hide_this ead/ ) {
            $hide = "einzel";
        }

        unless (
               ( $hide =~ /hide_this/ )
            || ( $level =~ /Abteilung/ )
            || ( $level =~ /Hauptabteilung/ )
            || (   $hide =~ /collect_this.handschrift/
                && $institution =~ /UBHandschriften/ )
            || (   $hide =~ /collect_this.miszellan/
                && $institution =~ /UBHandschriften/ )
            || (   $hide =~ /collect_this.handschrift/
                && $institution =~ /Luzern.ZHB/ )
            || (   $hide =~ /collect_this.handschrift/
                && $institution =~ /Vadiana/ )
            || ( $institution =~ /REBUS/ )
          )
        {

            push( @sysnum, $sysnum );
            $title{$sysnum}            = ($title);
            $alttitle{$sysnum}         = [@alttitle];
            $alttitleintro{$sysnum}    = [@alttitleintro];
            $ausreifung{$sysnum}       = $ausreifung;
            $music{$sysnum}            = [@music];
            $date{$sysnum}             = $date;
            $size{$sysnum}             = $size;
            $dimension{$sysnum}        = $dimension;
            $carrier{$sysnum}          = [@carrier];
            $arrangement{$sysnum}      = $arrangement;
            $level{$sysnum}            = $level;
            $note{$sysnum}             = [@note];
            $noteA{$sysnum}            = [@noteA];
            $content{$sysnum}          = [@content];
            $contentform{$sysnum}      = [@contentform];
            $restrict{$sysnum}         = [@restrict];
            $bibliography{$sysnum}     = [@bibliography];
            $acqinfo{$sysnum}          = [@acqinfo];
            $relatedmat{$sysnum}       = [@relatedmat];
            $bioghist{$sysnum}         = [@bioghist];
            $link{$sysnum}             = $link;
            $institution{$sysnum}      = $institution;
            $institutionname{$sysnum}  = [@institutionname];
            $signature{$sysnum}        = [@signature];
            $signaturealt{$sysnum}     = [@signaturealt];
            $signatureold{$sysnum}     = [@signatureold];
            $isilsysnum{$sysnum}       = $isilsysnum;
            $isilnum{$sysnum}          = $isilnum;
            $languages{$sysnum}        = [@languages];
            $langcodes{$sysnum}        = [@langcodes];
            $findaid{$sysnum}          = [@findaid];
            $custodhist{$sysnum}       = [@custodhist];
            $einband{$sysnum}          = [@einband];
            $literatur{$sysnum}        = [@literatur];
            $datenorm{$sysnum}         = [@datenorm];
            $datenormhuman{$sysnum}    = [@datenormhuman];
            $date008{$sysnum}          = $date008;
            $date008human{$sysnum}     = $date008human;
            $controlper{$sysnum}       = [@controlper];
            $controlpernorm{$sysnum}   = [@controlpera];
            $controlpergnd{$sysnum}    = [@controlpergnd];
            $controlperfamily{$sysnum} = [@controlperc];
            $controlkong{$sysnum}      = [@controlkong];
            $controlkongnorm{$sysnum}  = [@controlkonga];
            $controlkonggnd{$sysnum}   = [@controlkonggnd];
            $controlkorp{$sysnum}      = [@controlkorp];
            $controlkorpnorm{$sysnum}  = [@controlkorpa];
            $controlkorpgnd{$sysnum}   = [@controlkorpgnd];
            $controlsub{$sysnum}       = [@controlsub];
            $controlsubnorm{$sysnum}   = [@controlsuba];
            $controlsubgnd{$sysnum}    = [@controlsubgnd];
            $controlgeo{$sysnum}       = [@controlgeo];
            $controlgeonorm{$sysnum}   = [@controlgeoa];
            $controlgeognd{$sysnum}    = [@controlgeognd];
            $controlgenre{$sysnum}     = [@controlgenre];
            $nebenper{$sysnum}         = [@nebenper];
            $nebenpernorm{$sysnum}     = [@nebenpera];
            $nebenpergnd{$sysnum}      = [@nebenpergnd];
            $nebenperrelator{$sysnum}  = [@nebenperrelator];
            $nebenkong{$sysnum}        = [@nebenkong];
            $nebenkongnorm{$sysnum}    = [@nebenkonga];
            $nebenkonggnd{$sysnum}     = [@nebenkonggnd];
            $nebenkongrelator{$sysnum} = [@nebenkongrelator];
            $nebenkorp{$sysnum}        = [@nebenkorp];
            $nebenkorpnorm{$sysnum}    = [@nebenkorpa];
            $nebenkorpgnd{$sysnum}     = [@nebenkorpgnd];
            $nebenkorprelator{$sysnum} = [@nebenkorprelator];
            $originationa{$sysnum}     = [@originationa];
            $originationgnd{$sysnum}   = [@originationgnd];
            $hyperlink{$sysnum}        = [@hyperlink];
            $hyperlinknote{$sysnum}    = [@hyperlinknote];
            $hide{$sysnum}             = $hide;
            $catdate{$sysnum}          = [@catdate];
            $catdatehuman{$sysnum}     = [@catdatehuman];
        }
    }
);

foreach (@sysnum) {
    if ( ( $level{$_} =~ /Bestand/ ) && !( $hide{$_} =~ /einzel/ ) ) {
        intro($_);
        ead($_);
        extro();
    }
}

foreach (@sysnum) {
    unless ( $sysnumcheck{$_} ) {
        if ( $institution{$_} =~ /Basel UBHandschriften/ ) {
            $link{$_} = '000297324' unless $_ == '000297324';
        }
        elsif ( $institution{$_} =~ /SWA/ ) {
            $link{$_} = '000297326' unless $_ == '000297326';
        }
        elsif ( $institution{$_} =~ /Gosteli/ ) {
            $link{$_} = '000297327' unless $_ == '000297327';
        }
        elsif ( $institution{$_} =~ /Rorschach/ ) {
            $link{$_} = '000297330' unless $_ == '000297330';
        }
        elsif ( $institution{$_} =~ /Ausserrhoden/ ) {
            $link{$_} = '000297407' unless $_ == '000297407';
        }
        elsif ( $institution{$_} =~ /Thurgau/ ) {
            $link{$_} = '000297408' unless $_ == '000297408';
        }
        elsif ( $institution{$_} =~ /Luzern/ ) {
            $link{$_} = '000297409' unless $_ == '000297409';
        }
        elsif ( $institution{$_} =~ /Solothurn/ ) {
            $link{$_} = '000297410' unless $_ == '000297410';
        }
        elsif ( $institution{$_} =~ /Vadiana/ ) {
            $link{$_} = '000297411' unless $_ == '000297411';
        }
        elsif ( $institution{$_} =~ /Stiftsbibliothek/ ) {
            $link{$_} = '000297412' unless $_ == '000297412';
        }
    }
}

foreach (@sysnum) {
    if ( $hide{$_} =~ /einzel/ ) {
        intro($_);
        ead($_);
        extro();
    }
}

#foreach (@sysnum) {
#    unless ($sysnumcheck{$_}) {
#      if ($institution{$_} =~ /Stiftsbibliothek/) {
#            $link{$_} = 0;
#	    print $_ . "\n";
#            ead($_);
#        }
#    }
#}

sub maxarray {
    my $max;
    foreach my $i ( 0 .. ( @_ - 1 ) ) {
        $max = scalar @{ $_[$i] } if scalar @{ $_[$i] } > $max;
    }
    return $max;
}

sub hasvalue {
    my $i = 1 if defined $_[0] && $_[0] ne "";
    return $i;
}

sub isbd {
    if ( hasvalue( $_[1] ) ) {
        $_[0] = $_[0] . $_[2] . $_[1] . $_[3];
    }
}

sub simpletag {
    if ( defined $_[0] ) {
        foreach my $i ( 0 .. ( @{ $_[0] } - 1 ) ) {
            $writer->startTag( $_[1], $_[2] => $_[3] );
            $writer->characters( $_[0][$i] );
            $writer->endTag( $_[1] );
        }
    }
}

sub simpletag_p {
    if ( @{ $_[0] } > 0 ) {
        $writer->startTag( $_[1] );
        $writer->startTag("head");
        $writer->characters( $_[2] );
        $writer->endTag("head");
        foreach my $i ( 0 .. ( @{ $_[0] } - 1 ) ) {
            $writer->startTag("p");
            $writer->characters( $_[0][$i] );
            $writer->endTag("p");
        }
        $writer->endTag( $_[1] );
    }
}

sub intro {
    my $sysnum = $_[0];

    $writer->xmlDecl("UTF-8");
    $writer->startTag("ead");

    $writer->startTag(
        "eadheader",
        "langencoding"       => "iso639-2b",
        "scriptencoding"     => "iso15924",
        "dateencoding"       => "iso8601",
        "countryencoding"    => "iso3166-1",
        "repositoryencoding" => "iso15511",
        "relatedencoding"    => "Marc21",
        "audience"           => "external"
    );
    $writer->startTag("eadid");
    $writer->endTag("eadid");

    $writer->startTag("filedesc");
    $writer->startTag("titlestmt");
    $writer->startTag("titleproper");

    $writer->characters( $title{$sysnum} );

    $writer->endTag("titleproper");
    $writer->endTag("titlestmt");
    $writer->endTag("filedesc");

    $writer->startTag("profiledesc");
    $writer->startTag("langusage");

    if ( $institution{$sysnum} =~ /Rorschach/ ) {
        $writer->startTag(
            "language",
            "scriptcode" => "Latn",
            "langcode"   => "eng"
        );
        $writer->characters("Englisch");
    }
    else {
        $writer->startTag(
            "language",
            "scriptcode" => "Latn",
            "langcode"   => "ger"
        );
        $writer->characters("Deutsch");
    }

    $writer->endTag("language");
    $writer->endTag("langusage");
    $writer->endTag("profiledesc");

    $writer->endTag("eadheader");

}

sub extro {
    $writer->endTag("ead");
    $writer->end();
}

sub ead {

    my $sysnum = $_[0];
    $sysnumcheck{$sysnum} = 1;

    $writer->startTag(
        $lvl{ $level{$sysnum} },
        "level" => $lvlarg{ $level{$sysnum} },
        "id"    => $isilsysnum{$sysnum}
    );
    $writer->startTag("did");

    simpletag( $signature{$sysnum},    "unitid" );
    simpletag( $signaturealt{$sysnum}, "unitid", "label", "Weitere Signatur" );
    simpletag( $signatureold{$sysnum}, "unitid", "label", "Frühere Signatur" );

    foreach my $i ( 0 .. ( @{ $hyperlink{$sysnum} } - 1 ) ) {
        $writer->startTag(
            "dao", [ $xlink, "href" ] => $hyperlink{$sysnum}[$i],
            [ $xlink, "title" ] => $hyperlinknote{$sysnum}[$i]
        );
        $writer->endTag("dao");
    }

    unless ( $hide{$sysnum} =~ /einzel/ ) {
        $writer->startTag(
            "dao", [ $xlink, "type" ] => "simple",
            [ $xlink, "show" ]    => "embed",
            [ $xlink, "actuate" ] => "onLoad",
            [ $xlink, "href" ] =>
'http://aleph.unibas.ch/F/?local_base=DSV05&con_lng=GER&func=find-b&find_code=SYS&request='
              . $sysnum,
            [ $xlink, "title" ] => "Katalogeintrag im Verbundkatalog HAN"
        );
        $writer->endTag("dao");
    }

    $writer->startTag("repository");
    $writer->startTag(
        "corpname",
        "role"           => "Bestandshaltende Einrichtung",
        "normal"         => $institutionname{$sysnum}[0],
        "authfilenumber" => $isilnum{$sysnum}
    );
    $writer->characters( $institutionname{$sysnum}[0] );
    $writer->endTag("corpname");
    $writer->endTag("repository");

    $writer->startTag("langmaterial");

    foreach my $i ( 0 .. ( @{ $langcodes{$sysnum} } - 1 ) ) {
        $writer->startTag( "language", "langcode" => $langcodes{$sysnum}[$i] );
        $writer->characters( $languages{$sysnum}[$i] );
        $writer->endTag("language");
    }

    $writer->endTag("langmaterial");

    foreach my $i ( 0 .. ( @{ $nebenper{$sysnum} } - 1 ) ) {
        if ( $nebenperrelator{$sysnum}[$i] eq 'Aktenbildner' ) {
            if ( $nebenpergnd{$sysnum}[$i] ne "" ) {
                $writer->startTag("origination");
                $writer->startTag(
                    "persname",
                    "normal"         => $nebenpernorm{$sysnum}[$i],
                    "role"           => "Bestandsbildner",
                    "source"         => "GND",
                    "authfilenumber" => "$nebenpergnd{$sysnum}[$i]"
                );
                $writer->characters( $nebenper{$sysnum}[$i] );
                $writer->endTag("persname");
                $writer->endTag("origination");
            }
            else {
                $writer->startTag("origination");
                $writer->startTag(
                    "persname",
                    "normal" => $nebenpernorm{$sysnum}[$i],
                    "role"   => "Bestandsbildner"
                );
                $writer->characters( $nebenper{$sysnum}[$i] );
                $writer->endTag("persname");
                $writer->endTag("origination");
            }
        }
    }

    foreach my $i ( 0 .. ( @{ $nebenkorp{$sysnum} } - 1 ) ) {
        if ( $nebenkorprelator{$sysnum}[$i] eq 'Aktenbildner' ) {
            if ( $nebenkorpgnd{$sysnum}[$i] ne "" ) {
                $writer->startTag("origination");
                $writer->startTag(
                    "corpname",
                    "normal"         => $nebenkorpnorm{$sysnum}[$i],
                    "role"           => "Bestandsbildner",
                    "source"         => "GND",
                    "authfilenumber" => "$nebenkorpgnd{$sysnum}[$i]"
                );
                $writer->characters( $nebenkorp{$sysnum}[$i] );
                $writer->endTag("corpname");
                $writer->endTag("origination");
            }
            else {
                $writer->startTag("origination");
                $writer->startTag(
                    "corpname",
                    "normal" => $nebenkorpnorm{$sysnum}[$i],
                    "role"   => "Bestandsbildner"
                );
                $writer->characters( $nebenkorp{$sysnum}[$i] );
                $writer->endTag("corpname");
                $writer->endTag("origination");
            }
        }
    }

    foreach my $i ( 0 .. ( @{ $nebenkong{$sysnum} } - 1 ) ) {
        if ( $nebenkongrelator{$sysnum}[$i] eq 'Aktenbildner' ) {
            if ( $nebenkonggnd{$sysnum}[$i] ne "" ) {
                $writer->startTag("origination");
                $writer->startTag(
                    "corpname",
                    "normal"         => $nebenkongnorm{$sysnum}[$i],
                    "role"           => "Bestandsbildner",
                    "source"         => "GND",
                    "authfilenumber" => "$nebenkonggnd{$sysnum}[$i]"
                );
                $writer->characters( $nebenkong{$sysnum}[$i] );
                $writer->endTag("corpname");
                $writer->endTag("origination");
            }
            else {
                $writer->startTag("origination");
                $writer->startTag(
                    "corpname",
                    "normal" => $nebenkongnorm{$sysnum}[$i],
                    "role"   => "Bestandsbildner"
                );
                $writer->characters( $nebenkong{$sysnum}[$i] );
                $writer->endTag("corpname");
                $writer->endTag("origination");
            }
        }
    }

    if ( hasvalue( $title{$sysnum} ) ) {
        $writer->startTag("unittitle");
        $writer->characters( $title{$sysnum} );
        $writer->endTag("unittitle");

        foreach my $i ( 0 .. ( @{ $alttitle{$sysnum} } - 1 ) ) {
            $writer->startTag( "unittitle",
                "label" => $alttitleintro{$sysnum}[$i] );
            $writer->startTag("title");
            $writer->characters( $alttitle{$sysnum}[$i] );
            $writer->endTag("title");
            $writer->endTag("unittitle");
        }
    }
    else {

        $writer->startTag( "unittitle", "label" => $alttitleintro{$sysnum}[0] );
        $writer->characters( $alttitle{$sysnum}[0] );
        $writer->endTag("unittitle");

        foreach my $i ( 1 .. ( @{ $alttitle{$sysnum} } - 1 ) ) {
            $writer->startTag( "unittitle",
                "label" => $alttitleintro{$sysnum}[$i] );
            $writer->startTag("title");
            $writer->characters( $alttitle{$sysnum}[$i] );
            $writer->endTag("title");
            $writer->endTag("unittitle");
        }
    }

    if ( hasvalue( $datenorm{$sysnum}[0] ) && @{ $datenorm{$sysnum} } == 1 ) {
        $writer->startTag( "unitdate", "normal" => $datenorm{$sysnum}[0] );
    }
    elsif ( hasvalue( $date008{$sysnum} ) ) {
        $writer->startTag( "unitdate", "normal" => $date008{$sysnum} );
    }
    else {
        $writer->startTag("unitdate");
    }

    if ( hasvalue( $date{$sysnum} ) ) {
        $writer->characters( $date{$sysnum} );
    }
    elsif ( hasvalue( $datenormhuman{$sysnum}[0] )
        && @{ $datenormhuman{$sysnum} } == 1 )
    {
        $writer->characters( $datenormhuman{$sysnum}[0] );
    }
    elsif ( hasvalue( $date008human{$sysnum} ) ) {
        $writer->characters( $date008human{$sysnum} );
    }

    $writer->endTag("unitdate");

    simpletag( $music{$sysnum}, "materialspec" );

    $writer->startTag("physdesc");

    if ( defined $ausreifung{$sysnum} ) {
        $writer->startTag( "physfacet", "label" => "Ausreifungsgrad" );
        $writer->characters( $ausreifung{$sysnum} );
        $writer->endTag("physfacet");
    }

    if ( defined $size{$sysnum} ) {
        $writer->startTag("extent");
        $writer->characters( $size{$sysnum} );
        $writer->endTag("extent");
    }

    if ( defined $dimension{$sysnum} ) {
        $writer->startTag("dimensions");
        $writer->characters( $dimension{$sysnum} );
        $writer->endTag("dimensions");
    }

    foreach my $i ( 0 .. ( @{ $carrier{$sysnum} } - 1 ) ) {
        if ( defined $carrier{$sysnum}[$i] ) {
            $writer->startTag( "physfacet", "label" => "Material" );
            $writer->characters( $carrier{$sysnum}[$i] );
            $writer->endTag("physfacet");
        }
    }

    foreach my $i ( 0 .. ( @{ $einband{$sysnum} } - 1 ) ) {
        if ( defined $einband{$sysnum}[$i] ) {
            $writer->startTag( "physfacet", "label" => "Einband" );
            $writer->characters( $einband{$sysnum}[$i] );
            $writer->endTag("physfacet");
        }
    }

    $writer->endTag("physdesc");

    foreach my $i ( 0 .. ( @{ $note{$sysnum} } - 1 ) ) {
        $writer->startTag(
            "note",
            "label"    => "Bemerkung",
            "audience" => "external"
        );
        $writer->startTag("p");
        $writer->characters( $note{$sysnum}[$i] );
        $writer->endTag("p");
        $writer->endTag("note");
    }

    simpletag( $noteA{$sysnum}, "abstract", "type", "Darin" );

    $writer->endTag("did");

    simpletag_p( $content{$sysnum},     "scopecontent", "Inhaltsangabe" );
    simpletag_p( $contentform{$sysnum}, "scopecontent", "Inhaltsangabe" );

    if ( hasvalue( $arrangement{$sysnum} ) ) {
        $writer->startTag("arrangement");
        $writer->startTag("head");
        $writer->characters("Ordnungszustand");
        $writer->endTag("head");
        $writer->startTag("p");
        $writer->characters( $arrangement{$sysnum} );
        $writer->endTag("p");
        $writer->endTag("arrangement");
    }

    simpletag_p( $restrict{$sysnum}, "userestrict", "Benutzungsbeschränkung" );

    if ( @{ $bibliography{$sysnum} } > 0 ) {

        $writer->startTag("bibliography");
        $writer->startTag("head");
        $writer->characters("Bibliographie");
        $writer->endTag("head");

        foreach my $i ( 0 .. ( @{ $bibliography{$sysnum} } - 1 ) ) {
            $writer->startTag("bibref");
            $writer->characters( $bibliography{$sysnum}[$i] );
            $writer->endTag("bibref");
        }
        $writer->endTag("bibliography");
    }

    if ( @{ $literatur{$sysnum} } > 0 ) {
        $writer->startTag("bibliography");
        $writer->startTag("head");
        $writer->characters("Literaturhinweise");
        $writer->endTag("head");

        foreach my $i ( 0 .. ( @{ $literatur{$sysnum} } - 1 ) ) {
            $writer->startTag("bibref");
            $writer->characters( $literatur{$sysnum}[$i] );
            $writer->endTag("bibref");
        }
        $writer->endTag("bibliography");
    }

    simpletag_p( $acqinfo{$sysnum}, "acqinfo", "Akzession" );

    if ( @{ $relatedmat{$sysnum} } > 0 ) {
        $writer->startTag("relatedmaterial");
        $writer->startTag("head");
        $writer->characters("Verwandte Verzeichnungseinheiten");
        $writer->endTag("head");
        foreach my $i ( 0 .. ( @{ $relatedmat{$sysnum} } - 1 ) ) {
            $writer->startTag("p");
            $writer->characters( $relatedmat{$sysnum}[$i] );
            $writer->endTag("p");
        }
        $writer->endTag("relatedmaterial");
    }

    simpletag_p( $bioghist{$sysnum},   "bioghist",     "Biographische Notiz" );
    simpletag_p( $findaid{$sysnum},    "otherfindaid", "Weitere Findmittel" );
    simpletag_p( $custodhist{$sysnum}, "custodhist",   "Angaben zur Herkunft" );

    if (
        ( @{ $controlper{$sysnum} } > 0 )
        || ( @{ $nebenper{$sysnum} } > 0
            && !( 'Aktenbildner' ~~ @{ $nebenperrelator{$sysnum} } ) )
      )
    {
        $writer->startTag("controlaccess");

        $writer->startTag("head");
        $writer->characters('Personen');
        $writer->endTag("head");

        foreach my $i ( 0 .. ( @{ $controlper{$sysnum} } - 1 ) ) {
            if ( $controlperfamily{$sysnum}[$i] =~ /Familie/ ) {
                if ( $controlpergnd{$sysnum}[$i] ne "" ) {
                    $writer->startTag(
                        "persname",
                        "role"           => "Erwähnte Familie",
                        "normal"         => $controlpernorm{$sysnum}[$i],
                        "source"         => "GND",
                        "authfilenumber" => "$controlpergnd{$sysnum}[$i]"
                    );
                    $writer->characters( $controlper{$sysnum}[$i] );
                    $writer->endTag("persname");
                }
                else {
                    $writer->startTag(
                        "persname",
                        "role"   => "Erwähnte Familie",
                        "normal" => $controlpernorm{$sysnum}[$i]
                    );
                    $writer->characters( $controlper{$sysnum}[$i] );
                    $writer->endTag("persname");
                }
            }
            else {
                if ( $controlpergnd{$sysnum}[$i] ne "" ) {
                    $writer->startTag(
                        "persname",
                        "role"           => "Erwähnte Person",
                        "normal"         => $controlpernorm{$sysnum}[$i],
                        "source"         => "GND",
                        "authfilenumber" => "$controlpergnd{$sysnum}[$i]"
                    );
                    $writer->characters( $controlper{$sysnum}[$i] );
                    $writer->endTag("persname");
                }
                else {
                    $writer->startTag(
                        "persname",
                        "role"   => "Erwähnte Person",
                        "normal" => $controlpernorm{$sysnum}[$i]
                    );
                    $writer->characters( $controlper{$sysnum}[$i] );
                    $writer->endTag("persname");
                }
            }
        }

        foreach my $i ( 0 .. ( @{ $nebenper{$sysnum} } - 1 ) ) {
            unless ( $nebenperrelator{$sysnum}[$i] eq 'Aktenbildner' ) {
                if ( $nebenpergnd{$sysnum}[$i] ne "" ) {
                    $writer->startTag(
                        "persname",
                        "normal"         => $nebenpernorm{$sysnum}[$i],
                        "source"         => "GND",
                        "authfilenumber" => "$nebenpergnd{$sysnum}[$i]",
                        "role"           => $nebenperrelator{$sysnum}[$i]
                    );
                    $writer->characters( $nebenper{$sysnum}[$i] );
                    $writer->endTag("persname");
                }
                else {
                    $writer->startTag(
                        "persname",
                        "normal" => $nebenpernorm{$sysnum}[$i],
                        "role"   => $nebenperrelator{$sysnum}[$i]
                    );
                    $writer->characters( $nebenper{$sysnum}[$i] );
                    $writer->endTag("persname");
                }
            }
        }

        $writer->endTag("controlaccess");
    }

    if (
           ( @{ $controlkorp{$sysnum} } > 0 )
        || ( @{ $controlkong{$sysnum} } > 0 )
        || ( @{ $nebenkorp{$sysnum} } > 0
            && !( 'Aktenbildner' ~~ @{ $nebenkorprelator{$sysnum} } ) )
        || ( @{ $nebenkong{$sysnum} } > 0
            && !( 'Aktenbildner' ~~ @{ $nebenkongrelator{$sysnum} } ) )
      )
    {
        $writer->startTag("controlaccess");

        $writer->startTag("head");
        $writer->characters('Körperschaften');
        $writer->endTag("head");

        foreach my $i ( 0 .. ( @{ $controlkorp{$sysnum} } - 1 ) ) {
            if ( $controlkorpgnd{$sysnum}[$i] ne "" ) {
                $writer->startTag(
                    "corpname",
                    "role"           => "Erwähnte Körperschaft",
                    "normal"         => $controlkorpnorm{$sysnum}[$i],
                    "source"         => "GND",
                    "authfilenumber" => "$controlkorpgnd{$sysnum}[$i]"
                );
                $writer->characters( $controlkorp{$sysnum}[$i] );
                $writer->endTag("corpname");
            }
            else {
                $writer->startTag(
                    "corpname",
                    "role"   => "Erwähnte Körperschaft",
                    "normal" => $controlkorpnorm{$sysnum}[$i]
                );
                $writer->characters( $controlkorp{$sysnum}[$i] );
                $writer->endTag("corpname");
            }
        }

        foreach my $i ( 0 .. ( @{ $nebenkorp{$sysnum} } - 1 ) ) {
            unless ( $nebenkorprelator{$sysnum}[$i] eq 'Aktenbildner' ) {
                if ( $nebenkorpgnd{$sysnum}[$i] ne "" ) {
                    $writer->startTag(
                        "corpname",
                        "normal"         => $nebenkorpnorm{$sysnum}[$i],
                        "source"         => "GND",
                        "authfilenumber" => "$nebenkorpgnd{$sysnum}[$i]",
                        "role"           => $nebenkorprelator{$sysnum}[$i]
                    );
                    $writer->characters( $nebenkorp{$sysnum}[$i] );
                    $writer->endTag("corpname");
                }
                else {
                    $writer->startTag(
                        "corpname",
                        "normal" => $nebenkorpnorm{$sysnum}[$i],
                        "role"   => $nebenkorprelator{$sysnum}[$i]
                    );
                    $writer->characters( $nebenkorp{$sysnum}[$i] );
                    $writer->endTag("corpname");
                }
            }
        }

        foreach my $i ( 0 .. ( @{ $controlkong{$sysnum} } - 1 ) ) {
            if ( $controlkonggnd{$sysnum}[$i] ne "" ) {
                $writer->startTag(
                    "corpname",
                    "role"           => "Erwähnte Körperschaft",
                    "normal"         => $controlkongnorm{$sysnum}[$i],
                    "source"         => "GND",
                    "authfilenumber" => "$controlkonggnd{$sysnum}[$i]"
                );
                $writer->characters( $controlkong{$sysnum}[$i] );
                $writer->endTag("corpname");
            }
            else {
                $writer->startTag(
                    "corpname",
                    "role"   => "Erwähnte Körperschaft",
                    "normal" => $controlkongnorm{$sysnum}[$i]
                );
                $writer->characters( $controlkong{$sysnum}[$i] );
                $writer->endTag("corpname");
            }
        }

        foreach my $i ( 0 .. ( @{ $nebenkong{$sysnum} } - 1 ) ) {
            unless ( $nebenkongrelator{$sysnum}[$i] eq 'Aktenbildner' ) {
                if ( $nebenkonggnd{$sysnum}[$i] ne "" ) {
                    $writer->startTag(
                        "corpname",
                        "normal"         => $nebenkongnorm{$sysnum}[$i],
                        "source"         => "GND",
                        "authfilenumber" => "$nebenkonggnd{$sysnum}[$i]",
                        "role"           => $nebenkongrelator{$sysnum}[$i]
                    );
                    $writer->characters( $nebenkong{$sysnum}[$i] );
                    $writer->endTag("corpname");
                }
                else {
                    $writer->startTag(
                        "corpname",
                        "normal" => $nebenkongnorm{$sysnum}[$i],
                        "role"   => $nebenkongrelator{$sysnum}[$i]
                    );
                    $writer->characters( $nebenkong{$sysnum}[$i] );
                    $writer->endTag("corpname");
                }
            }
        }

        $writer->endTag("controlaccess");

    }

    unless ( @{ $controlsub{$sysnum} } == 0 ) {
        $writer->startTag("controlaccess");

        $writer->startTag("head");
        $writer->characters('Sachschlagwörter');
        $writer->endTag("head");

        foreach my $i ( 0 .. ( @{ $controlsub{$sysnum} } - 1 ) ) {
            if ( defined $controlsubgnd{$sysnum}[$i] ) {
                $writer->startTag(
                    "subject",
                    "normal"         => $controlsubnorm{$sysnum}[$i],
                    "source"         => "GND",
                    "authfilenumber" => "$controlsubgnd{$sysnum}[$i]"
                );
                $writer->characters( $controlsub{$sysnum}[$i] );
                $writer->endTag("subject");
            }
            else {
                $writer->startTag( "subject",
                    "normal" => $controlsubnorm{$sysnum}[$i] );
                $writer->characters( $controlsub{$sysnum}[$i] );
                $writer->endTag("subject");
            }
        }

        $writer->endTag("controlaccess");

    }

    unless ( ( @{ $controlgeo{$sysnum} } == 0 )
        && ( @{ $originationa{$sysnum} } == 0 ) )
    {
        $writer->startTag("controlaccess");

        $writer->startTag("head");
        $writer->characters('Orte');
        $writer->endTag("head");

        foreach my $i ( 0 .. ( @{ $controlgeo{$sysnum} } - 1 ) ) {
            if ( $controlgeognd{$sysnum}[$i] ne "" ) {
                $writer->startTag(
                    "geogname",
                    "role"           => "Erwähnter Ort",
                    "normal"         => $controlgeonorm{$sysnum}[$i],
                    "source"         => "GND",
                    "authfilenumber" => "$controlgeognd{$sysnum}[$i]"
                );
                $writer->characters( $controlgeo{$sysnum}[$i] );
                $writer->endTag("geogname");
            }
            else {
                $writer->startTag(
                    "geogname",
                    "role"   => "Erwähnter Ort",
                    "normal" => $controlgeonorm{$sysnum}[$i]
                );
                $writer->characters( $controlgeo{$sysnum}[$i] );
                $writer->endTag("geogname");
            }
        }

        foreach my $i ( 0 .. ( @{ $originationa{$sysnum} } - 1 ) ) {
            if ( $originationgnd{$sysnum}[$i] ne "" ) {
                $writer->startTag(
                    "geogname",
                    "role"           => "Entstehungsort",
                    "normal"         => $originationa{$sysnum}[$i],
                    "source"         => "GND",
                    "authfilenumber" => "$originationgnd{$sysnum}[$i]"
                );
                $writer->characters( $originationa{$sysnum}[$i] );
                $writer->endTag("geogname");
            }
            else {
                $writer->startTag(
                    "geogname",
                    "role"   => "Entstehungsort",
                    "normal" => $originationa{$sysnum}[$i]
                );
                $writer->characters( $originationa{$sysnum}[$i] );
                $writer->endTag("geogname");
            }
        }
        $writer->endTag("controlaccess");
    }

    unless ( @{ $controlgenre{$sysnum} } == 0 ) {
        $writer->startTag("controlaccess");

        $writer->startTag("head");
        $writer->characters('Gattungen');
        $writer->endTag("head");

        simpletag( $controlgenre{$sysnum}, "genreform" );

        $writer->endTag("controlaccess");
    }

    $writer->startTag("odd");
    $writer->startTag("head");
    $writer->characters("Steuerfelder");
    $writer->endTag("head");

    $writer->startTag("list");
    $writer->startTag("item");

    if ( hasvalue( $catdate{$sysnum}[0] ) ) {
        $writer->startTag(
            "date",
            "type"   => "Erfassungsdatum",
            "normal" => $catdate{$sysnum}[0]
        );
        $writer->characters( $catdatehuman{$sysnum}[0] );
        $writer->endTag("date");
    }

    if ( hasvalue( $catdate{$sysnum}[-1] ) ) {
        $writer->startTag(
            "date",
            "type"   => "Modifikationsdatum",
            "normal" => $catdate{$sysnum}[-1]
        );
        $writer->characters( $catdatehuman{$sysnum}[-1] );
        $writer->endTag("date");
    }

    $writer->startTag(
        "date",
        "type"   => "Synchronisationsdatum",
        "normal" => $syncdate
    );
    $writer->characters($syncdatehuman);
    $writer->endTag("date");

    $writer->endTag("item");
    $writer->endTag("list");

    $writer->endTag("odd");

    if ( $lvl{ $level{$sysnum} } eq "archdesc" ) {
        $writer->startTag("dsc");
    }

    #print $level{$sysnum} . "\n";

    addchildren($sysnum);

    if ( $lvl{ $level{$sysnum} } eq "archdesc" ) {
        $writer->endTag("dsc");
    }

    $writer->endTag( $lvl{ $level{$sysnum} } );

}

sub addchildren {
    for my $child ( keys %link ) {
        if ( $link{$child} == $_[0] ) {
            ead($child);
        }
    }
}

sub marc_map {
    my ( $data, $marc_path, %opts ) = @_;

    return unless exists $data->{'record'};

    my $record = $data->{'record'};

    unless ( defined $record && ref $record eq 'ARRAY' ) {
        return wantarray ? () : undef;
    }

    my $split     = $opts{'-split'};
    my $join_char = $opts{'-join'} // '';
    my $pluck     = $opts{'-pluck'};
    my $attrs     = {};

    if ( $marc_path =~
        /(\S{3})(\[(.)?,?(.)?\])?([_a-z0-9^]+)?(\/(\d+)(-(\d+))?)?/ )
    {
        $attrs->{field}          = $1;
        $attrs->{ind1}           = $3;
        $attrs->{ind2}           = $4;
        $attrs->{subfield_regex} = defined $5 ? "[$5]" : "[a-z0-9_]";
        $attrs->{from}           = $7;
        $attrs->{to}             = $9;
    }
    else {
        return wantarray ? () : undef;
    }

    $attrs->{field_regex} = $attrs->{field};
    $attrs->{field_regex} =~ s/\*/./g;

    my $add_subfields = sub {
        my $var   = shift;
        my $start = shift;

        my @v = ();

        if ($pluck) {

            # Treat the subfield_regex as a hash index
            my $_h = {};
            for ( my $i = $start ; $i < @$var ; $i += 2 ) {
                push @{ $_h->{ $var->[$i] } }, $var->[ $i + 1 ];
            }
            for my $c ( split( '', $attrs->{subfield_regex} ) ) {
                push @v, @{ $_h->{$c} } if exists $_h->{$c};
            }
        }
        else {
            my $found = "false";
            for ( my $i = $start ; $i < @$var ; $i += 2 ) {
                if ( $var->[$i] =~ /$attrs->{subfield_regex}/ ) {
                    push( @v, $var->[ $i + 1 ] );
                    $found = "true";
                }
            }
            if ( $found eq "false" ) {
                push( @v, "" );
            }
        }

        return \@v;
    };

    my @vals = ();

    for my $var (@$record) {
        next if $var->[0] !~ /$attrs->{field_regex}/;
        next if defined $attrs->{ind1} && $var->[1] ne $attrs->{ind1};
        next if defined $attrs->{ind2} && $var->[2] ne $attrs->{ind2};

        my $v;

        if ( $var->[0] =~ /LDR|00./ ) {
            $v = $add_subfields->( $var, 3 );
        }
        elsif ( defined $var->[5] && $var->[5] eq '_' ) {
            $v = $add_subfields->( $var, 5 );
        }
        else {
            $v = $add_subfields->( $var, 3 );
        }

        if (@$v) {
            if ( !$split ) {
                $v = join $join_char, @$v;

                if ( defined( my $off = $attrs->{from} ) ) {
                    my $len =
                      defined $attrs->{to} ? $attrs->{to} - $off + 1 : 1;
                    $v = substr( $v, $off, $len );
                }
            }
        }

        push( @vals, $v
          )   #if ( (ref $v eq 'ARRAY' && @$v) || (ref $v eq '' && length $v ));
    }

    if (wantarray) {
        return @vals;
    }
    elsif ( @vals > 0 ) {
        return join $join_char, @vals;
    }
    else {
        return undef;
    }
}

#print Dumper @sysnum;
#print Dumper \@sysnum;
#print Dumper (\%level);

exit;
