symfony2-vagrant
================

Install vagrant and vitualBox
---------------

__Vagrant__:

[http://downloads.vagrantup.com/](http://downloads.vagrantup.com/)

I used v1.2.1, but it should work fine for all v1.2.x versions

__VirtualBox__:

_For Ubuntu use apt to get virtual machine_:

    apt-get install virtualbox

Be sure that you have installed NFS server on your local host.

_For MacOS follow download to download page_:

[https://www.virtualbox.org/wiki/Downloads](https://www.virtualbox.org/wiki/Downloads)

NFS server should be already installed on your MacOs.

Configure virtual host or some specific settings
---------------

See [puppet/modules/config/templates](puppet/modules/config/templates) list of available configs.

You should not edit config files directly, use templates instead.

To apply changes restart vagrant box:

    vagrant reload

Or apply changes using puppet directly on your vagrant box:

    vagrant ssh

And then:

    cd /vagrant/puppet-apply


How to add php module?
----------------

Find comment "Add PHP modules here" in [puppet/manifests/default.pp](puppet/manifests/default.pp)
, then add required apt package in the end of row.

Like that: package { [ "php5", "php5-cli", **"php5-ffmpeg"**]:

Then you should apply changes as described for configuration.
