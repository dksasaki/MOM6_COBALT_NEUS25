# Use the official Ubuntu 22.04 LTS as the base image
FROM ubuntu:22.04

# Update the package list and install any desired packages
RUN apt-get update && apt-get install -y \
    make \
    gfortran \
    netcdf-bin \
    libnetcdf-dev \
    libnetcdff-dev \
    openmpi-bin \
    libopenmpi-dev


# add user user123 with no password, add to sudo group
RUN adduser --disabled-password --gecos '' user123 &&\
    adduser user123 sudo                           &&\
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN chown -R user123:user123 /home/user123

USER user123

WORKDIR /home/user123

# Add your application or configuration files to the image
# COPY /path/to/your/application /target/path/in/container

# Set environment variables, if needed
# ENV MY_VARIABLE=value

# Expose any necessary ports
# EXPOSE 80

# Define the command to run when the container starts
# CMD ["your-command"]
