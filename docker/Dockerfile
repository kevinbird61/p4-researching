FROM kevinbird61/new-basic-p4env

RUN apt-get update && apt-get install -y openssh-server \
    net-tools iputils-ping git vim curl wget
RUN mkdir /var/run/sshd
# using argument to assign passwd to create image
RUN echo 'root:u109' | chpasswd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
RUN git clone https://github.com/p4lang/tutorials /root/p4-tutorials
RUN git clone https://github.com/kevinbird61/p4-researching.git /root/p4-researching
