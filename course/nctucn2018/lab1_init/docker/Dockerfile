# Download base image from yungshenglu/ubuntu-env:16.04 (Task 1.)


# Update software repository (Task 1.)


# Install software repository (Task 1.)


# Install packages (Task 1.)


# Use argument to assign passwd to create image
RUN echo 'root:cn2018' | chpasswd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

# Set the envionment variables
ENV NOTVISIBLE "in users profile"
ENV LC_ALL C
RUN echo "export VISIBLE=now" >> /etc/profile

# Set the container listens on the specified ports at runtime (Task 1.)


# Set the entrypoint
CMD ["/usr/sbin/sshd", "-D"]

# Clone the repository from GitHub (Task 1.)
