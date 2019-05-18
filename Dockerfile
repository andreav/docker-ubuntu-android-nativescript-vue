FROM ubuntu:bionic AS ubuntunativescript
MAINTAINER Andrea V <andreav.pub@gmail.com>

RUN useradd -ms /bin/bash nativescript

# Utilities
RUN apt-get update && \
    apt-get -y install apt-transport-https unzip curl usbutils --no-install-recommends && \
    rm -r /var/lib/apt/lists/*

# JAVA
RUN apt-get update && \
    #apt-get -y install default-jdk --no-install-recommends && \
    apt-get -y install openjdk-8-jdk --no-install-recommends && \
    rm -r /var/lib/apt/lists/*

# NodeJS
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - && \
    apt-get update && \
    apt-get -y install nodejs --no-install-recommends && \
    rm -r /var/lib/apt/lists/*

# NativeScript
RUN npm install -g nativescript && \
    tns error-reporting disable

# Android build requirements
RUN apt-get update && \
    apt-get -y install lib32stdc++6 lib32z1 --no-install-recommends && \
    rm -r /var/lib/apt/lists/*

# Download and untar Android SDK tools
RUN mkdir -p /usr/local/android-sdk-linux && \
    curl -sL https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip -o tools.zip && \
    unzip tools.zip -d /usr/local/android-sdk-linux && \
    rm tools.zip

# Set environment variable
# ENV JAVA_HOME $(update-alternatives --query javac | sed -n -e 's/Best: *\(.*\)\/bin\/javac/\1/p')
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV ANDROID_HOME /usr/local/android-sdk-linux
ENV PATH ${ANDROID_HOME}/tools:$ANDROID_HOME/platform-tools:$PATH

RUN echo y | $ANDROID_HOME/tools/bin/sdkmanager "tools" "emulator" "platform-tools" "platforms;android-28" "build-tools;28.0.3" "extras;android;m2repository" "extras;google;m2repository"

WORKDIR /usr/src/app

CMD ["bash", "tns", "doctor"]



FROM ubuntunativescript AS ubuntunativescriptvue
MAINTAINER Andrea V <andreav.pub@gmail.com>

ARG USER_ID
ARG GROUP_ID

USER root

# When user is not 1000:1000, recreate it with the same id of host user
# So, created files under target directory (visible from host) will have same host uid
RUN if [ ${USER_ID:-0} -ne 0 ] && [ ${GROUP_ID:-0} -ne 0 ]; then \
        rm -rf /home/nativescript && \
        userdel -f nativescript && \
        if getent group nativescript ; then groupdel nativescript; fi && \
        groupadd -g ${GROUP_ID} nativescript && \
        useradd -l -u ${USER_ID} -g nativescript -ms /bin/bash nativescript \
    ;fi

# Create working folder
WORKDIR /usr/src/app

# Create node_modules and make nativescript owns it
# So, when running image and mounting node_modules for hiding this folder to host,
#     nativescript user will own node_modules and not root user
RUN mkdir /usr/src/app/node_modules && chown -R nativescript:nativescript /usr/src/app

USER nativescript

COPY ./app/package*.json ./
RUN npm install

COPY ./app/* ./

CMD [ "bash" ]
