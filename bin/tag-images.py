#!/usr/bin/env python

from docker import Client
import re

docker = Client(base_url='unix://var/run/docker.sock')
images = docker.images(name='cloud*')
repo_prefix = 'eu.gcr.io/powop-1349'

for image in images :
    image_id = image['Id'][7:19]
    tag_name = set(map(lambda tag: tag.split(':')[0].split('_')[-1], image['RepoTags'])).pop()
    print "docker tag %s %s/%s" % (image_id, repo_prefix, tag_name)
    docker.tag(image = image_id, repository = repo_prefix, tag = tag_name)
