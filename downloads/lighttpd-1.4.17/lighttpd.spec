Summary: A fast webserver with minimal memory-footprint (lighttpd)
Name: lighttpd
Version: 1.4.17
Release: 1
Source: http://jan.kneschke.de/projects/lighttpd/download/lighttpd-%version.tar.gz
Packager: Jan Kneschke <jan@kneschke.de>
License: BSD
Group: Networking/Daemons
URL: http://jan.kneschke.de/projects/lighttpd/
Requires: pcre >= 3.1 zlib
BuildPrereq: libtool zlib-devel
BuildRoot: %{_tmppath}/%{name}-root


%description
lighttpd is intented to be a frontend for ad-servers which have to deliver
small files concurrently to many connections.

Available rpmbuild rebuild options :
--with : ssl mysql lua memcache

%prep

%setup -q

%build
rm -rf %{buildroot}
%configure \
    %{?_with_mysql:       --with-mysql} \
    %{?_with_lua:         --with-lua} \
    %{?_with_memcache:    --with-memcache} \
    %{?_with_ssl:         --with-openssl}
make

%install

%makeinstall

mkdir -p %{buildroot}%{_sysconfdir}/{init.d,sysconfig}
if test -f /etc/redhat-release -o -f /etc/fedora-release; then
  install -m 755 doc/rc.lighttpd.redhat %{buildroot}%{_sysconfdir}/init.d/lighttpd
else
  install -m 755 doc/rc.lighttpd %{buildroot}%{_sysconfdir}/init.d/lighttpd
fi
install -m 644 doc/sysconfig.lighttpd %{buildroot}%{_sysconfdir}/sysconfig/lighttpd

%clean
rm -rf %{buildroot}

%post
## read http://www.fedora.us/docs/spec.html next time :)
if test "$1" = "1"; then
  # real install, not upgrade
  /sbin/chkconfig --add lighttpd
fi

%preun
if test "$1" = "0"; then
  # real uninstall, not upgrade
  %{_sysconfdir}/init.d/lighttpd stop
  /sbin/chkconfig --del lighttpd
fi

%files
%defattr(-,root,root)
%doc doc/lighttpd.conf doc/lighttpd.user README INSTALL ChangeLog COPYING AUTHORS
%doc doc/*.txt
%config(noreplace) %attr(0755,root,root) %{_sysconfdir}/init.d/lighttpd
%config(noreplace) %attr(0644,root,root) %{_sysconfdir}/sysconfig/lighttpd
%{_mandir}/*
%{_libdir}/*
%{_sbindir}/*
%{_bindir}/*

%changelog
* Thu Sep 30 2004 12:41 <jan@kneschke.de> 1.3.1
- upgraded to 1.3.1

* Tue Jun 29 2004 17:26 <jan@kneschke.de> 1.2.3
- rpmlint'ed the package
- added URL
- added (noreplace) to start-script
- change group to Networking/Daemon (like apache)

* Sun Feb 23 2003 15:04 <jan@kneschke.de>
- initial version
