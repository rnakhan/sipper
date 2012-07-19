check_status()
{
  if [ "$?" -gt "0" ] ; then
    echo "Sipper installation failed"
    exit
  fi
}
gem install facets-1.8.54.gem -l
gem install flexmock-0.7.1.gem -l
gem install log4r-1.0.5.gem -l
gem install rake-0.7.2.gem -l
check_status
gem install Sipper-2.0.0.gem -l
check_status
ruby i.rb
check_status
A=`cat sh.txt`
check_status
echo -n "export SIPPER_HOME=" > ~/sipper.sh
check_status
echo $A >> ~/sipper.sh
echo "export RUBYOPT=\"-rubygems\"" >> ~/sipper.sh
echo 'PATH=$PATH:$SIPPER_HOME/bin:/usr/local/bin' >> ~/sipper.sh
check_status
sudo cp -r bin/* /usr/local/bin
sudo chmod +x /usr/local/bin/s*
check_status
chmod 777 $A/sipper/logs
check_status
echo "Sipper installed succesfully"


