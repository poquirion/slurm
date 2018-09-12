#!/bin/bash

START_DIR=$PWD
cd $(mktemp -d)
function finish {
  cd $START_DIR
}
trap finish EXIT

cat > cvmfs-config.computecanada.ca.pub <<- EOF 
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA43uMewjRAbmggvGn/juJ
WlnAhqgcQkKQodM5/T2b2p97RLef8U5foUvaLhtjryDqD9UKEP0tZVtV4mh6zTjT
6NzRp4615/0k2l/iMbqmjdH1LKFqrTAC7s+03iA1FhmYzuiUaNDHp+K2zYxreiRf
rex+5HKzeI/QYgGYRCrOY/6rNeIQ0I38FfqoOZq2bcoi0SsBDtvEc+ayCkoaOAsh
bB2DcFigMkJVkiqyjAHpLp8Y35ISg195KPVDL2wjdfRZ9/DVsgd+QcQ/MTvLRrDp
+PfsUXIREFb/hkw441yLzG8QcNECWicG5cDW3GLZUYA9gMLzZawNxeb+nQcEX+NH
jQIDAQAB
-----END PUBLIC KEY-----
EOF

cat > genpipesrc <<- EOF 
source /etc/bashrc
source ~/.bashrc
echo -e "\nWait while Genpipes module are loaded. This could take a while,"
echo -e   "  especially if the cvmfs cache is new\n"
module use $MUGQIC_INSTALL_HOME/modulefiles
module load mugqic/python/2.7.14
module load mugqic/genpipes${PIPELINE_VERSION}
EOF


cat > cvmfs-config.computecanada.ca.conf <<- EOF
CVMFS_HTTP_PROXY='DIRECT'
CVMFS_SERVER_URL="http://cvmfs-s1-east.computecanada.ca:8000/cvmfs/@fqrn@;http://cvmfs-s1.arbutus.computecanada.ca:8000/cvmfs/@fqrn@"
CVMFS_PUBLIC_KEY="/etc/cvmfs/keys/cvmfs-config.computecanada.ca.pub"
CVMFS_USE_GEOAPI=yes
EOF
cat > ref.mugqic <<- EOF
CVMFS_SERVER_URL="http://cvmfs-s0-genomic.vhost38.genap.ca/cvmfs/@fqrn@"
CVMFS_KEYS_DIR=/cvmfs/cvmfs-config.computecanada.ca/etc/cvmfs/keys/mugqic
CVMFS_HTTP_PROXY=DIRECT
EOF
cat > soft.mugqic <<- EOF
CVMFS_SERVER_URL="http://cvmfs-s0-genomic.vhost38.genap.ca/cvmfs/@fqrn@"
CVMFS_KEYS_DIR=/cvmfs/cvmfs-config.computecanada.ca/etc/cvmfs/keys/mugqic
CVMFS_HTTP_PROXY=DIRECT
EOF

cat > dev_genpipes <<- EOF
#%Module1.0
proc ModulesHelp { } {

  puts stderr "\tDev - genpipes  "  
}
module-whatis "genpipes"
set             root                  $env(GENPIPES_DEV_DIR)
if { [ module-info mode load ] } {
    puts stderr "unloading mugqic/genpipes"
    module unload mugqic/genpipes
    puts stderr "Load GENPIPES available in '$root'"
}
setenv          MUGQIC_PIPELINES_HOME $root
prepend-path    PATH                  $root/utils
prepend-path    PATH                  $root/pipelines/ampliconseq
prepend-path    PATH                  $root/pipelines/chipseq
prepend-path    PATH                  $root/pipelines/dnaseq
prepend-path    PATH                  $root/pipelines/dnaseq_high_coverage
prepend-path    PATH                  $root/pipelines/illumina_run_processing
prepend-path    PATH                  $root/pipelines/methylseq
prepend-path    PATH                  $root/pipelines/pacbio_assembly
prepend-path    PATH                  $root/pipelines/rnaseq
prepend-path    PATH                  $root/pipelines/rnaseq_denovo_assembly
prepend-path    PATH                  $root/pipelines/tumor_pair
prepend-path    PATH                  $root/pipelines/hicseq
EOF

# All yum cmd
yum install -y  https://ecsft.cern.ch/dist/cvmfs/cvmfs-release/cvmfs-release-2-6.noarch.rpm \
  && yum install -y cvmfs.x86_64 wget unzip.x86_64 make.x86_64 gcc expectk dejagnu less tcl-devel.x86_64

cp cvmfs-config.computecanada.ca.pub /etc/cvmfs/keys/.
echo user_allow_other >> /etc/fuse.conf 
# adding local config to containe. These will overwrite the cvmfs-config.computecanada ones
cp *.conf /etc/cvmfs/config.d/.
mkdir /cvmfs-cache && chmod 777 /cvmfs-cache \
mkdir /cvmfs/{ref.mugqic,soft.mugqic,cvmfs-config.computecanada.ca} && chmod 777 /cvmfs/{ref.mugqic,soft.mugqic,cvmfs-config.computecanada.ca}  \
mkdir  /var/run/cvmfs   && chmod 777  /run/cvmfs && chmod 777  /var/run/cvmfs && chmod 777 /var/lib/cvmfs

# module
MODULE_VERSION=4.1.2
wget https://github.com/cea-hpc/modules/releases/download/v${MODULE_VERSION}/modules-${MODULE_VERSION}.tar.gz 
tar xzf modules-${MODULE_VERSION}.tar.gz && \
    rm modules-${MODULE_VERSION}.tar.gz
cd  modules-${MODULE_VERSION}  && ./configure && make -j 7  && make install
ln -s /usr/local/Modules/init/profile.sh /etc/profile.d/z00_module.sh
echo "source /etc/profile.d/z00_module.sh" >>  /etc/bashrc
rm -rf /usr/local/Modules/modulefiles/*
cp dev_genpipes "/usr/local/Modules/modulefiles/."

mount -t cvmfs  cvmfs-config.computecanada.ca   /cvmfs/cvmfs-config.computecanada.ca
mount -t cvmfs soft.mugqic    /cvmfs/soft.mugqic
mount  -t cvmfs ref.mugqic   /cvmfs/ref.mugqic

cp genpipesrc    /etc/profile.d/genpipes.sh
echo source /etc/profile.d/genpipes.sh >>    /etc/bash.bashrc


