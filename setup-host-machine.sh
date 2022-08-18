#!/bin/bash
# See instructions at https://docs.nvidia.com/jetson/archives/r35.1/DeveloperGuide/text/SD/SoftwarePackagesAndTheUpdateMechanism.html#preparing-for-an-image-based-ota-update
base_release="34.1.1"
# See format from https://docs.nvidia.com/jetson/archives/r35.1/DeveloperGuide/text/SD/SoftwarePackagesAndTheUpdateMechanism.html#updating-jetson-linux-with-image-based-over-the-air-update
base_bsp_version="R34-1"
target_release="35.1.0"
base_release_tarball=jetson_linux_r${base_release}_aarch64.tbz2
base_release_tarball_wget=https://developer.nvidia.com/embedded/l4t/r34_release_v1.1/release/${base_release_tarball}
base_release_rootfs_tarball=tegra_linux_sample-root-filesystem_r${base_release}_aarch64.tbz2
base_release_rootfs_tarball_wget=https://developer.nvidia.com/embedded/l4t/r34_release_v1.1/release/${base_release_rootfs_tarball}
ota_tools_tarball=ota_tools_R${target_release}_aarch64.tbz2
ota_tools_tarball_wget=https://developer.nvidia.com/embedded/L4T/r35_Release_v1.0/Release/${ota_tools_tarball}
target_release_tarball=jetson_linux_r${target_release}_aarch64.tbz2
target_release_tarball_wget=https://developer.nvidia.com/embedded/l4t/r35_release_v1.0/release/${target_release_tarball}
target_rootfs_tarball=tegra_linux_sample-root-filesystem_r${target_release}_aarch64.tbz2
target_rootfs_tarball_wget=https://developer.nvidia.com/embedded/l4t/r35_release_v1.0/release/${target_rootfs_tarball}
pushd $(dirname $0)
mkdir -p workdir
mkdir -p workdir/base
mkdir -p workdir/target
mkdir -p workdir/output
set -e
BASE_BSP=$(pwd)/workdir/base/Linux_for_Tegra
TARGET_BSP=$(pwd)/workdir/target/Linux_for_Tegra
out_dir=$(pwd)/workdir/output
dl_dir=~/nvidia/Downloads/nvidia/sdkm_downloads
if [ ! -d ${BASE_BSP} ]; then
    echo "${BASE_BSP} does not exist, extracting"
    if [ ! -e ${dl_dir}/${base_release_tarball} ]; then
        echo "${dl_dir}/${base_release_tarball} does not exist, downloading"
        wget ${base_release_tarball_wget} -O ${dl_dir}/${base_release_tarball}
    fi
    mkdir -p ${BASE_BSP}
    tar xpf ${dl_dir}/${base_release_tarball} -C ${BASE_BSP}/..
fi
if [ ! -e ${BASE_BSP}/rootfs/etc/passwd ]; then
    echo "${BASE_BSP}/rootfs does not exist, extracting"
    if [ ! -e ${dl_dir}/${base_release_rootfs_tarball} ]; then
        echo "${dl_dir}/${base_release_rootfs_tarball} does not exist, downloading"
        wget ${base_release_rootfs_tarball_wget} -O ${dl_dir}/${base_release_rootfs_tarball}
    fi
    mkdir -p ${BASE_BSP}/rootfs
    sudo tar xpf ${dl_dir}/${base_release_rootfs_tarball} -C ${BASE_BSP}/rootfs
    pushd ${BASE_BSP}
    sudo ./apply_binaries.sh
    popd
fi
if [ ! -d ${TARGET_BSP} ]; then
    echo "${TARGET_BSP} does not exist, extracting"
    if [ ! -e ${dl_dir}/${target_release_tarball} ]; then
        echo "${dl_dir}/${target_release_tarball} does not exist, downloading"
        wget ${target_release_tarball_wget} -O ${dl_dir}/${target_release_tarball}
    fi
    mkdir -p ${TARGET_BSP}
    tar xpf ${dl_dir}/${target_release_tarball} -C ${TARGET_BSP}/..
fi
if [ ! -f ${TARGET_BSP}/rootfs/etc/passwd ]; then
    echo "${TARGET_BSP}/rootfs does not exist, extracting"
    if [ ! -e ${dl_dir}/${target_rootfs_tarball} ]; then
        echo "${dl_dir}/${target_rootfs_tarball} does not exist, downloading"
        wget ${target_rootfs_tarball_wget} -O ${dl_dir}/${target_rootfs_tarball}
    fi
    mkdir -p ${TARGET_BSP}/rootfs
    sudo tar xpf ${dl_dir}/${target_rootfs_tarball} -C ${TARGET_BSP}/rootfs
    pushd ${TARGET_BSP}
    sudo ./apply_binaries.sh
    popd
fi
if [ ! -e ${TARGET_BSP}/tools/ota_tools/version_upgrade/l4t_generate_ota_package.sh ]; then
    echo "Installing OTA tools to ${TARGET_BSP}"
    if [ ! -e ${dl_dir}/${ota_tools_tarball} ]; then
        echo "${dl_dir}/${ota_tools_tarball} does not exist, downloading"
        wget ${ota_tools_tarball_wget} -O ${dl_dir}/${ota_tools_tarball}
    fi
    sudo tar xpf ${dl_dir}/${ota_tools_tarball} -C ${TARGET_BSP}/..
fi
echo "Generating OTA update payload package"
pushd ${TARGET_BSP}
sudo -E ./tools/ota_tools/version_upgrade/l4t_generate_ota_package.sh \
    jetson-xavier-nx-devkit-emmc ${base_bsp_version}
