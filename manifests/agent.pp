# = Class: checkmk::agent
#
# == Description:
#
# * This class install the 'check_mk' agent on the monitored host
# and configures the 'Xinetd' Service used to call 'check_mk'.
# * It also exports and triggers a refresh on the remote
#   Nagios server whenever the configuration of the local node changes.
#
# == Parameters:
#
# [*nagios_server*]
#   The remote Nagios server to send data to.
#
# [*mk_confdir*]
#   Where the configs ultimately go; if you run a recent 'check_mk'
#   you can use a subdirectory of 'conf.d' if you wish.
#
# [*checkmk_override_ip*]
#   In cases where name resolution fails, we can hard-code the IP address
#   by setting the '$check_mk_override_ip' variable for the node.
#   If we cannot resolve and no address is specified, we use facter's
#   best guess for IP address.
#
# == Variables:
#
# [*mkhostname*]
# [*checkmk_no_resolve*]
# [**]
#
# == Example:
#
#
class checkmk::agent (
  $nagios_server,
  $mk_confdir          = '/etc/check_mk/conf.d/puppet',
  $checkmk_override_ip = false
) {
    ## Variables settings;
    ## -------------------
    ## It is possible that $::fqdn may not exist;
    ## Fall back on $::hostname if it does not.
    if $::fqdn {
        $mkhostname = $::fqdn
    } else {
        $checkmk_no_resolve = true
        $mkhostname = $::hostname
    }
    if $checkmk_override_ip {
        $override_ip = $::checkmk_override_ip
    } else {
        $override_ip = $::ipaddress
    }

    ## Node's Local CheckMK Agent Configuration;
    ## -----------------------------------------
    ## Ensure that your clients understand how to install the agent
    ## (e.g. add it to a repo or add a source entry to this) for this to work
    package { 'check_mk-agent':
        ensure => installed,
    }
    ## The template restricts 'check_mk' access to the 'nagios_server' or
    ## local host.
    file { '/etc/xinetd.d/check_mk':
        ensure  => file,
        content => template('checkmk/check_mk.erb'),
        mode    => '0644',
        owner   => root,
        group   => root,
    }

    ## The exported 'file' resource;
    ## -----------------------------
    ## The template will create a valid snippet of python code
    ## in a file named after the host.
    @@file { "$mk_confdir/$mkhostname.mk":
        content => template( 'checkmk/collection.mk.erb'),
        notify  => Exec["checkmk_inventory_$mkhostname"],
        tag     => "checkmk_conf_$nagios_server",
    }

    ## The exported 'exec' resource;
    ## -----------------------------
    ## This will trigger a 'check_mk' inventory of the specific node
    ## whenever its config changes.
    @@exec { "checkmk_inventory_$mkhostname":
        command     => "/usr/bin/check_mk -I $mkhostname",
        notify      => Exec['checkmk_refresh'],
        refreshonly => true,
        tag         => "checkmk_inventory_$nagios_server",
    }
}
