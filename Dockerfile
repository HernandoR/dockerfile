FROM node

RUN npm config set registry http://mirrors.cloud.tencent.com/npm && \
  npm install -g bower
