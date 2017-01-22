# Starting Scala Environment

This is a dockerfile to help you get started with your Scala development. Feel free to split/remove it into whatever makes more sense to your projects, as this image is huge and not very performant (but it gets the jon done for me)

## Includes

- Java 8 JDK
- Scala
- Play Framework
- Git
- Postgres
- Redis

## Before we get started

I assume that you are familiar with Docker. If not, [here is the official documentation](https://docs.docker.com/).

## Installation

1. Install Docker
1. Build the image from my Dockerfile:
`docker build -t 54chi/discodock github.com/54chi/discodock`

## Usage

`docker run -it -rm 54chi/discodock`

## License

This code is open source software licensed under the MIT License.

## To dos:

[ ] The base image for the container is the [openjdk:8](https://github.com/docker-library/openjdk). Does the trick, and can be reused for other containers, but prob. would be better to create a base image from scratch.

[ ] Put together a list of frequent commands (e.g. rebuild, stop, start containers, compile scala, redis, psql, etc.)
