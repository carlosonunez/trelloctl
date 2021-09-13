FROM ruby:2.7-buster
MAINTAINER Carlos Nunez <dev@carlosnunez.me>

COPY Gemfile /
RUN apt -y install git curl
RUN bundle install
