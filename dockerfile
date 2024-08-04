# Use an appropriate base image for Jetson Nano
# sudo docker build -t imswitch_hik .
# sudo docker run -it --privileged  imswitch_hik
# sudo docker ps # => get id for stop
# docker stop imswitch_hik
# sudo docker inspect imswitch_hik
# docker run --privileged -it imswitch_hik
# sudo docker run -it --rm -p 8001:8001 -p 2222:22 -e HEADLESS=1 -e HTTP_PORT=8001 -e CONFIG_FILE=example_virtual_microscope.json -e UPDATE_GIT=0 -e UPDATE_CONFIG=0 --privileged ghcr.io/openuc2/imswitch-noqt-x64:latest
# sudo docker run -it --rm -p 8001:8001 -p 2222:22 -e HEADLESS=1 -e HTTP_PORT=8001 -e CONFIG_FILE=example_uc2_hik_flowstop.json -e UPDATE_GIT=1 -e UPDATE_CONFIG=0 --privileged imswitch_hik
# performs python3 /opt/MVS/Samples/aarch64/Python/MvImport/GrabImage.py
#  sudo docker run -it -e MODE=terminal imswitch_hik
# docker build --build-arg ARCH=linux/arm64  -t imswitch_hik_arm64 .
# docker build --build-arg ARCH=linux/amd64  -t imswitch_hik_amd64 .
# sudo docker run -it --rm -p 8001:8001 -p 2222:22 -e HEADLESS=1 -e HTTP_PORT=8001 -e CONFIG_FILE=example_virtual_microscope.json -e UPDATE_GIT=0 -e UPDATE_CONFIG=0 --privileged imswitch_hik
#
# sudo docker run -it --rm -p 8001:8001 -p 2222:22 -e HEADLESS=1 -e HTTP_PORT=8001 -e CONFIG_FILE=example_uc2_hik_flowstop.json -e UPDATE_GIT=1 -e UPDATE_CONFIG=0 --privileged ghcr.io/openuc2/imswitch-noqt-x64:latest
# For loading external configs and store data externally
# sudo docker run -it --rm -p 8001:8001  -e HEADLESS=1  -e HTTP_PORT=8001    -e UPDATE_GIT=1  -e UPDATE_CONFIG=0  -e CONFIG_PATH=/config  --privileged  -v ~/Downloads:/config  imswitch_hik_arm64
# sudo docker run -it --rm -p 8002:8001  -e HEADLESS=1  -e HTTP_PORT=8001  -e UPDATE_GIT=1  -e UPDATE_CONFIG=0  --privileged -e DATA_PATH=/dataset -e CONFIG_PATH=/config -v /media/uc2/SD2/:/dataset -v /home/uc2/:/config  ghcr.io/openuc2/imswitch-noqt-x64:latest
# sudo docker run -it -e MODE=terminal ghcr.io/openuc2/imswitch-noqt-x64:latest





# Use an appropriate base image for multi-arch support
# Use an appropriate base image for multi-arch support
FROM ubuntu:22.04

ARG TARGETPLATFORM
ENV TZ=America/Los_Angeles

# Install necessary dependencies
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    python3 \
    python3-pip \
    build-essential \
    git \
    mesa-utils \
    openssh-server \
    libhdf5-dev \
    nano \
    usbutils \
    sudo \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


# Install Miniforge based on architecture
RUN if [ "${TARGETPLATFORM}" = "linux/arm64" ]; then \
        wget --quiet https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-aarch64.sh -O /tmp/miniforge.sh; \
    elif [ "${TARGETPLATFORM}" = "linux/amd64" ]; then \
        wget --quiet https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh -O /tmp/miniforge.sh; \
    fi && \
    /bin/bash /tmp/miniforge.sh -b -p /opt/conda && \
    rm /tmp/miniforge.sh

# Update PATH environment variable
ENV PATH=/opt/conda/bin:$PATH

# Create conda environment and install packages
RUN /opt/conda/bin/conda create -y --name imswitch python=3.10

RUN /opt/conda/bin/conda install -n imswitch -y -c conda-forge h5py numcodecs && \
    conda clean --all -f -y

# Download and install the appropriate Hik driver based on architecture
RUN cd /tmp && \
wget https://www.hikrobotics.com/cn2/source/support/software/MVS_STD_GML_V2.1.2_231116.zip && \
unzip MVS_STD_GML_V2.1.2_231116.zip && \
if [ "${TARGETPLATFORM}" = "linux/arm64" ]; then \
    dpkg -i MVS-2.1.2_aarch64_20231116.deb; \
elif [ "${TARGETPLATFORM}" = "linux/amd64" ]; then \
    dpkg -i MVS-2.1.2_x86_64_20231116.deb; \
fi

## Install Daheng Camera 
# Create the udev rules directory
RUN mkdir -p /etc/udev/rules.d

# Download and install the appropriate Daheng driver based on architecture
RUN cd /tmp && \ 
wget https://dahengimaging.com/downloads/Galaxy_Linux_Python_2.0.2106.9041.tar_1.gz && \
tar -zxvf Galaxy_Linux_Python_2.0.2106.9041.tar_1.gz && \
if [ "${TARGETPLATFORM}" = "linux/arm64" ]; then \
    wget https://dahengimaging.com/downloads/Galaxy_Linux-armhf_Gige-U3_32bits-64bits_1.5.2303.9202.zip && \
    unzip Galaxy_Linux-armhf_Gige-U3_32bits-64bits_1.5.2303.9202.zip && \
    cd /tmp/Galaxy_Linux-armhf_Gige-U3_32bits-64bits_1.5.2303.9202; \
elif [ "${TARGETPLATFORM}" = "linux/amd64" ]; then \
    wget https://dahengimaging.com/downloads/Galaxy_Linux-x86_Gige-U3_32bits-64bits_1.5.2303.9221.zip && \
    unzip Galaxy_Linux-x86_Gige-U3_32bits-64bits_1.5.2303.9221.zip && \
    cd /tmp/Galaxy_Linux-x86_Gige-U3_32bits-64bits_1.5.2303.9221; \
fi && \
chmod +x Galaxy_camera.run && \
cd /tmp/Galaxy_Linux_Python_2.0.2106.9041/api && \
/bin/bash -c "source /opt/conda/bin/activate imswitch && python3 setup.py build" && \
python3 setup.py install

# Run the installer script using expect to automate Enter key presses
RUN if [ "${TARGETPLATFORM}" = "linux/arm64" ]; then \
    echo "Y En Y" | /tmp/Galaxy_Linux-armhf_Gige-U3_32bits-64bits_1.5.2303.9202/Galaxy_camera.run; \
elif [ "${TARGETPLATFORM}" = "linux/amd64" ]; then \
    echo "Y En Y" | /tmp/Galaxy_Linux-x86_Gige-U3_32bits-64bits_1.5.2303.9221/Galaxy_camera.run; \
fi

# Ensure the library path is set
ENV LD_LIBRARY_PATH="/usr/lib:/tmp/Galaxy_Linux-armhf_Gige-U3_32bits-64bits_1.5.2303.9202:$LD_LIBRARY_PATH"

# Source the bashrc file
RUN echo "source ~/.bashrc" >> ~/.bashrc
RUN /bin/bash -c "source ~/.bashrc"
RUN mkdir -p /opt/MVS/bin/fonts

# Set environment variable for MVCAM_COMMON_RUNENV
ENV MVCAM_COMMON_RUNENV=/opt/MVS/lib LD_LIBRARY_PATH=/opt/MVS/lib/64:/opt/MVS/lib/32:$LD_LIBRARY_PATH

# Clone the config folder
RUN git clone https://github.com/openUC2/ImSwitchConfig /root/ImSwitchConfig

# Clone the repository and install dependencies
RUN git clone https://github.com/openUC2/imSwitch /tmp/ImSwitch && \
    cd /tmp/ImSwitch && \
    /bin/bash -c "source /opt/conda/bin/activate imswitch && pip install -e /tmp/ImSwitch"

# Install UC2-REST
RUN git clone https://github.com/openUC2/UC2-REST /tmp/UC2-REST && \
    cd /tmp/UC2-REST && \
    /bin/bash -c "source /opt/conda/bin/activate imswitch && pip install -e /tmp/UC2-REST"

# Force pull imswitch
ARG CACHEBUST=1
RUN cd /tmp/ImSwitch && \
     git pull
        #/bin/bash -c "source /opt/conda/bin/activate imswitch && pip install -e /tmp/ImSwitch --no-deps"

# Expose SSH port and HTTP port
EXPOSE 22 8001

CMD ["/bin/bash", "-c", "\
    if [ \"$MODE\" = \"terminal\" ]; then \
        /bin/bash; \
    else \
        echo 'LSUSB' && lsusb && \
        echo 'Listing external USB storage devices' && \
        ls /media && \
        /usr/sbin/sshd -D & \
        ls /root/ImSwitchConfig && \
        if [ \"$UPDATE_GIT\" = \"true\" ] || [ \"$UPDATE_GIT\" = \"1\" ]; then \
            echo 'Pulling the ImSwitch repository' && \
            cd /tmp/ImSwitch && \
            git pull; \
        fi && \
        if [ \"$UPDATE_INSTALL_GIT\" = \"true\" ] || [ \"$UPDATE_INSTALL_GIT\" = \"1\" ]; then \
            echo 'Pulling the ImSwitch repository and installing' && \
            cd /tmp/ImSwitch && \
            git pull && \
            /bin/bash -c 'source /opt/conda/bin/activate imswitch && pip install -e /tmp/ImSwitch'; \
        fi && \
        if [ \"$UPDATE_UC2\" = \"true\" ] || [ \"$UPDATE_UC2\" = \"1\" ]; then \
            echo 'Pulling the UC2-REST repository' && \
            cd /tmp/UC2-REST && \
            git pull; \
        fi && \
        if [ \"$UPDATE_INSTALL_UC2\" = \"true\" ] || [ \"$UPDATE_INSTALL_UC2\" = \"1\" ]; then \
            echo 'Pulling the UC2-REST repository and installing' && \
            cd /tmp/UC2-REST && \
            git pull && \
            /bin/bash -c 'source /opt/conda/bin/activate imswitch && pip install -e /tmp/UC2-ESP'; \
        fi && \
        if [ \"$UPDATE_CONFIG\" = \"true\" ]; then \
            echo 'Pulling the ImSwitchConfig repository' && \
            cd /root/ImSwitchConfig && \
            git pull; \
        fi && \
        if [ -z \"$CONFIG_PATH\" ]; then \
            CONFIG_FILE=${CONFIG_FILE:-/root/ImSwitchConfig/imcontrol_setup/example_virtual_microscope.json}; \
        else \
            CONFIG_FILE=None; \
        fi && \
        source /opt/conda/bin/activate imswitch && \
        HEADLESS=${HEADLESS:-1} && \
        HTTP_PORT=${HTTP_PORT:-8001} && \
        USB_DEVICE_PATH=${USB_DEVICE_PATH:-/dev/bus/usb} && \
        CONFIG_PATH=${CONFIG_PATH:-None} && \
        DATA_PATH=${DATA_PATH:-None} && \        
        echo \"python3 /tmp/ImSwitch/main.py --headless $HEADLESS --config-file $CONFIG_FILE --http-port $HTTP_PORT --config-folder $CONFIG_PATH --ext-data-folder $DATA_PATH \" && \
        python3 /tmp/ImSwitch/main.py --headless $HEADLESS --config-file $CONFIG_FILE --http-port $HTTP_PORT --config-folder $CONFIG_PATH --ext-data-folder $DATA_PATH; \
    fi"]

# source /opt/conda/bin/activate imswitch
# python3 /tmp/ImSwitch/main.py  --headless 1 --config-file example_virtual_microscope.json --config-folder /config