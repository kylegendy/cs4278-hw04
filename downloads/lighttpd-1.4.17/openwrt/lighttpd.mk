######################################################
#
#  An example makefile to fetch a package from sources
#  then fetch the ipkg updates required to the base package
#  extract the archives into the build tree
#  and then build the source
#
######################################################


#  For this example we'll use a fairly simple package that compiles easily
#  and has sources available for download at sourceforge
LIGHTTPD=lighttpd-1.4.17
LIGHTTPD_TARGET=.built
LIGHTTPD_DIR=$(BUILD_DIR)/$(LIGHTTPD)
LIGHTTPD_IPK=$(BUILD_DIR)/$(LIGHTTPD)_mipsel.ipk
LIGHTTPD_IPK_DIR=$(BUILD_DIR)/$(LIGHTTPD)-ipk

LIGHTTPD_SITE=http://jan.kneschke.de/projects/lighttpd/download/
LIGHTTPD_SOURCE=$(LIGHTTPD).tar.gz


# We need to download sources if we dont have them
$(DL_DIR)/$(LIGHTTPD_SOURCE) :
	$(WGET) -P $(DL_DIR) $(LIGHTTPD_SITE)/$(LIGHTTPD_SOURCE)

# if we have the sources, they do no good unless they are unpacked
$(LIGHTTPD_DIR)/.unpacked:	$(DL_DIR)/$(LIGHTTPD_SOURCE)
	gzip -cd $(DL_DIR)/$(LIGHTTPD_SOURCE) | tar -C $(BUILD_DIR) -xvf -
	touch $(LIGHTTPD_DIR)/.unpacked

# if we have the sources unpacked, we need to configure them
$(LIGHTTPD_DIR)/.configured:	$(LIGHTTPD_DIR)/.unpacked
	(cd $(LIGHTTPD_DIR); rm -rf config.cache; \
		$(TARGET_CONFIGURE_OPTS) \
		CFLAGS="$(TARGET_CFLAGS)" \
		LD=$(TARGET_CROSS)ld \
		./configure \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--prefix=/usr \
		--exec-prefix=/usr \
		--bindir=/usr/bin \
		--sbindir=/usr/sbin \
		--disable-zlib \
		--sysconfdir=/etc \
		--program-transform-name="s,y,y," \
	);
	touch $(LIGHTTPD_DIR)/.configured


# now that we have it all in place, just build it
$(LIGHTTPD_DIR)/$(LIGHTTPD_TARGET):	$(LIGHTTPD_DIR)/.configured
	cd $(LIGHTTPD_DIR) && $(MAKE) CC=$(TARGET_CC) DESTDIR="$(LIGHTTPD_IPK_DIR)" install
	$(STAGING_DIR)/bin/sstrip $(LIGHTTPD_IPK_DIR)/usr/sbin/lighttpd
	touch $(LIGHTTPD_DIR)/$(LIGHTTPD_TARGET)

$(LIGHTTPD_IPK): uclibc $(LIGHTTPD_DIR)/$(LIGHTTPD_TARGET)
	mkdir -p $(LIGHTTPD_IPK_DIR)/CONTROL
	mkdir -p $(LIGHTTPD_IPK_DIR)/etc/init.d
	cp $(LIGHTTPD_DIR)/openwrt/conffiles $(LIGHTTPD_IPK_DIR)/CONTROL
	cp $(LIGHTTPD_DIR)/openwrt/control $(LIGHTTPD_IPK_DIR)/CONTROL
	cp $(LIGHTTPD_DIR)/openwrt/S51lighttpd $(LIGHTTPD_IPK_DIR)/etc/init.d/
	cp $(LIGHTTPD_DIR)/openwrt/lighttpd.conf $(LIGHTTPD_IPK_DIR)/etc/

	rm -f $(LIGHTTPD_IPK_DIR)/usr/lib/*.a
	rm -f $(LIGHTTPD_IPK_DIR)/usr/lib/*.la

	cd $(BUILD_DIR); $(IPKG_BUILD) $(LIGHTTPD_IPK_DIR)

lighttpd-ipk: $(LIGHTTPD_IPK)
