FROM andreav/docker-ubuntu-android-nativescript
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

# I'm not creating an image for deployinG, so, not useful copying stuff inside

# COPY ./package*.json ./
# RUN npm install

# COPY . .

CMD [ "bash" ]
