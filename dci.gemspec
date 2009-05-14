# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{dci}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Rich Lane"]
  s.date = %q{2009-05-13}
  s.email = %q{rlane@club.cc.cmu.edu}
  s.executables = ["reindex", "proxy", "query"]
  s.extra_rdoc_files = [
    "README"
  ]
  s.files = [
    ".gitignore",
     "BENCHMARK",
     "README",
     "TODO",
     "VERSION",
     "bin/proxy",
     "bin/query",
     "bin/reindex",
     "etc/config.yaml.template",
     "lib/dci.rb",
     "lib/dci/common.rb",
     "lib/dci/db.rb",
     "lib/dci/heuristics.rb",
     "lib/dci/heuristics/basic.rb",
     "lib/dci/index.rb",
     "lib/dci/protocol.rb",
     "lib/dci/proxy.rb",
     "lib/dci/proxy/base_connection.rb",
     "lib/dci/proxy/client_connection.rb",
     "lib/dci/proxy/console.rb",
     "lib/dci/proxy/downloader.rb",
     "lib/dci/proxy/http.rb",
     "lib/dci/proxy/hub_connection.rb",
     "lib/dci/proxy/jabber.rb",
     "lib/dci/proxy/transfer.rb",
     "var/downloads/.keep",
     "var/filelists/.keep",
     "var/log/.keep"
  ]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/rlane/dci}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.2}
  s.summary = %q{HTTP/Jabber interface to Direct Connect}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
