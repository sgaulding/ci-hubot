FROM node
MAINTAINER Sam Gaulding <sam.gaulding@gmail.com>

ENV BOTDIR /opt/hubot

COPY . ${BOTDIR}
WORKDIR ${BOTDIR}
RUN npm install

CMD bin/hubot -a slack

