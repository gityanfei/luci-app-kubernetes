include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI Kubernetes Management Plugin
LUCI_DEPENDS:=+kubectl +curl +jq
LUCI_PKGARCH:=all
PKG_NAME:=luci-app-kubernetes
PKG_VERSION:=0.0.2
PKG_RELEASE:=1

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
