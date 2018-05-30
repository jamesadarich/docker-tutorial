## Prerequisites

For this tutorial you will need:

### Docker CE  
[install Docker for Ubuntu](https://docs.docker.com/install/linux/docker-ce/ubuntu/)

[install Docker for Windows](https://docs.docker.com/docker-for-windows/install/)

[install Docker for Mac](https://docs.docker.com/docker-for-mac/install/)

### Clone the repo

```cli
> git clone https://github.com/jamesadarich/docker-tutorial
```

## The dockerfile

To start us off let's create a dockerfile, this contains the instructions for how to build the image. All we need to do is create a file called `dockerfile` (no file extension) in the root of our workspace.

## FROM instruction

Our very first instruction to Docker is what image we'd like to base our image on. In this case we need Node.js so we'll grab one with that. The `FROM` instruction will take an image name and tag, if we don't specify a tag Docker will assume we want the tag `latest` which could be a problem if the image has breaking changes in it. So we're going to specify we only want Node.js version 10 as we're happy to take minor updates and patches.

```docker
FROM node:10
```

And there we have it, we've started our dockerfile, lets continue.

## RUN instruction

Now we've got the environment out of the way we want to do things! The `RUN` instruction will execute some command line loveliness for us. To start out we'll keep things simple and create a folder for us to build our app into to keep things nice and neat.

```docker
RUN mkdir -p /build
```

## WORKDIR instruction

After we have created a folder to keep our app in we want to ensure all further commands Docker executes are within that so we'll need to change the current working directory. This is done using the `WORKDIR` instruction.

```docker
WORKDIR /build
```

## COPY instruction

Next up we need to copy the files from our local folder to our container. Since we need everything let's copy it all in one go. The `COPY` instruction takes two arguments, the first of which is what to take from the local source folder and the second is where to put it in the container. We just want everything from the local current working directory moved to the container's current working director so we'll use two dots like so.

```docker
COPY . .
```

The arguments could be globs, folders or individual files however depending on your requirements (some examples of these later)

### COPY vs ADD

A brief aside about the `COPY` instruction, it has a very close relative - the `ADD` instruction. They do very similar things so why have we chosen to use `COPY` over `ADD`? This is because `ADD` has additional behaviour, specifically grabbing resources from URLs and unpacking archives. As that could potentially result in security issues or unexpected behaviour I prefer to use `COPY` and ensure that all my instructions are clear and if I want to unpack an archive I will call out to that as for example a `RUN` instruction.

## Setup the app

This app contains TypeScript and Sass, it's also got some other dependencies so it needs to be built. All we need for that is a couple more `RUN` instructions.

```docker
RUN npm install
RUN npm run build
```

## CMD instruction

All we have left to do now is to tell Docker how to start the application. This is a little bit different to the `RUN` instructions as we need to tell Docker not to run it until the image is run. The `CMD` instruction does this for us. We pass it an array of strings representing the command we want to run, we want `npm start` which will look like the below.

```docker
CMD [ "npm", "start" ]
```

### CMD vs ENTRYPOINT

Another instruction with a similar counterpart `CMD` and `ENTRYPOINT` can have similar effects. The difference is that `CMD` defines the command to be run when the container starts whereas `ENTRYPOINT` allows a command to be passed to a program. The default `ENTRYPOINT` is `/bin/sh -c` which means we can pass things like npm to it. In general I prefer `CMD` as it keeps things cleaner if you're creating a web app or API or something similar you always want it to start using the same command so you might as well define it explicitly.

## Build the image

The dockerfile is complete so we can get building the image. All we need to do is call `docker build` with the working directory (in this case current so ".") and a tag for our image so we can reference it later. The tag should comprise of a namespace (usually your docker hub username) an image name (whatever you want) and a tag name (usually the version of whatever your building) in the format *{namespace}/{image-name}:{tag-name}*.

```cli
> docker build . -t jamesadarich/docker-tutorial:1.0.0
```

When you run the build command Docker will run through each instruction in sequence and you should see the following output.

```cli
Step 2/7 : RUN mkdir -p /build
 ---> ee1ebb5188d8
```

After each step you should see an arrow pointing to an alphanumeric string. This identifies a layer built by Docker so that it can cache it for later. If you run the same build command you should see that it skips over this step and uses the cache instead assuming the step hasn't changed or it's input hasn't changed.

```cli
Step 2/7 : RUN mkdir -p /build
 ---> Using cache
 ---> ee1ebb5188d8
```

This should merrily go through the instructions and complete successfully, unless you've run `npm install` for this app locally and are not on linux or have a node version locally of anything other than what's in the container, in which case you should probably see an error. Which brings us neatly on to...

### .dockerignore file

Because developer environments can be different we want to ensure that our dev environment doesn't effect the container. This can happen when you copy in files that should be generated in the container e.g. `node_modules` - because these can be environment specific such as `node-sass` which grabs a specific binary file for the current environment. If this is copied across and they don't match errors will happen and as we want consistent builds we need to avoid this. But not at the cost of keeping our `COPY` instruction simple. In this case we create a .dockerignore file and in the same way as .gitignore we give it globs, folders and files to ignore. We only want to ignore `node_modules` which simply means a file with the below.

```
node_modules
```

## Run the container

Let's have a look at the image we've built. We can do this using the docker run command. We're going to pass a `publish` flag to let Docker know how we want to expose the application to our machine and the name of the image we want to run. The `publish` flag (--publish or -p) maps a port on our local machine to a port on the container and is separated with a colon *{local-port}:{container-port}*. If you wish to map it to the same port on both you can supply just a single number.

```cli
> docker run -p 4321:3000 jamesadarich/docker-tutorial:1.0.0
```

If everything has gone absolutely wonderfully then if you go to localhost:4321 in your favourite browser you should see the following.

![the app in all it's glory](app-screenshot.png)


### What about EXPOSE?

There is an instruction that seems like it should allow a port to be exposed from the container, so why didn't we use it? The `EXPOSE` instruction on it's own doesn't actually expose the port on it's own, it still requires the `publish` flag to be passed to it. Generally it's thought of as a way of documenting which port the application is listening on so it's good practice to put it in but be mindful that you will still need the `publish` flag to access it.

Use it simply by adding the port number you want to expose after the instruction

```docker
EXPOSE 3000
```

## So we're done right?

As you can probably see by the article continuing below (well sleuthed) we're not quite finished yet. To figure out what we're missing let's run the docker images command to see the images that have been built.

```cli
> docker images
REPOSITORY                          TAG                 IMAGE ID            CREATED             SIZE
jamesadarich/docker-tutorial        1.0.0               79ef02201071        2 minutes ago       849MB
```

Yikes, check out that size - **849MB**. Granted it contains an operating system, Node.js and the web app but still we can do better. Node.js isn't going to get any smaller so the only two we can target is our operating system and our web app. However, while our web app might not need that operating system to run we may be using some of the features for the build process that we don't use at run time e.g. python. Luckily it's possible to use a different base image to build and run your app.

## Multi-stage builds

Defining a different image to be used for the build vs running of a dockerized application is as simple as having multiple `FROM` instructions... in fact that's all it is. If we add a second `FROM` instruction before our `CMD` instruction this will be the image used to run our application. In this case we're using a different version of the same image built on Alpine which is a small Linux flavour.

```docker
FROM node:10-alpine
```

As well as making our image much smaller it also has the benefit of eliminating potential security issues in operating system features or libraries we're not even using. When Docker sees multiple `FROM` images in a build it will use the last one as the base for the built image and discard any previous images. This however means we have an empty image so let's copy our built files across.

### Copy only useful files

When copying files previously we moved from our local machine into the image but now we'll need a way of referencing our build image. we do this by giving it a name in the from statement like so.

```docker
FROM node:10 as build-container
```

As before we'll keep things neat by adding a directory in the Alpine image.

```docker
RUN mkdir -p /app
WORKDIR /app
```

Then we can simply copy across the stuff we care about (remembering that we put everything in a folder called "build"). The "public" folder contains the web app assets (compiled javascript, css and html), the "server" folder contains the node.js web server and we also want the `package.json` so we can run our start command.

```docker
COPY --from=build-container build/public public
COPY --from=build-container build/server server
COPY --from=build-container build/package.json .
```

### Install only the dependencies you need

The last thing we need to do is another `npm install` as our web server depends on Express so we'll need to install it. However we don't want any of the dependencies we've bundled or used to build the web app so we just install the production ones this time.

```docker
RUN npm install --production
```

## Run it again

At last, the dockerfile is complete so let's build it again

```cli
> docker build . -t jamesadarich/docker-tutorial:1.0.0
```

When that's finally done we can run the container.

```cli
> docker run -p 4321:3000 jamesadarich/docker-tutorial:1.0.0
docker: Error response from daemon: driver failed programming external connectivity on endpoint sharp_hugle (a903c15a7515066943185f33e6b6db14fbf6a761abd77bef1bd41ca06fd85e30): Bind for 0.0.0.0:4321 failed: port is already allocated.
```

Oh no the port is already allocated! That's the pesky image we were ran earlier, we'll need to stop it. We can find out information about all running containers using the `docker ps` command.

```cli
> docker ps
CONTAINER ID        IMAGE                                 COMMAND                  CREATED             STATUS                          PORTS                    NAMES
1572bc7c0ba4        jamesadarich/docker-tutorial:1.0.0    "npm start"              14 minutes ago      Up 14 minutes                   0.0.0.0:4321->3000/tcp   romantic_lamport
```

Then stop the container using it's ID.

```cli
> docker stop 1572bc7c0ba4
```

If we run the image again everything should be the same as we had previously but what's more if we check the size of the built image...

```cli
> docker images
REPOSITORY                          TAG                 IMAGE ID            CREATED             SIZE
jamesadarich/docker-tutorial        1.0.0               f7015c4a0c06        5 days ago          80MB
```

... only **80MB** more than 90% smaller than before hooray we did it!

## Wrapping up

So we've learnt to build and optimise Docker images and run a container from an image we've built. Your dockerfile should look something like the file below, I've added some comments using the `#` character at the start of the line to clarify things (and show you how to add comments if you were wondering)

```docker
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
```

If you're still having trouble I've added a [solution branch](https://github.com/jamesadarich/docker-tutorial/tree/solution) to the repo to pull to compare.
