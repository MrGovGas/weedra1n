TARGET_CODESIGN = $(shell which ldid)

WRTMP = $(TMPDIR)/pogo
WR_STAGE_DIR = $(WRTMP)/stage
WR_APP_DIR 	= $(WRTMP)/Build/Products/Release-iphoneos/weedra1n.app
WR_HELPER_PATH 	= $(WRTMP)/Build/Products/Release-iphoneos/weedra1nHelper
GIT_REV=$(shell git rev-parse --short HEAD)

package:
	/usr/libexec/PlistBuddy -c "Set :REVISION ${GIT_REV}" "weedra1n/Info.plist"

	@set -o pipefail; \
		xcodebuild -jobs $(shell sysctl -n hw.ncpu) -project 'weedra1n.xcodeproj' -scheme weedra1n -configuration Release -arch arm64 -sdk iphoneos -derivedDataPath $(WRTMP) \
		CODE_SIGNING_ALLOWED=NO DSTROOT=$(WRTMP)/install ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES=NO
	@set -o pipefail; \
		xcodebuild -jobs $(shell sysctl -n hw.ncpu) -project 'weedra1n.xcodeproj' -scheme weedra1nHelper -configuration Release -arch arm64 -sdk iphoneos -derivedDataPath $(WRTMP) \
		CODE_SIGNING_ALLOWED=NO DSTROOT=$(WRTMP)/install ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES=NO
	@rm -rf Payload
	@rm -rf $(WR_STAGE_DIR)/
	@mkdir -p $(WR_STAGE_DIR)/Payload
	@mv $(WR_APP_DIR) $(WR_STAGE_DIR)/Payload/weedra1n.app

	@echo $(WRTMP)
	@echo $(WR_STAGE_DIR)

	@ls $(WR_HELPER_PATH)
	@ls $(WR_STAGE_DIR)
	@mv $(WR_HELPER_PATH) $(WR_STAGE_DIR)/Payload/weedra1n.app/weedra1nHelper
	@$(TARGET_CODESIGN) -Sentitlements.xml $(WR_STAGE_DIR)/Payload/weedra1n.app/
	@$(TARGET_CODESIGN) -Sentitlements.xml $(WR_STAGE_DIR)/Payload/weedra1n.app//weedra1nHelper
	
	@rm -rf $(WR_STAGE_DIR)/Payload/weedra1n.app/_CodeSignature

	@ln -sf $(WR_STAGE_DIR)/Payload Payload

	@rm -rf packages
	@mkdir -p packages

	@zip -r9 packages/weedra1n.ipa Payload
