for ii in `find /opt/ /home/vagrant/.chefdk/ -type f -name multiplexed_dir.rb`;do sudo sed -i '/Child with name/s/^/#/g' $ii;done
