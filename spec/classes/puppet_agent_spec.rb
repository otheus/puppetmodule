require 'spec_helper'

describe 'puppet::agent', :type => :class do
  context 'on Debian operatingsystems' do
    let(:facts) do
      {
        :osfamily        => 'Debian',
        :operatingsystem => 'Debian',
        :kernel          => 'Linux',
        :puppetversion   => '3.8.0'
      }
    end

    describe 'when installed as' do
      context 'a service' do
        let(:params) do
          {
            :puppet_server          => 'test.exaple.com',
            :puppet_agent_service   => 'puppet',
            :puppet_agent_package   => 'puppet',
            :version                => '/etc/puppet/manifests/site.pp',
            :puppet_run_style       => 'service',
            :splay                  => 'true',
            :environment            => 'production',
            :puppet_run_interval    => 30,
            :puppet_server_port     => 8140,
          }
        end
        it {
          should contain_file('/etc/default/puppet').with(
            :mode     => '0644',
            :owner    => 'root',
            :group    => 'root',
            :content  => /START=yes/,
            :require  => "Package[#{params[:puppet_agent_package]}]"
          )
          should contain_service(params[:puppet_agent_service]).with(
            :ensure  => 'running',
            :enable  => true,
            :require => "Package[#{params[:puppet_agent_package]}]"
          )
        }
      end
      context 'using cron' do
        let(:params) do
          {
            :puppet_server          => 'test.exaple.com',
            :puppet_agent_service   => 'puppet',
            :puppet_agent_package   => 'puppet',
            :version                => '/etc/puppet/manifests/site.pp',
            :puppet_run_style       => 'cron',
            :splay                  => 'true',
            :environment            => 'production',
            :puppet_server_port     => 8140,
            :cron_hour              => 5,
            :cron_minute            => '*/30',
          }
        end
        it{
          should contain_file('/etc/default/puppet').with(
            :mode     => '0644',
            :owner    => 'root',
            :group    => 'root',
            :content  => /START=no/,
            :require  => "Package[#{params[:puppet_agent_package]}]"
          )
          should contain_service(params[:puppet_agent_service]).with(
            :ensure  => 'stopped',
            :enable  => false,
            :require => "Package[#{params[:puppet_agent_package]}]"
          )
          should contain_cron('puppet-agent').with(
            :command  => '/usr/bin/puppet agent --no-daemonize --onetime --logdest syslog > /dev/null 2>&1',
            :user     => 'root',
            :hour     => '5',
            :minute   => '*/30'
          )
        }
      end
      context 'using cron-with-ip1' do
        let(:params) do
          {
            :puppet_server          => 'test.exaple.com',
            :puppet_agent_service   => 'puppet',
            :puppet_agent_package   => 'puppet',
            :version                => '/etc/puppet/manifests/site.pp',
            :puppet_run_style       => 'cron',
            :splay                  => 'true',
            :environment            => 'production',
            :puppet_server_port     => 8140,
	    :cron_minute => 'ip:10.2.3.44/8%60', # (2*256*256+3*256+44)%60 = 4
          }
        end
        it{
          should contain_cron('puppet-agent').with(
            :command  => '/usr/bin/puppet agent --no-daemonize --onetime --logdest syslog > /dev/null 2>&1',
            :user     => 'root',
            :hour     => '*',
            :minute   => '4'
          )
        }
      end
      context 'using cron-with-ip2' do
        let(:params) do
          {
            :puppet_server          => 'test.exaple.com',
            :puppet_agent_service   => 'puppet',
            :puppet_agent_package   => 'puppet',
            :version                => '/etc/puppet/manifests/site.pp',
            :puppet_run_style       => 'cron',
            :splay                  => 'true',
            :environment            => 'production',
            :puppet_server_port     => 8140,
	    :cron_minute => 'ip:10.2.3.44/16%300', # .. (3*256+44)%300 = 212
          }
        end
        it{
          should contain_cron('puppet-agent').with(
            :command  => '/usr/bin/puppet agent --no-daemonize --onetime --logdest syslog > /dev/null 2>&1',
            :user     => 'root',
            :hour     => '*',
            :minute   => '212'
          )
        }
      end
      context 'using cron-with-ip3' do
        let(:params) do
          {
            :puppet_server          => 'test.exaple.com',
            :puppet_agent_service   => 'puppet',
            :puppet_agent_package   => 'puppet',
            :version                => '/etc/puppet/manifests/site.pp',
            :puppet_run_style       => 'cron',
            :splay                  => 'true',
            :environment            => 'production',
            :puppet_server_port     => 8140,
	    :cron_minute            => 'ip/0', # .. (127*256*256+1)%60 = 53
          }
        end
        it{
          should contain_cron('puppet-agent').with(
            :command  => '/usr/bin/puppet agent --no-daemonize --onetime --logdest syslog > /dev/null 2>&1',
            :user     => 'root',
            :hour     => '*',
            :minute   => '53'
          )
        }
      end

    end

    describe 'srv records on Debian' do
      context 'fail on Debian with use_srv_records but no srv_domain set' do
        let(:params) do
          {
            :puppet_server          => 'test.exaple.com',
            :puppet_agent_service   => 'puppet',
            :puppet_agent_package   => 'puppet',
            :version                => '/etc/puppet/manifests/site.pp',
            :puppet_run_style       => 'cron',
            :splay                  => 'true',
            :environment            => 'production',
            :puppet_run_interval    => 30,
            :puppet_server_port     => 8140,
            :use_srv_records        => true,
          }
        end

        it {
          should compile.and_raise_error(/puppet has attribute use_srv_records set but has srv_domain unset/)
        }
      end

      context 'on Debian with use_srv_records false' do
        let(:params) do
          {
            :puppet_server          => 'test.exaple.com',
            :puppet_agent_service   => 'puppet',
            :puppet_agent_package   => 'puppet',
            :version                => '/etc/puppet/manifests/site.pp',
            :puppet_run_style       => 'cron',
            :splay                  => 'true',
            :environment            => 'production',
            :puppet_run_interval    => 30,
            :puppet_server_port     => 8140,
            :use_srv_records        => false,
          }
        end

        it{
          should contain_ini_setting('puppetagentsrv_domain').with(
            :ensure  => 'absent',
            :section => 'agent',
            :setting => 'srv_domain',
            :path    => '/etc/puppet/puppet.conf'
          )
        }
      end

      context 'on Debian with use_srv_records and srv_domain set' do
        let(:params) do
          {
            :puppet_server          => 'test.exaple.com',
            :puppet_agent_service   => 'puppet',
            :puppet_agent_package   => 'puppet',
            :version                => '/etc/puppet/manifests/site.pp',
            :puppet_run_style       => 'cron',
            :splay                  => 'true',
            :environment            => 'production',
            :puppet_run_interval    => 30,
            :puppet_server_port     => 8140,
            :use_srv_records        => true,
            :srv_domain             => 'example.com',
          }
        end

        it{
          should contain_ini_setting('puppetagentuse_srv_records').with(
            :ensure  => 'present',
            :section => 'agent',
            :setting => 'use_srv_records',
            :path    => '/etc/puppet/puppet.conf',
            :value   => 'true'
          )
          should contain_ini_setting('puppetagentsrv_domain').with(
            :ensure  => 'present',
            :section => 'agent',
            :setting => 'srv_domain',
            :path    => '/etc/puppet/puppet.conf',
            :value   => params[:srv_domain]
          )
        }
      end
    end
  end
  context 'on RedHat operatingsystems' do
    let(:facts) do
      {
        :osfamily        => 'RedHat',
        :operatingsystem => 'RedHat',
        :kernel          => 'Linux',
        :puppetversion   => '3.8.0'
      }
    end
    describe 'when installed' do
      context 'as a service' do
        let(:params) do
          {
            :puppet_server          => 'test.exaple.com',
            :puppet_agent_service   => 'puppet',
            :puppet_agent_package   => 'puppet',
            :version                => '/etc/puppet/manifests/site.pp',
            :puppet_run_style       => 'service',
            :splay                  => 'true',
            :environment            => 'production',
            :puppet_run_interval    => 30,
            :puppet_server_port     => 8140,
          }
        end
        it {
          should contain_file('/etc/sysconfig/puppet').with(
            :mode     => '0644',
            :owner    => 'root',
            :group    => 'root',
            :content  => /PUPPET_SERVER=#{params[:puppet_server]}/,
            :require  => "Package[#{params[:puppet_agent_package]}]"
          )
          should contain_service(params[:puppet_agent_service]).with(
            :ensure  => 'running',
            :enable  => true,
            :require => "Package[#{params[:puppet_agent_package]}]"
          )
        }
      end

      context 'using cron' do
        let(:params) do
          {
            :puppet_server          => 'test.exaple.com',
            :puppet_agent_service   => 'puppet',
            :puppet_agent_package   => 'puppet',
            :version                => '/etc/puppet/manifests/site.pp',
            :puppet_run_style       => 'cron',
            :splay                  => 'true',
            :environment            => 'production',
            :puppet_run_interval    => 30,
            :puppet_server_port     => 8140,
          }
        end
        it{
          should contain_file('/etc/sysconfig/puppet').with(
            :mode     => '0644',
            :owner    => 'root',
            :group    => 'root',
            :content  => /PUPPET_SERVER=#{params[:puppet_server]}/,
            :require  => "Package[#{params[:puppet_agent_package]}]"
          )
          should contain_service(params[:puppet_agent_service]).with(
            :ensure  => 'stopped',
            :enable  => false,
            :require => "Package[#{params[:puppet_agent_package]}]"
          )
          should contain_cron('puppet-agent').with(
            :command  => '/usr/bin/puppet agent --no-daemonize --onetime --logdest syslog > /dev/null 2>&1',
            :user  => 'root',
            :hour => '*'
          )
        }
      end
    end

    describe 'srv records on RedHat' do
      context 'with use_srv_records but no srv_domain set' do
        let(:params) do
          {
            :puppet_server          => 'test.exaple.com',
            :puppet_agent_service   => 'puppet',
            :puppet_agent_package   => 'puppet',
            :version                => '/etc/puppet/manifests/site.pp',
            :puppet_run_style       => 'cron',
            :splay                  => 'true',
            :environment            => 'production',
            :puppet_run_interval    => 30,
            :puppet_server_port     => 8140,
            :use_srv_records        => true,
          }
        end

        it {
          should compile.and_raise_error(/puppet has attribute use_srv_records set but has srv_domain unset/)
        }
      end

      context 'with use_srv_records false' do
        let(:params) do
          {
            :puppet_server          => 'test.exaple.com',
            :puppet_agent_service   => 'puppet',
            :puppet_agent_package   => 'puppet',
            :version                => '/etc/puppet/manifests/site.pp',
            :puppet_run_style       => 'cron',
            :splay                  => 'true',
            :environment            => 'production',
            :puppet_run_interval    => 30,
            :puppet_server_port     => 8140,
            :use_srv_records        => false,
          }
        end

        it{
          should contain_ini_setting('puppetagentsrv_domain').with(
            :ensure  => 'absent',
            :section => 'agent',
            :setting => 'srv_domain',
            :path    => '/etc/puppet/puppet.conf'
          )
        }
      end

      context 'with use_srv_records and srv_domain set' do
        let(:params) do
          {
            :puppet_server          => 'test.exaple.com',
            :puppet_agent_service   => 'puppet',
            :puppet_agent_package   => 'puppet',
            :version                => '/etc/puppet/manifests/site.pp',
            :puppet_run_style       => 'cron',
            :splay                  => 'true',
            :environment            => 'production',
            :puppet_run_interval    => 30,
            :puppet_server_port     => 8140,
            :use_srv_records        => true,
            :srv_domain             => 'example.com',
          }
        end

        it{
          should contain_ini_setting('puppetagentuse_srv_records').with(
            :ensure  => 'present',
            :section => 'agent',
            :setting => 'use_srv_records',
            :path    => '/etc/puppet/puppet.conf',
            :value   => 'true'
          )
          should contain_ini_setting('puppetagentsrv_domain').with(
            :ensure  => 'present',
            :section => 'agent',
            :setting => 'srv_domain',
            :path    => '/etc/puppet/puppet.conf',
            :value   => params[:srv_domain]
          )
        }
      end
    end
  end

  describe 'Ordering' do
    let(:facts) do
      {
        :osfamily        => 'RedHat',
        :operatingsystem => 'RedHat',
        :kernel          => 'Linux',
        :puppetversion   => '3.8.0'
      }
    end
    context 'with ordering set' do
      let(:params) do
        {
          :puppet_server          => 'test.exaple.com',
          :puppet_agent_service   => 'puppet',
          :puppet_agent_package   => 'puppet',
          :version                => '/etc/puppet/manifests/site.pp',
          :puppet_run_style       => 'cron',
          :splay                  => 'true',
          :environment            => 'production',
          :ordering               => 'manifest',
          :puppet_run_interval    => 30,
          :puppet_server_port     => 8140,
          :use_srv_records        => false,
        }
      end

      it{
        should contain_ini_setting('puppetagentordering').with(
          :ensure  => 'present',
          :section => 'agent',
          :setting => 'ordering',
          :value   => 'manifest',
          :path    => '/etc/puppet/puppet.conf'
        )
      }
    end

    context 'with ordering not set' do
      let(:params) do
        {
          :puppet_server          => 'test.exaple.com',
          :puppet_agent_service   => 'puppet',
          :puppet_agent_package   => 'puppet',
          :version                => '/etc/puppet/manifests/site.pp',
          :puppet_run_style       => 'cron',
          :splay                  => 'true',
          :environment            => 'production',
          :puppet_run_interval    => 30,
          :puppet_server_port     => 8140,
          :use_srv_records        => false,
        }
      end

      it{
        should contain_ini_setting('puppetagentordering').with(
          :ensure  => 'absent',
          :section => 'agent',
          :setting => 'ordering',
          :path    => '/etc/puppet/puppet.conf'
        )
      }
    end
  end
  describe 'Trusted fact' do
    let(:facts) do
      {
        :osfamily        => 'RedHat',
        :operatingsystem => 'RedHat',
        :kernel          => 'Linux',
        :puppetversion   => '3.8.0'
      }
    end
    context 'with trusted set' do
      let(:params) do
        {
          :puppet_server          => 'test.exaple.com',
          :puppet_agent_service   => 'puppet',
          :puppet_agent_package   => 'puppet',
          :version                => '/etc/puppet/manifests/site.pp',
          :puppet_run_style       => 'cron',
          :splay                  => 'true',
          :environment            => 'production',
          :trusted_node_data      => 'true',
          :puppet_run_interval    => 30,
          :puppet_server_port     => 8140,
          :use_srv_records        => false,
        }
      end

      it{
        should contain_ini_setting('puppetagenttrusted_node_data').with(
          :ensure  => 'present',
          :section => 'agent',
          :setting => 'trusted_node_data',
          :value   => 'true',
          :path    => '/etc/puppet/puppet.conf'
        )
      }
    end

    context 'with trusted not set' do
      let(:params) do
        {
          :puppet_server          => 'test.exaple.com',
          :puppet_agent_service   => 'puppet',
          :puppet_agent_package   => 'puppet',
          :version                => '/etc/puppet/manifests/site.pp',
          :puppet_run_style       => 'cron',
          :splay                  => 'true',
          :environment            => 'production',
          :puppet_run_interval    => 30,
          :puppet_server_port     => 8140,
          :use_srv_records        => false,
        }
      end

      it{
        should contain_ini_setting('puppetagenttrusted_node_data').with(
          :ensure  => 'absent',
          :section => 'agent',
          :setting => 'trusted_node_data',
          :path    => '/etc/puppet/puppet.conf'
        )
      }
    end
  end
  describe 'Trusted fact' do
    let(:facts) do
      {
        :osfamily        => 'RedHat',
        :operatingsystem => 'RedHat',
        :kernel          => 'Linux',
        :puppetversion   => '3.8.0'
      }
    end
    context 'with templatedir set' do
      let(:params) do
        {
          :puppet_server          => 'test.exaple.com',
          :puppet_agent_service   => 'puppet',
          :puppet_agent_package   => 'puppet',
          :version                => '/etc/puppet/manifests/site.pp',
          :puppet_run_style       => 'cron',
          :splay                  => 'true',
          :environment            => 'production',
          :puppet_run_interval    => 30,
          :puppet_server_port     => 8140,
          :use_srv_records        => false,
          :templatedir            => '$confdir/templates'
        }
      end

      it{
        should contain_ini_setting('puppetagenttemplatedir').with(
          :ensure  => 'present',
          :section => 'main',
          :setting => 'templatedir',
          :value   => '$confdir/templates',
          :path    => '/etc/puppet/puppet.conf'
        )
      }
    end

    context 'with templatedir not set' do
      let(:params) do
        {
          :puppet_server          => 'test.exaple.com',
          :puppet_agent_service   => 'puppet',
          :puppet_agent_package   => 'puppet',
          :version                => '/etc/puppet/manifests/site.pp',
          :puppet_run_style       => 'cron',
          :splay                  => 'true',
          :environment            => 'production',
          :puppet_run_interval    => 30,
          :puppet_server_port     => 8140,
          :use_srv_records        => false
        }
      end

      it{
        should contain_ini_setting('puppetagenttemplatedir').with(
          :ensure  => 'absent',
          :section => 'main',
          :setting => 'templatedir',
          :path    => '/etc/puppet/puppet.conf'
        )
      }
    end
  end
  describe 'configtimeout' do
    let(:facts) do
      {
        :osfamily        => 'RedHat',
        :operatingsystem => 'RedHat',
        :kernel          => 'Linux',
        :puppetversion   => '3.8.0'
      }
    end
    context 'with configtimeout set' do
      let(:params) do
        {
          :configtimeout        => '3m',
        }
      end

      it{
        should contain_ini_setting('puppetagentconfigtimeout').with(
          :ensure  => 'present',
          :section => 'agent',
          :setting => 'configtimeout',
          :value   => '3m',
          :path    => '/etc/puppet/puppet.conf'
        )
      }
    end

    context 'with configtimeout not set' do
      let(:params) do
        {
        }
      end

      it{
        should contain_ini_setting('puppetagentconfigtimeout').with(
          :ensure  => 'present',
          :section => 'agent',
          :setting => 'configtimeout',
          :value   => '2m',
          :path    => '/etc/puppet/puppet.conf'
        )
      }
    end
  end
  describe 'puppetagentshow_diff' do
    let(:facts) do
      {
        :osfamily        => 'RedHat',
        :operatingsystem => 'RedHat',
        :kernel          => 'Linux',
        :puppetversion   => '3.8.0'
      }
    end
    context 'with show_diff set' do
      let(:params) do
        {
          :show_diff        => true,
        }
      end

      it{
        should contain_ini_setting('puppetagentshow_diff').with(
          :ensure  => 'present',
          :section => 'main',
          :setting => 'show_diff',
          :value   => true,
          :path    => '/etc/puppet/puppet.conf'
        )
      }
    end
  end
  describe 'puppetagentstringifyfacts' do
    let(:facts) do
      {
        :osfamily        => 'RedHat',
        :operatingsystem => 'RedHat',
        :kernel          => 'Linux',
        :puppetversion   => '3.8.0'
      }
    end
    context 'with stringify_facts set' do
      let(:params) do
        {
          :stringify_facts        => true,
        }
      end

      it{
        should contain_ini_setting('puppetagentstringifyfacts').with(
          :ensure  => 'present',
          :section => 'agent',
          :setting => 'stringify_facts',
          :value   => 'true',
          :path    => '/etc/puppet/puppet.conf'
        )
      }
    end
  end
  describe 'puppetagenthttpproxyhost' do
    let(:facts) do
      {
        :osfamily        => 'RedHat',
        :operatingsystem => 'RedHat',
        :kernel          => 'Linux',
        :puppetversion   => '3.8.0'
      }
    end
    context 'with http_proxy_host set' do
      let(:params) do
        {
          :http_proxy_host => 'proxy.example.com',
        }
      end

      it{
        should contain_ini_setting('puppetagenthttpproxyhost').with(
          :ensure  => 'present',
          :section => 'agent',
          :setting => 'http_proxy_host',
          :value   => 'proxy.example.com',
          :path    => '/etc/puppet/puppet.conf'
        )
      }
    end
  end
  describe 'puppetagenthttpproxyport' do
    let(:facts) do
      {
        :osfamily        => 'RedHat',
        :operatingsystem => 'RedHat',
        :kernel          => 'Linux',
        :puppetversion   => '3.8.0'
      }
    end
    context 'with http_proxy_port set' do
      let(:params) do
        {
          :http_proxy_port => '1234',
        }
      end

      it{
        should contain_ini_setting('puppetagenthttpproxyport').with(
          :ensure  => 'present',
          :section => 'agent',
          :setting => 'http_proxy_port',
          :value   => '1234',
          :path    => '/etc/puppet/puppet.conf'
        )
      }
    end
  end
end
