# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
class mig::agent::daemon {
    class { 'mig::agent::base':
        isimmortal       => 'on',
        installservice   => 'on',
        discoverpublicip => 'on',
        discoverawsmeta  => 'on',
        checkin          => 'off',
        moduletimeout    => '1200s',
        apiurl           => 'https://api.mig.mozilla.org/api/v1/'
    }
    # on package update, shutdown the old agent and start the new one
    # when the package is upgraded, exec a new instance of the agent
    $mig_path = $::operatingsystem ? { /(CentOS|Ubuntu)/ => '/sbin/mig-agent', Darwin => '/usr/local/bin/mig-agent' }
    case $::operatingsystem {
        Ubuntu: {
            case $::operatingsystemrelease {
                16.04: {
                    exec {
                        # mig hangs sometimes after a package upgrade
                        # so let systemd handle restarting it after an upgrade
                        'systemd restart mig':
                            command     => '/bin/systemctl restart mig-agent.service',
                            subscribe   => Class['packages::mozilla::mig_agent'],
                            refreshonly => true,
                            # is-active returns false if the service is inactive or does not exist
                            onlyif      => '/bin/systemctl is-active mig-agent.service',
                    }
                    service {
                        'mig-agent':
                            ensure   => running,
                            enable   => true,
                            provider => 'systemd'
                    }
                }
            }
        }
        default: {
            exec {
                'restart mig':
                    command     => "/bin/kill -s 2 $(${mig_path} -q=pid); ${mig_path}",
                    subscribe   => Class['packages::mozilla::mig_agent'],
                    refreshonly => true
            }
        }
    }
}
