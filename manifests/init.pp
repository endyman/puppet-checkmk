# = Class: checkmk
#
# == Description:
#
# Puppet module to manage check_mk
#
# == Parameters:
#
#
class checkmk {

    # I like to have a convenience meta class that may be
    # disabled with a variable; this part is completely optional
    if $::checkmkmoduledisabled {
    } else {
        class {'checkmk::agent':
          nagios_server => $::nagios_server,
          mk_confdir    => $::mk_confdir,
        }
    }
}



