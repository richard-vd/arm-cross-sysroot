#!/bin/bash

if ! [ "${UV_board}" == "raspi" ]; then
	return
fi

GV_url="git://git.drogon.net/wiringPi"
GV_sha1=""

DEPEND=()

GV_args=()

FU_tools_get_names_from_url
FU_tools_installed "wiringPi.pc"

if [ $? == 1 ]; then
	
	FU_tools_check_depend
	
	GV_dir_name=${GV_dir_name%.*}
	GV_name=$GV_dir_name
	
	FU_file_git_clone	
	
	cd "${GV_source_dir}/${GV_dir_name}"
	
	# remove sudo from install file
	$SED -e 's/sudo //g' build > build.sh
	
	MAKEFILES=($(find . -name Makefile))
	
	for entry in ${MAKEFILES[*]}
	do
		cp $entry "${entry}.ori"
		$SED -e 's/gcc/arm-linux-gnueabihf-gcc/g' "${entry}.ori" > $entry
		cp $entry "${entry}.ori"
		$SED -e 's/\/local//g' "${entry}.ori" > $entry
		cp $entry "${entry}.ori"
		$SED -e 's,/usr,'"$UV_sysroot_dir"',g' "${entry}.ori" > $entry
		cp $entry "${entry}.ori"
		$SED -e 's/\@ldconfig//g' "${entry}.ori" > $entry
		cp $entry "${entry}.ori"
		$SED -e 's/\@cp gpio/#\@cp gpio/g' "${entry}.ori" > $entry
		cp $entry "${entry}.ori"
		$SED -e 's/\@chown/#\@chown/g' "${entry}.ori" > $entry
		cp $entry "${entry}.ori"
		$SED -e 's/\@chmod/#\@chmod/g' "${entry}.ori" > $entry
		
		if [ "${entry}" ==  "./devLib/Makefile" ]; then
			cp $entry "${entry}.ori"
			$SED -e 's,INCLUDE	= -I.,'"INCLUDE	= -I. -I$UV_sysroot_dir/include"',g' "${entry}.ori" > $entry
		fi
		
		
		rm -f "${entry}.ori"
	done
	
	echo -n "Build and Install ${GV_name}... "
	chmod +x build.sh
	./build.sh >$GV_log_file 2>&1
	FU_tools_is_error "$?"
	
	cd $GV_base_dir
	
	FU_build_finishinstall
	
cat > "${UV_sysroot_dir}/lib/pkgconfig/${GV_name}.pc" << EOF
prefix=${UV_sysroot_dir}
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
sharedlibdir=\${libdir}
includedir=\${prefix}/include

Name: ${GV_name}
Description: GPIO Interface library for the Raspberry Pi
Version: 

Requires:
Libs: -L\${libdir} -L\${sharedlibdir} -lpthread
Cflags: -I\${includedir}
EOF
fi