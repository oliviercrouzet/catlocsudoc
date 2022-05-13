package Koha::Plugin::PifPafPlug::CatLocSudoc;

## It's good practice to use Modern::Perl
use Modern::Perl;

## Required for all plugins
use base qw(Koha::Plugins::Base);

## We will also need to include any Koha libraries we want to access
use C4::Auth;
use C4::Context;
use Koha::DateUtils;
use utf8;


use Cwd qw(abs_path);
use Data::Dumper;

## Here we set our plugin version
our $VERSION = "1.0";
our $MINIMUM_VERSION = "19.11.00";

## Here is our metadata, some keys are required, some are optional
our $metadata = {
    name   => 'CatLocSudoc',
    author => 'Olivier Crouzet',
    date_authored   => '2022-02-07',
    date_updated    => '2022-02-07',
    minimum_version => $MINIMUM_VERSION,
    maximum_version => undef,
    version         => $VERSION,
    description => "Ce plugin permet de signaler si l'ouvrage en cours de réception doit être localisé dans le Sudoc ou catalogué",
};

## This is the minimum code required for a plugin's 'new' method
## More can be added, but none should be removed
sub new {
    my ( $class, $args ) = @_;

    ## We need to add our metadata here so our base class can access it
    $args->{'metadata'} = $metadata;
    $args->{'metadata'}->{'class'} = $class;

    ## Here, we call the 'new' method for our base class
    ## This runs some additional magic and checking
    ## and returns our actual $self
    my $self = $class->SUPER::new($args);

    return $self;
}

## If your tool is complicated enough to needs it's own setting/configuration
## you will want to add a 'configure' method to your plugin like so.
## Here I am throwing all the logic into the 'configure' method, but it could
## be split up like the 'report' method is.
sub configure {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    unless ( $cgi->param('save') ) {
        my $template = $self->get_template({ file => 'configure.tt' });

        ## Grab the values we already have for our settings, if any exist
        $template->param(
            shortname => $self->retrieve_data('shortname'),
            rcr             => $self->retrieve_data('rcr'),
        );

        $self->output_html( $template->output() );
    }
    else {
        $self->store_data(
            {
                shortname => $cgi->param('shortname'),
                rcr                => $cgi->param('rcr'),
            }
        );
        $self->go_home();
    }
}

## If your plugin needs to add some javascript in the staff intranet, you'll want
## to return that javascript here. Don't forget to wrap your javascript in
## <script> tags. By not adding them automatically for you, you'll have a
## chance to include other javascript files if necessary.
sub intranet_js {
    my ( $self ) = @_;
    my $shortname = $self->retrieve_data("shortname"); 
    my $rcr = $self->retrieve_data("rcr"); 
    my $key; my $searched;
    if ($rcr) {
        $rcr =~ s/\s+//g;
        $key = 'rcr'; $searched = $rcr;
    } else {
        $shortname=s/^\s+|\s+$//g;
        $key = 'shortname'; $searched = $shortname;
    }    
    return qq{
        <script>
if ( \$('#acq_orderreceive').length ) {
  var isbn = \$('#acq_orderreceive .rows li:eq(3)').contents().eq(2).text().split('|')[0];
  isbn=isbn.replace(/\\s/g,'');
  if (isbn) {
    var biblionumber= \$('input[name=biblionumber]').val();
    var noconnexion = 'AAAAARghhh, problème de connexion avec le Sudoc suspecté \\nPrévenez un administrateur Koha';
    var dialog = '<div class=\"dialog alert\" style=\"float:left;margin-left:50px;padding:15px 15px;width:auto\"><h4>Situation SUDOC</h4><p>';
    //y a-t-il un ppn correspondant à cet isbn ?
    \$.ajax({
        url: 'https://www.sudoc.fr/services/isbn2ppn/'+isbn,
        type: 'GET',
        dataType: "json",
        success: function(data){ 
            var ppn = data.sudoc.query.result.ppn;
            \$.ajax({
                url: 'https://www.sudoc.fr/services/multiwhere/'+ ppn,
                type: 'GET',
                success: function(data){
                    var localiser = 1;
                    \$(data).find('$key').each(function(){
                        if ( \$(this).text().match(/$searched/i) ) {
                            localiser = 0;
                            return false;
                        }
                    });
                    if ( localiser ) {
                         \$('#header_search').after(dialog+\'<span style=\"color:red\">Document à localiser :</span><br /><input id=\"ref\" readonly=\"readonly\" onclick=\"this.select();\" value=\' + ppn + \'#-#\' + biblionumber + \' /></p></div>\');
                         \$('#ref').select();
                    }
                },
                error: function(data) {
                    alert(noconnexion+' (API multiwhere)');
                }
            });                
        },
        error: function(data) {
	    if (data.statusText == "Not Found") {
            \$('#header_search').after(dialog+\'<span style=\"color:#cb0a0a\">Aucune notice associée à cet isbn (\'+isbn+\')<br> => Ouvrage à cataloguer</span></p></div>\');
            } else {
               alert(noconnexion+' (API isbn2ppn)');
            }
        }
    });
  } else {
    alert(\"Pas d\'isbn trouvé : le contrôle automatique sur le Sudoc est donc impossible\\nMerci de vérifier à partir de WiniBW\");
  }
}

</script>
    };
}

## This is the 'install' method. Any database tables or other setup that should
## be done when the plugin if first installed should be executed in this method.
## The installation method should always return true if the installation succeeded
## or false if it failed.
sub install() {
    my ( $self, $args ) = @_;

}

## This is the 'upgrade' method. It will be triggered when a newer version of a
## plugin is installed over an existing older version of a plugin
sub upgrade {
    my ( $self, $args ) = @_;

    my $dt = dt_from_string();
    $self->store_data( { last_upgraded => $dt->ymd('-') . ' ' . $dt->hms(':') } );

    return 1;
}

## This method will be run just before the plugin files are deleted
## when a plugin is uninstalled. It is good practice to clean up
## after ourselves!
sub uninstall() {
    my ( $self, $args ) = @_;

}

1;

