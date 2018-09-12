#cd /tmp
echo ############################### BASH INSTALL SCRIPT ######################################33
echo $PWD
echo ls -asl 
echo ############################### BASH INSTALL SCRIPT ######################################33
# All yum cmd
yum install -y  https://ecsft.cern.ch/dist/cvmfs/cvmfs-release/cvmfs-release-2-6.noarch.rpm \
  && yum install -y cvmfs.x86_64 wget unzip.x86_64 make.x86_64 gcc expectk dejagnu less tcl-devel.x86_64

cp cvmfs-config.computecanada.ca.pub /etc/cvmfs/keys/.
chmod 4755 /bin/ping && echo user_allow_other > /etc/fuse.conf 
# adding local config to containe. These will overwrite the cvmfs-config.computecanada ones
cp config.d/* /etc/cvmfs/config.d/.
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
cp devmodule/genpipes "/usr/local/Modules/modulefiles/."

cp genpiperc    /usr/local/etc/genpiperc
cp init_all.sh /usr/local/bin/init_genpipes
chmod 755 /usr/local/bin/init_genpipes

