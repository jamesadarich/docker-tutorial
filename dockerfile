# the build container
FROM node:10 as build-container

# create build directory
RUN mkdir -p /build
WORKDIR /build

# copy EVERYTHING
COPY . .

# setup the app
RUN npm install
RUN npm run build

# the app container
FROM node:10-alpine

# create an app directory
RUN mkdir -p /app
WORKDIR /app

# copy the stuff we need from the build container
COPY --from=build-container build/public public
COPY --from=build-container build/server server
COPY --from=build-container build/package.json .

# install our production dependencies
RUN npm install --production

# remind ourselves what port the application is listening on
EXPOSE 3000

# set the start command
CMD [ "npm", "start" ]
