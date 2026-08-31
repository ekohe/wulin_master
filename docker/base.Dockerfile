# Ruby + Node + build toolchain + bundler: the layer every wulin_master-generated app is
# built FROM, so a cold build pulls it instead of re-running apt and the NodeSource
# install. It ships into each app through the wulin_master submodule, which is what lets
# one be built with no registry access:
#
#   docker build -f vendor/gems/wulin_master/docker/base.Dockerfile -t wulin-base:local .
#   docker compose up --build
#
# `wulin-base:local` is what the generated compose file defaults BASE_IMAGE to. AIDA
# reaches this file through the build contract's `base_build` recipe.
#
# No `# syntax=docker/dockerfile:1`: that opts into the BuildKit frontend, and this has
# to build on the legacy builder, which is what the docker socket-proxy supports.

# Nothing enforces a match with the app: `rails new` writes a .ruby-version, but Rails'
# Gemfile has no `ruby` directive, so bundler never compares them. Tracks the Ruby the
# gem's own CI runs.
ARG RUBY_VERSION=3.4.4

FROM ruby:${RUBY_VERSION}-slim

WORKDIR /rails

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    BUNDLE_PATH=/usr/local/bundle

# Matches the Gemfile.lock "BUNDLED WITH" of the apps this builds.
ARG BUNDLER_VERSION=2.7.2
RUN gem install bundler -v "${BUNDLER_VERSION}" --no-document

ARG NODE_MAJOR=20
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

# Bind-mounted submodules appear owned by a different uid than the container user, and
# git then refuses to touch them ("detected dubious ownership"), breaking the gemspecs'
# `git ls-files`. Single-tenant development container, so everything in it is trusted.
RUN git config --global --add safe.directory '*'
