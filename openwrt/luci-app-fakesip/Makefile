include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-fakesip
PKG_VERSION:=1.0.0
PKG_RELEASE:=3
PKGARCH:=all

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-fakesip
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=LuCI support for FakeSIP
  DEPENDS:=+fakesip
endef

define Package/luci-app-fakesip/description
 LuCI web interface for configuring and controlling the FakeSIP OpenWrt
 service.
endef

define Build/Compile
endef

define Package/luci-app-fakesip/install
	$(CP) ./root/* $(1)/
endef

$(eval $(call BuildPackage,luci-app-fakesip))
