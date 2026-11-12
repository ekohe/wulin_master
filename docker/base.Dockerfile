# Ruby + Node + build toolchain + bundler: the layer every wulin_master-generated app is
# built FROM, so a cold build pulls it instead of re-running apt and the NodeSource
# install. The scaffold COPIES this file into each app as `docker/base.Dockerfile`, so an
# app can build it from its own checkout with no registry access and no dependency on how
# the gem got there:
#
#   docker build --pull -f docker/base.Dockerfile -t wulin-base:ruby-<series> .
#   docker compose up --build
#
# `wulin-base:ruby-<series>` is what the generated compose file defaults BASE_IMAGE to.
#
# No `# syntax=docker/dockerfile:1`: that opts into the BuildKit frontend, and this has
# to build on the legacy builder too.

# The template writes the app's Ruby series here; this copy names none, so it cannot be built
# on a Ruby the app does not run. The series' newest patch keeps its ABI, so gems compiled in a
# bundle volume still load; the tag only moves on a pull, hence --pull.
ARG RUBY_VERSION

FROM ruby:${RUBY_VERSION}-slim

WORKDIR /rails

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    BUNDLE_PATH=/usr/local/bundle

# Matches the Gemfile.lock "BUNDLED WITH" of the apps this builds.
ARG BUNDLER_VERSION=2.7.2
RUN gem install bundler -v "${BUNDLER_VERSION}" --no-document

ARG NODE_MAJOR=22
# Both apt-get updates are needed: the second re-indexes after the NodeSource repository
# is added. curl outlives the install step -- the generated compose healthcheck uses it.
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential git curl gnupg2 procps \
      libpq-dev libyaml-dev libvips pkg-config && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" > /etc/apt/sources.list.d/nodesource.list && \
    apt-get update -qq && \
    apt-get install -y --no-install-recommends nodejs && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# A bind-mounted checkout appears owned by a different uid than the container user, and git then
# refuses to touch it ("detected dubious ownership"), breaking the gemspecs' `git ls-files`.
# Single-tenant development container, so everything in it is trusted.
RUN git config --global --add safe.directory '*'
