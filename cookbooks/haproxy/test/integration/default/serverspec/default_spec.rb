require 'serverspec'

set :backend, :exec
set :path, '$PATH:/sbin:/usr/sbin'

describe "Haproxy Daemon" do

  describe package('haproxy') do
    it { should be_installed }
  end

  describe service('haproxy') do
    it { should be_enabled   }
    it { should be_running   }
  end

  [80, 443].each do |port|
    it "is listening on port #{port}" do
      expect(port(port)).to be_listening
    end
  end

  describe file('/etc/haproxy/haproxy.cfg') do
    it { should be_file }
    its(:content) { should match /#{Regexp.quote('server localhost 127.0.0.1:80 weight 1 maxconn 1024 check')}/ }
    its(:content) { should match /#{Regexp.quote('server localhost 127.0.0.1:443 weight 1 maxconn 1024 check')}/ }
  end

end
