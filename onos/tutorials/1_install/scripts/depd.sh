# Install git
sudo apt-get install git -y

# Install zip
sudo apt-get install zip -y

# Install curl
sudo apt-get install curl -y

# Install unzip
sudo apt-get install unzip -y

# Install Python 2.7
sudo apt install python2.7 python-pip -y

# Install Oracle JDK8
sudo apt-get install software-properties-common -y
sudo add-apt-repository ppa:webupd8team/java -y
sudo apt-get update
echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | sudo debconf-set-selections
sudo apt-get install oracle-java8-installer oracle-java8-set-default -y