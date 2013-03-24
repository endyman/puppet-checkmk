# = Class: checkmk::server
#
# == Description:
#
# * This class manage a 'check_mk' server. It collects nodes' exported
#   resources and creates a config file for each one of them into a
#   specific directory.
# * When a new file is created, it triggers a refresh of the service to
#   acknowledge the new host and show him in the UI.
#
# == Parameters:
#
# [*nagios_server*]
#   This class uses the '$nagios_server' variable to determine where
#   resources should be collected (i.e.: '$nagios_server' must be the
#   same on a nagios server and on the clients).
#
#   If you have more than one nagios server managing the same sets of
#   clients you can set this to a 'string' used by all of them, and assign
#   the IPs or FQDNs of the servers directly in the xinetd template
#   instead of using the '$nagios_server' variable to set the ACL there.
#
# [*mk_confdir*]
#   Where the configs ultimately go; if you run a recent 'check_mk'
#   you can use a subdirectory of 'conf.d' if you wish.
#
# == Variables:
#
# == Example:
#
#
class checkmk::server (
  $nagios_server,
  $mk_confdir = '/etc/check_mk/conf.d/puppet'
) {

    ## Config and Update server;
    ## ------------------------
    ## We prune any not-managed-by-puppet files from the directory,
    ## and refresh nagios when we do so.
    ##
    ## NB: for this to work, your '$mk_confdir' must be totally managed
    ## by puppet; If it's not you should disable this resource. Newer
    ## versions of 'check_mk' support reading from subdirectories under
    ## 'conf.d', so you can dedicate one specifically to the generated configs
    file { $mk_confdir:
        ensure  => directory,
        purge   => true,
        recurse => true,
        notify  => Exec['checkmk_refresh'],
    }

    ## This exec statement will cause 'check_mk' to regenerate
    ## the nagios config when new nodes are added.
    exec { 'checkmk_refresh':
        command     => '/usr/bin/check_mk -O',
        refreshonly => true,
    }

    ## Collect the exported resources from the clients;
    ## ------------------------------------------------
    ## Each one will have a corresponding config file
    ## placed on the 'check_mk' server
    File <<| tag == "checkmk_conf_$nagios_server" |>> {
    }
    ## In addition, each one will have a corresponding
    ## exec resource, used to re-inventory changes.
    Exec <<| tag == "checkmk_inventory_$nagios_server" |>> {
    }
}
