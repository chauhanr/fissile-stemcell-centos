ARG base_image
FROM ${base_image}

ARG stemcell_version
RUN [ -n "$stemcell_version" ] || (echo "stemcell_version needs to be set"; exit 1)

LABEL stemcell-flavor=centos
LABEL stemcell-version=${stemcell_version}


# Install RVM & Ruby 2.4.0
RUN gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB && \
    (curl -sSL https://get.rvm.io | bash -s stable --ruby=2.4.0 --gems=public_suffix,rake) && \
    usermod -a -G rvm root && \
    (echo "[[ -s /usr/local/rvm/scripts/rvm ]] && source /etc/profile.d/rvm.sh" >> /root/.bashrc) && \
    bash -l -c "gem install configgin --version 0.18.4" && \
    yum list installed --disableplugin=subscription-manager > /root/after-ruby-install.packages && \
    yum clean all

# Install dumb-init
RUN wget -O /usr/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.0/dumb-init_1.2.0_amd64 \
        && chmod +x /usr/bin/dumb-init

# Install configgin
# The configgin version is hardcoded here so a commit is generated when the version is bumped.
RUN /bin/bash -c "source /usr/local/rvm/scripts/rvm && gem install configgin --version=0.20.3"

# Install additional dependencies
RUN yum install -y rsync fuse &&\
    yum clean all 

RUN yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm &&\ 
    yum install -y jq &&\ 
    yum clean all    

ADD monitrc.erb /opt/fissile/monitrc.erb

ADD post-start.sh /opt/fissile/post-start.sh
RUN chmod ug+x /opt/fissile/post-start.sh

# Add rsyslog configuration
ADD rsyslog_conf/etc /etc/
