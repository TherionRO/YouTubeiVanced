#!/bin/bash
# Thanks Al4ise for his support

cd "$(dirname "$0")"	
	
# Check uYou
if 	[ ! -f Tweaks/uYou/com.miro.uyou_2.3~1_iphoneos-arm.deb ]
then
	echo -e "==> \033[1muYou v2.3~1 is not found. Downloading uYou (v2.3~1)...\033[0m"
	(set -x ; curl https://miro92.com/repo/debs/com.miro.uyou_2.3~1_iphoneos-arm.deb --output Tweaks/uYou/com.miro.uyou_2.3~1_iphoneos-arm.deb)
else
	echo -e "==> \033[1mFounded uYou (v2.3~1)!\033[0m"
fi

# Extract uYou
	echo -e "==> \033[1mExtracting uYou...\033[0m"
if 	(cd Tweaks/uYou && tar -xf com.miro.uyou_2.3~1_iphoneos-arm.deb && tar -xf data.tar.*)
then
	echo -e "\033[1m> Extracted uYou!\033[0m"
else
	echo "> \033[1mCouldn't extract uYou\033[0m"
fi

# Makefile
if 	[ -d tmp ]
then
	rm -rf tmp
fi
	read -e -p "==> Path to the decrypted YouTube.ipa or YouTube.app: " PATHTOYT
if 	[[ $PATHTOYT == *.ipa ]]
then 
	unzip -q "$PATHTOYT" -d tmp
	rm -rf tmp/Payload/YouTube.app/_CodeSignature/CodeResources
	rm -rf tmp/Payload/YouTube.app/PlugIns/*.appex
	cp -R Extensions/*.appex tmp/Payload/YouTube.app/PlugIns 
	make package FINALPACKAGE=1
	open packages

elif 	[[ $PATHTOYT == *.app ]]
then
	mkdir -p tmp/Payload/
	cp -R "$PATHTOYT" tmp/Payload 2>/dev/null
	rm -rf tmp/Payload/YouTube.app/_CodeSignature/CodeResources
	rm -rf tmp/Payload/YouTube.app/PlugIns/*.appex
	cp -R Extensions/*.appex tmp/Payload/YouTube.app/PlugIns 
	make package FINALPACKAGE=1
	open packages
else
	echo "This is not an ipa/app!"
fi
# Clean up	
	tput setaf 1 && echo -e "==> \033[1mCleaning up...\033[0m"
	find Tweaks/uYou -mindepth 1 ! -name "com.miro.uyou_2.3~1_iphoneos-arm.deb" ! -name ".gitkeep" -exec rm -rf {} \; 2>/dev/null
	rm -rf tmp/ Resources .theos/_/Payload
	echo -e  "==> \033[1mSHASUM256: $(shasum -a 256 packages/*.ipa)\033[0m"	